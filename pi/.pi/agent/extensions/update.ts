import { readFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import { VERSION, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const PATCH_SCRIPT = `${process.env.HOME}/.pi/scripts/apply-patches.sh`;
const SETTINGS_FILE = `${process.env.HOME}/.pi/agent/settings.json`;
const UNKNOWN_VERSION = "unknown";
const NPM_PREFIX = "npm:";
const PI_PACKAGE = "@earendil-works/pi-coding-agent";
const UPDATE_COMMAND = "update";
const UI = {
  commandDescription: "Update pi and all installed extensions, apply local patches, and restart",
  noUpdates: "No updates available.",
  updating: "Updating pi and installed extensions...",
  noPatches: "Applying patches:\nNo patches were applied.",
  restarting: "Updated pi and extensions. Restarting...",
  settingsError: "Extensions: unable to read settings",
};

function updateFailure(code: number, details: string): string {
  return `Update failed (exit ${code}): ${details}`;
}

function patchFailure(details: string): string {
  return `Update succeeded, but applying local patches failed: ${details}`;
}

type PackageSpec = string | { source?: string };

type VersionInfo = {
  name: string;
  current: string;
  target: string;
};

function npmPackageName(spec: string): string | null {
  if (!spec.startsWith(NPM_PREFIX)) return null;
  const raw = spec.slice(NPM_PREFIX.length);
  const versionSeparator = raw.startsWith("@") ? raw.indexOf("@", 1) : raw.indexOf("@");
  const name = versionSeparator === -1 ? raw : raw.slice(0, versionSeparator);
  return name || null;
}

async function latestNpmVersion(name: string): Promise<string | undefined> {
  try {
    const response = await fetch(`https://registry.npmjs.org/${name}`, {
      signal: AbortSignal.timeout(10_000),
    });
    if (!response.ok) return undefined;
    const data = (await response.json()) as { [key: string]: unknown };
    return typeof data["dist-tags"] === "object" && data["dist-tags"] !== null
      ? ((data["dist-tags"] as { latest?: unknown }).latest as string | undefined)
      : undefined;
  } catch {
    return undefined;
  }
}

async function getVersionInfo(name: string): Promise<VersionInfo> {
  const packageFile = `${process.env.HOME}/.pi/agent/npm/node_modules/${name}/package.json`;
  let current = UNKNOWN_VERSION;
  try {
    const packageJson = JSON.parse(await readFile(packageFile, "utf8")) as { version?: string };
    current = packageJson.version ?? current;
  } catch {
    // The update command will report the real install error if the package is unavailable.
  }

  return { name, current, target: (await latestNpmVersion(name)) ?? UNKNOWN_VERSION };
}

async function getUpdateSummary(): Promise<{ lines: string[]; hasUpdates: boolean; complete: boolean }> {
  let settings: { packages?: PackageSpec[] };
  try {
    settings = JSON.parse(await readFile(SETTINGS_FILE, "utf8")) as { packages?: PackageSpec[] };
  } catch {
    return {
      lines: [`Pi: v${VERSION} → ${UNKNOWN_VERSION}`, UI.settingsError],
      hasUpdates: true,
      complete: false,
    };
  }

  const names = (settings.packages ?? [])
    .map((item) => (typeof item === "string" ? item : item.source))
    .filter((source): source is string => source !== undefined)
    .map(npmPackageName)
    .filter((name): name is string => name !== null);
  const packages = await Promise.all([...new Set(names)].map(getVersionInfo));

  const piTarget = (await latestNpmVersion(PI_PACKAGE)) ?? UNKNOWN_VERSION;
  const formatVersionLine = (name: string, current: string, target: string): string =>
    current === target && target !== "unknown"
      ? `${name}: v${current} (latest)`
      : `${name}: v${current} → v${target}`;
  const lines = [
    formatVersionLine("Pi", VERSION, piTarget),
    ...packages.map((item) => formatVersionLine(item.name, item.current, item.target)),
  ];
  const versions = [
    { current: VERSION, target: piTarget },
    ...packages,
  ];

  return {
    lines,
    hasUpdates: versions.some((item) => item.target !== UNKNOWN_VERSION && item.current !== item.target),
    complete: versions.every((item) => item.current !== UNKNOWN_VERSION && item.target !== UNKNOWN_VERSION),
  }; 
}

export default function (pi: ExtensionAPI) {
  let pendingRestart = false;

  process.on("exit", () => {
    if (!pendingRestart) return;
    spawnSync(process.execPath, process.argv.slice(1), { stdio: "inherit" });
  });

  pi.registerCommand(UPDATE_COMMAND, {
    description: UI.commandDescription,
    handler: async (_args, ctx) => {
      const summary = await getUpdateSummary();
      if (summary.complete && !summary.hasUpdates) {
        ctx.ui.notify(
          `${summary.lines.join("\n")}\n\n${UI.noUpdates}`,
          "info",
        );
        return;
      }
      ctx.ui.notify(UI.updating, "info");

      const update = await pi.exec("pi", ["update", "--all"], { timeout: 120_000 });
      if (update.code !== 0) {
        ctx.ui.notify(updateFailure(update.code, (update.stderr || update.stdout || "").trim().slice(0, 300)), "error");
        return;
      }

      const patch = await pi.exec(PATCH_SCRIPT, [], { timeout: 30_000 });
      if (patch.code !== 0) {
        ctx.ui.notify(patchFailure((patch.stderr || patch.stdout || "").trim().slice(0, 300)), "error");
        return;
      }
      const patchStatus = patch.stdout.trim()
        ? `Applying patches:\n${patch.stdout.trim()}`
        : UI.noPatches;
      ctx.ui.notify(
        `${summary.lines.join("\n")}\n\n${patchStatus}\n\n${UI.restarting}`,
        "info",
      );
      pendingRestart = true;
      ctx.shutdown();
    },
  });
}
