```
 ███████╗███████╗██╗  ██╗
 ╚══███╔╝██╔════╝██║  ██║
   ███╔╝ ███████╗███████║
  ███╔╝  ╚════██║██╔══██║
 ███████╗███████║██║  ██║
 ╚══════╝╚══════╝╚═╝  ╚═╝
       [ p i p ]
```

[![CI](https://github.com/MenkeTechnologies/zsh-pip-description-completion/actions/workflows/ci.yml/badge.svg)](https://github.com/MenkeTechnologies/zsh-pip-description-completion/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![zsh](https://img.shields.io/badge/zsh-plugin-cyan.svg)](https://github.com/MenkeTechnologies/zpwr)

### `[PIP COMPLETION FOR ZSH // REMOTE PACKAGES + DESCRIPTIONS IN MENU]`

> *"`pip install <TAB>` with version + description."*

This plugin has all functionality of OMZ pip completion but it also allows `pip install <tab>` to complete remote pip packages from output of `pip search`.
The descriptions in the zsh menu completions are the version number and decription.

### [`strykelang`](https://github.com/MenkeTechnologies/strykelang) &middot; [`zshrs`](https://github.com/MenkeTechnologies/zshrs) · [`MenkeTechnologiesMeta`](https://github.com/MenkeTechnologies/MenkeTechnologiesMeta) · [`zsh-cargo-completion`](https://github.com/MenkeTechnologies/zsh-cargo-completion) · [`zsh-gem-completion`](https://github.com/MenkeTechnologies/zsh-gem-completion) · [`zsh-more-completions`](https://github.com/MenkeTechnologies/zsh-more-completions) · [`zpwr`](https://github.com/MenkeTechnologies/zpwr)

---

## Table of Contents

- [\[0x00\] Install for Zinit](#0x00-install-for-zinit)
- [\[0x01\] Install for Oh My Zsh](#0x01-install-for-oh-my-zsh)
- [\[0x02\] General Install](#0x02-general-install)

---

## [0x00] Install for Zinit
> `~/.zshrc`
```sh
source "$HOME/.zinit/bin/zinit.zsh"
zinit ice lucid nocompile
zinit load MenkeTechnologies/zsh-pip-description-completion
```

## [0x01] Install for Oh My Zsh

```sh
cd "$HOME/.oh-my-zsh/custom/plugins"  && git clone https://github.com/MenkeTechnologies/zsh-pip-description-completion.git
```

Add `zsh-pip-description-completion` to plugins array in ~/.zshrc

## [0x02] General Install

```sh
git clone https://github.com/MenkeTechnologies/zsh-pip-description-completion.git
```

source zsh-pip-description-completion.plugin.zsh or add code to zshrc or any startup script
