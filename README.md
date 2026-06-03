# dotfiles

Personal configuration for macOS and Linux — shell, editor, and terminal
multiplexer. Symlinks are managed with [GNU Stow][stow].

## What's in here

| Path                          | What it is                                                   |
| ----------------------------- | ------------------------------------------------------------ |
| `.zshrc`, `.zsh/`             | Zsh config + Catppuccin syntax-highlighting theme            |
| `.tmux.conf`                  | Tmux config (uses [TPM][tpm] for plugins)                    |
| `.config/nvim/`               | Neovim config (Lua, Lazy.nvim)                               |
| `Brewfile`                    | Homebrew formulae, casks, and Go tools                       |
| `install.sh`                  | One-shot bootstrap for macOS + Debian/Ubuntu                 |
| `home_row_mods-*.json`        | [Karabiner-Elements][karabiner] home-row mods rule           |
| `.stow-local-ignore`          | Tells `stow` which top-level entries **not** to symlink      |

## Install

### Option 1 — bootstrap script (recommended)

The one-shot installer detects your OS, installs packages, sets up Oh My Zsh /
Powerlevel10k / NVM / TPM, and stows the dotfiles for you.

```sh
git clone https://github.com/<you>/.dotfiles ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

Supported: macOS (via Homebrew) and Debian/Ubuntu Linux (via `apt`, including
Raspberry Pi / arm64). After it finishes, start a new shell, then:

- inside `tmux`, hit `prefix + I` to install tmux plugins
- run `nvim` once to trigger Lazy.nvim plugin install
- on Linux, log out and back in for the `docker` group to apply

### Option 2 — manual install with GNU Stow

If you'd rather wire up only the dotfiles (no package installs, no shell
plugins), use Stow directly. Stow creates symlinks from `$HOME` back into this
repo, mirroring the directory structure here.

```sh
# 1. Install stow
brew install stow                # macOS
sudo apt-get install -y stow     # Debian / Ubuntu / Raspberry Pi OS

# 2. Clone the repo
git clone https://github.com/<you>/.dotfiles ~/.dotfiles
cd ~/.dotfiles

# 3. Preview what stow would do (dry run)
stow --target="$HOME" --no --verbose=2 .

# 4. Apply
stow --target="$HOME" --verbose .
```

This single-package layout means everything in the repo root maps 1:1 into
`$HOME` — `~/.dotfiles/.zshrc` → `~/.zshrc`, `~/.dotfiles/.config/nvim/` →
`~/.config/nvim/`, and so on. The [`.stow-local-ignore`](./.stow-local-ignore)
file keeps `Brewfile`, `install.sh`, `goals.md`, and the Karabiner JSON from
being symlinked.

#### Common Stow commands

```sh
stow --target="$HOME" --restow .   # re-link (after pulling new files)
stow --target="$HOME" --delete .   # remove all symlinks
stow --target="$HOME" --adopt .    # absorb existing $HOME files into the repo
                                   # (then `git diff` and decide what to keep)
```

#### Conflicts

If `stow` refuses because a file already exists in `$HOME`, either back it up
and re-run, or use `--adopt` to pull it into the repo and review with
`git diff` before committing.

[stow]: https://www.gnu.org/software/stow/
[tpm]: https://github.com/tmux-plugins/tpm
[karabiner]: https://karabiner-elements.pqrs.org/
