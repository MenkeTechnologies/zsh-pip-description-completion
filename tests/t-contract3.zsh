#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-pip-description-completion — third-tier surface pins:
#####          - _pip has #autoload directive on line 2 (compsys defer-load)
#####          - cache fn uses ${VAR:h} (head modifier) for parent dir, NOT dirname
#####          - cache fn cleans up /tmp/zsh_tmp_cache (no temp-file leak)
#####          - clear fn UNSETS piplist (not just rm the file)
#####          - _pip's _1st_arguments includes every documented subcommand
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/zsh-pip-description-completion.plugin.zsh"
    pipFile="$pluginDir/src/_pip"
    cacheFile="$pluginDir/autoload/zsh-pip-cache-packages"
    clearFile="$pluginDir/autoload/zsh-pip-clear-cache"
}

@test '_pip has #autoload directive on line 2 (compsys defer-load contract)' {
    # Pin: `#autoload` on line 2 tells compinit to defer loading until
    # first invocation. Without it, the entire _pip body parses at
    # shell startup — adds ~5ms per shell.
    local line2
    line2=$(sed -n '2p' "$pipFile")
    assert "$line2" same_as '#autoload'
}

@test 'cache fn uses ${VAR:h} (head modifier) for parent dir lookup' {
    # Pin: `${ZSH_PIP_CACHE_FILE:h}` is the zsh-native parent-dir extract.
    # Using `$(dirname $ZSH_PIP_CACHE_FILE)` would fork a process per
    # check — significant on hot paths.
    grep -qF '${ZSH_PIP_CACHE_FILE:h}' "$cacheFile"
    assert $? equals 0
}

@test 'cache fn removes /tmp/zsh_tmp_cache after consolidation (no leak)' {
    # Pin: the staging file `/tmp/zsh_tmp_cache` is consolidated into
    # the real cache; without the `rm $tmp_cache` cleanup, the temp
    # file persists across runs and grows on repeat invocation.
    grep -qE 'rm[[:space:]]+\$tmp_cache' "$cacheFile"
    assert $? equals 0
}

@test 'clear fn unsets piplist (not just rms cache file)' {
    # Pin: clear MUST `unset piplist` so the next __pip_all run repopulates
    # from disk. Without the unset, the in-memory array stays cached
    # forever — clear is a no-op until shell restart.
    grep -qE '^[[:space:]]*unset piplist' "$clearFile"
    assert $? equals 0
}

@test '_1st_arguments includes the 4 most-used pip subcommands (install/uninstall/freeze/list)' {
    # Pin: these are the canonical pip verbs. Dropping any silently
    # disables completion for a common workflow.
    local missing="" v
    for v in install uninstall freeze list; do
        grep -qE "'$v:" "$pipFile" || missing="$missing $v"
    done
    assert "$missing" is_empty
}
