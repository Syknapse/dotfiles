# .dotfiles

My macOS dotfiles, managed with [Dotbot](https://github.com/anishathalye/dotbot).

---

## Quick start

```bash
git clone <repo_address> ~/.dotfiles
cd ~/.dotfiles
./install
```

> **New Mac:** Homebrew may prompt you to install the Xcode Command Line Tools on the first run. That's expected and required; everything else runs on its own.
>
> **Apple Silicon only:** Homebrew paths are hardcoded to `/opt/homebrew` (in `zprofile`, `zshrc`, and the setup scripts). On an Intel Mac you'd need to point those at `/usr/local`.

`./install` does the following:

1. Symlinks the config files into `~` (creating `secrets` from the template first, if it's missing)
2. Creates `~/projects`, `~/work`, and `~/Documents/Snips` (screenshot folder)
3. Installs everything in the Brewfile (packages and casks)
4. Sets the Homebrew zsh as the default shell
5. Installs the latest Node LTS via nvm
6. Applies macOS system preferences
7. Generates an SSH key if there isn't one
8. Arms the git pre-push hook (see [Testing](#testing))

Re-running it later is safe.

---

## Setting up a new machine

1. Run `./install`.
2. Add API keys to `~/.dotfiles/secrets`. Install already creates this file (from the template, mode 600) and links it to `~/.secrets`, so it's ready to edit.
3. If you want a separate work git identity, create it from the template: `cp config/work-gitconfig.example ~/work/.gitconfig`, then fill it in.

To have your keys in place from the very first shell, fill in `secrets` _before_ running install (`cp secrets.example secrets`). Install never overwrites an existing `secrets` file.

---

## Symlinks

Config files live in `~/.dotfiles/` and are symlinked into `~` by `install.conf.yaml`.

To add another one, add it under `link:`:

```yaml
~/.filename: filename
```

Then re-run `./install`.

---

## Secrets and API keys

Anything private (API keys, tokens) goes in `~/.secrets`, never in a tracked file.

If `secrets` doesn't exist, `./install` creates it from `secrets.example` (mode 600) and links it to `~/.secrets`. Add your values there:

```bash
$EDITOR ~/.dotfiles/secrets
```

`zshrc` sources `~/.secrets` on startup. The file is gitignored and is never overwritten by re-running install.

---

## Brewfile

The Brewfile holds all the Homebrew packages and apps. VSCode extensions are left out on purpose, since they sync on their own through VSCode Settings Sync.

Regenerate it from the current machine with:

```bash
brewbd   # alias for: brew bundle dump --force --describe --no-vscode
```

`HOMEBREW_BUNDLE_DUMP_NO_VSCODE=1` (set in `zshrc`) keeps extensions out even when running `brew bundle dump` directly. Commit the result.

---

## macOS settings

`setup_macos.zsh` applies system preferences (Dock, Finder, keyboard, trackpad, screenshots, and so on).

```bash
./setup_macos.zsh --dry-run   # show what would change
./setup_macos.zsh             # apply it
```

---

## Testing

These check that the repo still installs cleanly. The first three don't touch the machine, so they're safe to run anytime:

```bash
./test.sh                    # syntax, shellcheck, YAML. Instant, no changes
./test/sandbox-install.sh    # run the real ./install into a temp $HOME, twice
./test/brewfile-drift.sh     # check every Brewfile package still resolves upstream
./verify.sh                  # check this machine against the expected setup
```

- **`test/sandbox-install.sh`** is the closest thing to a fresh-machine test without a fresh machine: it runs the real `./install` into a temp `$HOME` with a wiped environment and every privileged step neutralised (dry-run), **twice**, asserting both the fresh-install result and idempotency.
- **`test/brewfile-drift.sh`** catches any packages renamed or dropped by brew. It runs automatically on a fresh-machine install; run it by hand anytime you want to check before provisioning.

### Preview the whole install without changing anything

Every setup script honours a dry-run mode that makes no changes:

```bash
DOTFILES_DRY_RUN=1 ./install   # the whole install
./setup_macos.zsh --dry-run    # or a single script
```

### What runs automatically

- A **pre-push hook** runs `test.sh` and `sandbox-install.sh` before every `git push`, and blocks the push if either fails. `./install` arms it automatically (by pointing `core.hooksPath` at `.githooks`). Skip it for a single push with `git push --no-verify`.
- **GitHub Actions** runs the same two checks on every push. Nothing to set up.
- **Brew drift** `./install` runs `brewfile-drift.sh` automatically the _first_ time it installs Homebrew on a new machine (advisory — it never blocks the install), and never on re-runs. We can also manually trigger the drift check on demand from the repo's Actions tab before provisioning.

So once you've run `./install`, every push is checked locally by the hook and on the server by CI. Running a script by hand is just for quicker feedback while editing.

---

## Keeping everything in sync

After changing a dotfile, commit and push. On the other machine:

```bash
git pull
./install
```

---

## Work git identity

`~/.gitconfig` pulls in `~/work/.gitconfig` for any repo under `~/work/`, so work repos can use a different name and email. That file isn't in this repo (it's a separate identity); create it from the template:

```bash
cp config/work-gitconfig.example ~/work/.gitconfig
# then fill in your work name and email
```

---

_Based on [dotfiles.eieio.xyz](http://dotfiles.eieio.xyz)_
