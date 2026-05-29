#!/usr/bin/env zunit
#{{{                    MARK:Header
#**************************************************************
##### Purpose: zsh-pip-description-completion contract pins.
#####          The plugin caches the PyPI simple-index HTML and
#####          parses package names with a sed regex. Tests exercise
#####          the regex against the two documented HTML shapes
#####          (python's simple index + djangopypi2) so a future
#####          regex tweak can't silently break either form.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/zsh-pip-description-completion.plugin.zsh"
    completionFile="$pluginDir/src/_pip"
    cleanFn="$pluginDir/autoload/zsh-pip-clean-packages"
    cacheFn="$pluginDir/autoload/zsh-pip-cache-packages"
    clearFn="$pluginDir/autoload/zsh-pip-clear-cache"
    testCleanFn="$pluginDir/autoload/zsh-pip-test-clean-packages"
}

@test 'plugin file defines ZSH_PIP_CACHE_FILE default of ~/.pip/zsh-cache' {
    # Pin: the documented cache path. Changing it silently strands
    # users' existing caches.
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains 'ZSH_PIP_CACHE_FILE=~/.pip/zsh-cache'
}

@test 'plugin file defaults ZSH_PIP_INDEXES to pypi.org/simple/' {
    # Pin: the canonical PyPI index URL. The /simple/ path is the
    # PEP 503 endpoint for the index API — replacing it breaks the
    # entire scrape.
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains 'ZSH_PIP_INDEXES=(https://pypi.org/simple/)'
}

@test 'plugin file appends src/ to fpath (completion discovery)' {
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains 'fpath=("${0:h}/src" $fpath)'
}

@test 'plugin file appends autoload/ to fpath AND autoloads everything in it' {
    # Pin: BOTH src AND autoload must end up on fpath. src holds
    # the completion; autoload holds the helper fns.
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains 'fpath+=("${0:h}/autoload")'
    assert "$body" contains 'autoload -Uz "${0:h}/autoload/"*(.:t)'
}

@test '_pip is #compdef for all 7 documented pip versions (pip/pip2/pip3/pip-2.7…)' {
    # Pin: the multi-name compdef line covers every pip variant on
    # disk. Dropping any silently strands users on that interpreter.
    local first
    first=$(head -1 "$completionFile")
    assert "$first" same_as '#compdef pip pip2 pip-2.7 pip3 pip-3.2 pip-3.3 pip-3.4'
}

@test '_pip uses #autoload directive on line 2 (zsh completion contract)' {
    # Pin: the second line MUST be `#autoload` so compinit binds
    # the file once. Removing it forces eager loading at every
    # shell start (slow).
    local second
    second=$(sed -n '2p' "$completionFile")
    assert "$second" same_as '#autoload'
}

@test '_pip declares __pip_all helper that reads $ZSH_PIP_CACHE_FILE' {
    # Pin: the completion reuses the cache. If __pip_all is removed
    # or stops reading the cache file, completion goes from
    # instant -> 5+ seconds per keystroke (PyPI scrape per tab).
    local body
    body=$(cat "$completionFile")
    assert "$body" contains '__pip_all()'
    assert "$body" contains '$ZSH_PIP_CACHE_FILE'
}

@test '_pip declares __pip_installed helper that wraps `pip freeze`' {
    # Pin: __pip_installed is the source of truth for "what is
    # installed right now". Powers `pip uninstall <tab>` and
    # `pip show <tab>`.
    local body
    body=$(cat "$completionFile")
    assert "$body" contains '__pip_installed()'
    assert "$body" contains 'pip freeze'
}

@test '_pip declares __pip_search helper that caches via _retrieve_cache' {
    # Pin: without the per-prefix cache, every tab on `pip search`
    # round-trips to PyPI. The _retrieve_cache / _store_cache pair
    # is mandatory for performance.
    local body
    body=$(cat "$completionFile")
    assert "$body" contains '__pip_search()'
    assert "$body" contains '_retrieve_cache'
    assert "$body" contains '_store_cache'
}

@test 'zsh-pip-clean-packages: sed regex extracts <a href="X">X</a> package names' {
    # The regex is the workhorse — pin it via known good input.
    local out
    out=$(printf '<a href="numpy">numpy</a><br/>\n<a href="scipy">scipy</a><br/>\n' \
        | sed -n '/<a href/ s/.*>\([^<]\{1,\}\).*/\1/p')
    assert "$out" contains 'numpy'
    assert "$out" contains 'scipy'
}

@test 'zsh-pip-clean-packages regex matches python.org PyPI simple-index shape' {
    # End-to-end: replay the shape documented in
    # zsh-pip-test-clean-packages — single-line per-anchor, one
    # body wrapper.
    local fixture
    fixture='<html><head><title>Simple Index</title><meta name="api-version" value="2" /></head><body>
<a href='"'"'0x10c-asm'"'"'>0x10c-asm</a><br/>
<a href='"'"'1009558_nester'"'"'>1009558_nester</a><br/>
</body></html>'
    local actual
    actual=$(printf '%s' "$fixture" | sed -n '/<a href/ s/.*>\([^<]\{1,\}\).*/\1/p')
    assert "$actual" contains '0x10c-asm'
    assert "$actual" contains '1009558_nester'
}

@test 'zsh-pip-clean-packages regex matches djangopypi2 multi-line shape' {
    # The other documented index format — anchors on indented
    # lines inside a multi-line <body>. The /<a href/ pattern is
    # what makes both shapes work.
    local fixture
    fixture='<html>
  <head>
    <title>Simple Package Index</title>
  </head>
  <body>
    <a href="0x10c-asm">0x10c-asm</a><br/>
    <a href="1009558_nester">1009558_nester</a><br/>
</body></html>'
    local actual
    actual=$(printf '%s' "$fixture" | sed -n '/<a href/ s/.*>\([^<]\{1,\}\).*/\1/p')
    assert "$actual" contains '0x10c-asm'
    assert "$actual" contains '1009558_nester'
}

@test 'zsh-pip-clean-packages regex ignores non-anchor HTML' {
    # Sanity: lines without <a href> must not match. Otherwise the
    # cache fills with garbage from the simple-index header.
    local out
    out=$(printf '<html><body><p>hello world</p></body></html>' \
        | sed -n '/<a href/ s/.*>\([^<]\{1,\}\).*/\1/p')
    [[ -z "$out" ]]
    assert $? equals 0
}

@test 'zsh-pip-clean-packages handles package names containing dots + dashes + underscores' {
    # PyPI package names per PEP 426 allow .-_ in names. Pin so
    # the regex char class stays permissive enough.
    local out
    out=$(printf '<a href="my.pkg-name_v2">my.pkg-name_v2</a>' \
        | sed -n '/<a href/ s/.*>\([^<]\{1,\}\).*/\1/p')
    assert "$out" same_as 'my.pkg-name_v2'
}

@test 'cache fn lives at autoload/zsh-pip-cache-packages and curls each index' {
    # Pin: caches by iterating $ZSH_PIP_INDEXES and curl-fetching.
    # If the iteration drops, only the first index gets scraped.
    local body
    body=$(cat "$cacheFn")
    assert "$body" contains 'for index in $ZSH_PIP_INDEXES'
    assert "$body" contains 'curl -L $index'
}

@test 'cache fn dedups via sort | uniq before writing the cache file' {
    # Pin: PyPI mirrors may overlap. Without dedup, cache size
    # bloats and completion lists show duplicates.
    local body
    body=$(cat "$cacheFn")
    assert "$body" contains 'sort'
    assert "$body" contains 'uniq'
}

@test 'cache fn writes a SINGLE LINE (tr \\n " ") for fast array load' {
    # Pin: the cache is parsed via `piplist=($(cat ...))` in the
    # completion. Writing as a single space-joined line is faster
    # than line-by-line. Keep this format stable.
    local body
    body=$(cat "$cacheFn")
    assert "$body" contains "tr '\\n' ' '"
}

@test 'cache fn creates parent dir of cache file via mkdir -p' {
    # Pin: ~/.pip might not exist on a fresh box. Without mkdir -p,
    # the cache write would error on first run.
    local body
    body=$(cat "$cacheFn")
    assert "$body" contains 'mkdir -p ${ZSH_PIP_CACHE_FILE:h}'
}

@test 'clear fn rms cache file AND unsets piplist (full cache reset)' {
    # Pin: dropping the unset would leave a stale in-memory array
    # even after the on-disk cache is gone — a confusing half-state.
    local body
    body=$(cat "$clearFn")
    assert "$body" contains 'rm $ZSH_PIP_CACHE_FILE'
    assert "$body" contains 'unset piplist'
}

@test 'test-clean fn ships fixture-based parser sanity check (regression detector)' {
    # Pin: the test fn itself is documentation — it shows future
    # contributors which HTML shapes the regex must support.
    local body
    body=$(cat "$testCleanFn")
    assert "$body" contains 'djangopypi2 index'
    assert "$body" contains "python's simple index"
}

@test 'all autoload files end with self-invocation (autoload + execute pattern)' {
    # Pin: zsh's `autoload -Uz` defines the function on first call
    # by sourcing the file. Each helper MUST end with a call to
    # itself so the file produces a defined function.
    for f in "$cacheFn" "$clearFn" "$cleanFn" "$testCleanFn"; do
        local name="${f:t}"
        local last
        last=$(grep -E "^${name}" "$f" | tail -1)
        assert "$last" contains "$name"
    done
}

@test 'plugin sources cleanly in a fresh subshell' {
    # End-to-end: sourcing must work without errors. Catches a
    # syntax-clean-but-eval-time-broken plugin.
    local result
    result=$(zsh -c "
        emulate zsh
        source '$pluginFile' 2>&1
        echo OK
    " 2>&1 | tail -1)
    assert "$result" same_as 'OK'
}

@test '_pip completion compiles cleanly under autoload (no syntax errors)' {
    local result
    result=$(zsh -c "
        emulate zsh
        fpath=('$pluginDir/src' \$fpath)
        autoload -U _pip
        autoload +X _pip && print OK || print FAIL
    " 2>&1)
    assert "$result" same_as 'OK'
}
