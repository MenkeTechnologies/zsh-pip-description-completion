# Usage:
# Just add pip to your installed plugins.

# If you would like to change the cheeseshops used for autocomplete set
# ZSH_PIP_INDEXES in your zshrc. If one of your indexes are bogus you won't get
# any kind of error message, pip will just not autocomplete from them. Double
# check!
#
# If you would like to clear your cache, go ahead and do a
# "zsh-pip-clear-cache".

ZSH_PIP_CACHE_FILE=~/.pip/zsh-cache
ZSH_PIP_INDEXES=(https://pypi.org/simple/)

alias pip="noglob pip" # allows square brackets for pip command invocation

0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# comps
fpath=("${0:h}/src" $fpath)

# util fns
fpath+=("${0:h}/autoload")
autoload -Uz "${0:h}/autoload/"*(.:t)

alias pin='python3 -m pip install'
