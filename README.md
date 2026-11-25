# dev_dotfiles
Personal configurations of bash, tools, vscode and so on.

## Software versions on the standalone Mac

Chezmoi manages `~/.config/mise/config.toml`; mise installs the pinned developer
tools, terminal apps, and shell utilities listed there. Bash uses those copies
ahead of Homebrew. Homebrew still provides mise, macOS apps and libraries, and
tools without a compatible mise package for this Mac, such as btop. Rust stays
with rustup, and Pi and its packages keep their existing update workflow.

To bootstrap on a standalone Mac after initializing chezmoi:

```bash
brew install mise
chezmoi apply ~/.config/mise ~/.bashrc ~/.bash_profile ~/.bash_aliases
mise -C "$HOME" install
mise -C "$HOME" ls --current
```

Open a new Bash shell to pick up the managed versions. For non-interactive
commands, use `mise exec -- <command>`. To change a global version, edit
`dot_config/mise/config.toml` in the chezmoi source, apply that file, then rerun
`mise -C "$HOME" install`. Projects can pin their own versions in a local
`mise.toml`. These global pins do not deploy to ZTE machines.
