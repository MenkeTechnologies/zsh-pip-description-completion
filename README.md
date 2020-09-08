# zsh-pip-description-completion

This plugin has all functionality of OMZ pip completion but it also allows `pip install <tab>` to complete remote pip packages from output of `pip search`.
The descriptions in the zsh menu completions are the version number and decription.

## Install for Zinit
> `~/.zshrc`
```sh
source "$HOME/.zinit/bin/zinit.zsh"
zinit ice lucid nocompile
zinit load MenkeTechnologies/zsh-pip-description-completion
```

## Install for Oh My Zsh

```sh
cd "$HOME/.oh-my-zsh/custom/plugins"  && git clone https://github.com/MenkeTechnologies/zsh-pip-description-completion.git
```

Add `zsh-pip-description-completion` to plugins array in ~/.zshrc

## General Install

```sh
git clone https://github.com/MenkeTechnologies/zsh-pip-description-completion.git
```

source zsh-pip-description-completion.plugin.zsh or add code to zshrc or any startup script
