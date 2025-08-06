# Agent Guidelines for Dotfiles Repository

## Repository Overview

This is a personal dotfiles repository containing configuration files for various tools and desktop environments (macOS, hyprland, KDE). The [TODO.md](TODO.md) file tracks outstanding work and improvements needed.

## File Structure & Conventions

- Configuration files are organized by package in subdirectories that mirror $HOME
- Shell scripts use `#!/bin/bash` and follow POSIX conventions
- General shell scripts are executable and located in `scripts/` directory

## Code Style Guidelines

- **Comments**: Minimal inline comments, self-documenting code preferred

## Common Operations

- Directory structure is designed for stow compatibility
- Use stow to symlink configurations: `stow -vR <package> -t ~` (e.g., `stow -vR lazygit -t ~`)
- Scripts are meant to be run directly: `./scripts/script-name.sh`
- No build process required - files are used as-is
