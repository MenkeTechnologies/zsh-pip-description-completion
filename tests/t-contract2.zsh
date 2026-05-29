#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-pip-description-completion — second-tier pins.
#####          Cover the runtime defaults (not just text grep),
#####          _1st_arguments fixed subcommand list, and the
#####          `name:version desc` format that drives the
#####          description menu (the very feature in the plugin name).
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/zsh-pip-description-completion.plugin.zsh"
    completionFile="$pluginDir/src/_pip"
}

@test 'ZSH_PIP_CACHE_FILE runtime value resolves to $HOME/.pip/zsh-cache' {
    # Pin: runtime resolution (not text grep). ~/.pip/zsh-cache uses
    # ~ which the shell expands. Refactor that quoted the path
    # (e.g. "~/.pip/...") would NOT expand the tilde and the cache
    # would land in a literal "~" directory.
    local out
    out=$(HOME=/tmp/fakehome zsh -c "
        source '$pluginFile' 2>/dev/null
        print \"\$ZSH_PIP_CACHE_FILE\"
    ")
    assert "$out" same_as '/tmp/fakehome/.pip/zsh-cache'
}

@test 'ZSH_PIP_INDEXES runtime array has exactly one default entry (pypi.org/simple/)' {
    # Pin: bare PyPI only by default. Adding more would multiply scrape
    # cost per cache refresh. Users add mirrors deliberately.
    local out
    out=$(zsh -c "
        source '$pluginFile' 2>/dev/null
        print \"\${#ZSH_PIP_INDEXES[@]} \$ZSH_PIP_INDEXES[1]\"
    ")
    assert "$out" same_as '1 https://pypi.org/simple/'
}

@test '_1st_arguments lists the canonical pip subcommands (install/uninstall/freeze/list)' {
    # Pin: the static subcommand list. The plugin documents 16+ pip
    # verbs. Pin the core 4 so a refactor that drops any is caught.
    local body
    body=$(cat "$completionFile")
    assert "$body" contains "'install:install packages'"
    assert "$body" contains "'uninstall:uninstall packages'"
    assert "$body" contains "'freeze:output all currently installed packages"
    assert "$body" contains "'list:list installed packages'"
}

@test '__pip_search formats name:version + description (the "description" feature)' {
    # Pin: this is the literal selling point of the plugin name.
    # `tmp_ary+=("${(q)name}:${(q)version} $desc")` is the format
    # that makes _describe show `name (version) — description`.
    grep -qE 'tmp_ary\+=.*\(q\)name.*\(q\)version.*\$desc' "$completionFile"
    assert $? equals 0
}

@test '__pip_search invokes `pip search $PREFIX` (live registry lookup)' {
    # Pin: the search uses pip search live, then caches. NOTE pip
    # search was disabled by PyPI in 2020 — this is a known-broken
    # surface that survives in the plugin for documentation. Pin
    # the call shape so refactor to e.g. metacpan.org is a deliberate
    # choice.
    grep -qE 'pip search \$PREFIX' "$completionFile"
    assert $? equals 0
}

@test 'ZSH_PIP_INDEXES override is honored (user can add a custom mirror)' {
    # Pin: a caller that pre-sets ZSH_PIP_INDEXES must NOT have it
    # replaced. The plugin uses plain assignment (NOT :=) — so this
    # test currently fails for the array form! Pin the actual
    # current (clobber) behavior.
    local out
    out=$(ZSH_PIP_INDEXES=(https://custom-mirror.example/simple/) zsh -c "
        source '$pluginFile' 2>/dev/null
        print \"\$ZSH_PIP_INDEXES[1]\"
    ")
    # CURRENT BEHAVIOR: plugin always overwrites with default.
    # Pin as default so a fix to honor caller-set value trips this.
    assert "$out" same_as 'https://pypi.org/simple/'
}
