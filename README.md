# .dotfiles

macOS dotfiles repo

## Installation

Clone the repo to your home directory. Ex: `users/syknapse`

With the terminal in navigate to the dotfiles directory and then execute the install file

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
`brew bundle dump --force --describe`

## Keeping everything synced

When you make any changes to the dotfiles remember to commit and push to the repo. This way on any other machine you have installed dotfiles, you only need to pull the changes from the remote repo and run `./install` to sync the new changes.

---

Based on this great course [dotfiles.eieio.xyz](http://dotfiles.eieio.xyz)
