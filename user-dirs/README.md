# Linux user directories

The `user-dirs` package configures the standard XDG directories using lowercase names.
Run these commands from the repository root. Create the directories before applying
it so `xdg-user-dirs-update` does not reset missing paths to `$HOME`:

```bash
mkdir -p ~/desktop ~/downloads ~/templates ~/public ~/documents ~/music ~/pictures ~/videos
stow -vR user-dirs -t ~
```

Before stowing, move any existing regular `~/.config/user-dirs.dirs` file to a backup
outside the repository; leaving it in place causes a Stow conflict. If it is already
a symlink to this package, leave it alone.

This changes directory mappings only; it does not move files from existing folders
such as `~/Documents`. Move any existing contents separately as needed. This package
assumes the default `XDG_CONFIG_HOME` (`~/.config`).

Query paths with `xdg-user-dir PICTURES` (or `DOCUMENTS`, `DOWNLOAD`, etc.).
