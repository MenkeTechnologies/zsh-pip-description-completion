#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-pip-description-completion — fourth-tier contracts.
#####          Pins for cache-build pipeline: directory-create guard,
#####          existence-cache (no re-build if file present), the
#####          curl-pipe-sed dataflow shape, and the sort+uniq+tr
#####          newline-to-space normalization.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    cacheFile="$pluginDir/autoload/zsh-pip-cache-packages"
    cleanFile="$pluginDir/autoload/zsh-pip-clean-packages"
}

@test 'cache builder creates parent directory before touching the cache file' {
    # Pin: the guard `if [[ ! -d ${ZSH_PIP_CACHE_FILE:h} ]]; then mkdir -p`
    # ensures `~/.pip` exists before writes. Removing the guard would
    # error on first-ever invocation when ~/.pip does not exist.
    grep -qE 'if \[\[ ! -d \$\{ZSH_PIP_CACHE_FILE:h\} \]\]; then' "$cacheFile"
    local guard=$?
    grep -qE 'mkdir -p \$\{ZSH_PIP_CACHE_FILE:h\}' "$cacheFile"
    local mk=$?
    assert $(( guard + mk )) equals 0
}

@test 'cache existence-check skips rebuild when file present (TTL=infinite)' {
    # Pin: the rebuild branch is gated by `if [[ ! -f $ZSH_PIP_CACHE_FILE ]]`.
    # Once built, subsequent calls are a no-op until the user runs
    # `zsh-pip-clear-cache`. Pin the guard and the absence of any time
    # comparison or TTL arithmetic.
    grep -qE 'if \[\[ ! -f \$ZSH_PIP_CACHE_FILE \]\]; then' "$cacheFile"
    local guard=$?
    # No TTL math anywhere in the file.
    ! grep -qE '(EPOCHSECONDS|date \+%s|stat -c %Y)' "$cacheFile"
    local no_ttl=$?
    assert $(( guard + no_ttl )) equals 0
}

@test 'curl pipeline pipes through zsh-pip-clean-packages then appends to tmp_cache' {
    # Pin: the dataflow is `curl URL | clean >> tmp_cache`. Dropping
    # the >> appends and using > would clobber on each iteration,
    # leaving only the LAST index's packages. Pin the append redirect.
    awk '/for index in \$ZSH_PIP_INDEXES/,/^[[:space:]]*done/' "$cacheFile" > /tmp/pip_loop.$$
    grep -qE 'zsh-pip-clean-packages' /tmp/pip_loop.$$
    local pipe=$?
    grep -qE '>> \$tmp_cache' /tmp/pip_loop.$$
    local appnd=$?
    rm -f /tmp/pip_loop.$$
    assert $(( pipe + appnd )) equals 0
}

@test 'final cache normalization: sort | uniq | tr newline-to-space' {
    # Pin: the canonical form for the cache file is space-separated
    # so it can be read into an array via `arr=(${(z)$(<file)})`.
    # Dropping `tr` leaves it newline-separated and breaks completion.
    grep -qE 'sort \$tmp_cache \| uniq \| tr' "$cacheFile"
    local has_pipe=$?
    grep -qF "> \$ZSH_PIP_CACHE_FILE" "$cacheFile"
    local has_redir=$?
    assert $(( has_pipe + has_redir )) equals 0
}

@test 'zsh-pip-clean-packages: sed -n with /<a href/ filter and single-capture group' {
    # Pin: malformed pip-list (no <a href tags) yields zero output —
    # the cache file then exists but is empty. The completion gracefully
    # falls back to empty candidate set. Pin the sed program AND verify
    # that feeding it non-anchor lines yields empty output.
    grep -qE "sed -n '/<a href/ s/" "$cleanFile"
    local has_sed=$?
    local out
    out=$(printf 'no anchors here\njust plain text\n' | zsh -c "source '$cleanFile'; zsh-pip-clean-packages")
    assert $has_sed equals 0
    assert "$out" is_empty
}
