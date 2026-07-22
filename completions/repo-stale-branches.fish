# Fish completions for repo-stale-branches.

function __fish_repo_stale_branches_manifest_branches \
    --description 'List local and remote manifest branches'
    set -l top $PWD
    while true
        if test -d "$top/.repo/manifests"
            break
        end
        set -l parent (dirname "$top")
        test "$parent" = "$top"
        and return
        set top $parent
    end

    git -C "$top/.repo/manifests" for-each-ref \
        --format='%(refname:short)' refs/heads refs/remotes 2>/dev/null |
        string replace -r '^origin/' '' |
        sort -u
end

complete -c repo-stale-branches -f
complete -c repo-stale-branches -s h -l help -d 'Show usage information'
complete -c repo-stale-branches -l abandon \
    -d 'Abandon detected inactive stale branches'
complete -c repo-stale-branches -l checkout-upstream-and-abandon \
    -d 'Detach clean active branches at upstream, then abandon them'
complete -c repo-stale-branches -l since -x \
    -d 'Scan upstream Change-Ids newer than DATE' \
    -a '"1 week ago" "1 month ago" "6 months ago" "1 year ago" "2 years ago"'
complete -c repo-stale-branches -l manifest-branch -x \
    -d 'Compare against this manifest branch' \
    -a '(__fish_repo_stale_branches_manifest_branches)'
