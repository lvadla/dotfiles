# dotfiles
settings and configurations I use

## Stow installation

Install GNU Stow, clone this repository, then run Stow from the repository root:

```bash
stow -vR <package> -t ~
```

Choose packages explicitly for the machine you are setting up. Shared packages include `zsh`,
`gitconfig`, `codex`, `ghostty`, `helix`, `lazygit`, `ripgrep`, `scripts`, `ssh`, and `starship`.
Desktop and platform-specific packages should only be stowed where they apply.

## Updating

To update an already-stowed package after pulling changes, run the same command again.
