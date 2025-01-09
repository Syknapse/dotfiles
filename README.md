# .dotfiles

macOS dotfiles repo

## Installation

WARNING: This is currently not working properly. It creates the repo and symlinks correctly, and creates the projects and work directories, but all subsequent steps fail. Brew is not executing and not installing packages.  
**This can be fixed by installing brew manually before installing this program**. Then it all works correctly

Clone the repo to .dotfiles directory in your home directory. Ex: `users/syknapse`

```bash
git clone <repo_address> ~/.dotfiles
```

With the terminal navigate to the dotfiles directory and then execute the install file

```bash
$ cd .dotfiles
# users/syknapse/.dotfiles

$ ./install
# starts installation process of all the dotfiles project
```

## Symlinks

To symlink a file in our dotfiles to the home directory we just need to add it to the `install.conf.yaml` file.  
`~/.zshrc: zshrc` will create a .zshrc file in the home directory which is symbolically linked to the zshrc file in our .dotfiles directory.

## Create or modify the Brewfile

The following command uses Brew to create/modify the Brewfile with a full list of apps and packages installed on the machine, with a description.  
These will be installed when we install the dotfiles project.  
`brew bundle dump --force --describe` (aliased to `brewbd`)

## Keeping everything synced

When you make any changes to the dotfiles remember to commit and push to the repo. This way on any other machine you have installed dotfiles, you only need to pull the changes from the remote repo and run `./install` to sync the new changes.

## to do

- add explanation of work gitconfig (has to be init to be tested)
- add explanation of how to symlink

---

Based on this great course [dotfiles.eieio.xyz](http://dotfiles.eieio.xyz)
