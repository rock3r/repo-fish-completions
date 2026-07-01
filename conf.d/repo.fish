# repo completion cache invalidation.
#
# The repo completions (completions/repo.fish) cache the project list and the
# local branch list for the session so `repo list` / `repo forall` aren't re-run
# on every Tab. This file clears those caches after commands that change them,
# using fish's `fish_postexec` event (fired after every command line).
#
# It lives in conf.d/ rather than completions/ because completion files are
# autoloaded lazily — only on the first repo Tab — which is too late to register
# an event handler. conf.d/ is sourced at startup, so the handler is always live.

function __fish_repo_invalidate_cache --on-event fish_postexec
    # $argv[1] is the full command line that just ran.
    set -l toks (string split ' ' -- (string trim -- $argv[1]))
    test (count $toks) -ge 2
    or return
    test "$toks[1]" = repo
    or return

    # First non-flag token after `repo` is the subcommand (skips global options
    # like -p / --color=auto). A stray flag value could be misread, but that only
    # ever causes a harmless extra cache rebuild.
    set -l sub ''
    for t in $toks[2..-1]
        if string match -q -- '-*' $t
            continue
        end
        set sub $t
        break
    end

    # Subcommands that change the set of local topic branches.
    if contains -- $sub start abandon checkout download
        set -e __repo_branch_cache
    end

    # Subcommands that change the project set / manifest layout.
    if contains -- $sub init sync smartsync wipe start abandon checkout download
        set -e __repo_project_cache
    end
end
