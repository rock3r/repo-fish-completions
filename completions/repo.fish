# Fish completions for the Android `repo` (git-repo) tool.
#
# Generated from the repo source tree (gerrit.googlesource.com/git-repo).
#
# Dynamic completions provided:
#   * subcommand names                  (everywhere)
#   * project names & paths             (commands taking [<project>...])
#   * local topic-branch names          (start / checkout / abandon / download -b / upload --branch)
#   * manifest XML files                (diffmanifests / manifest -m / sync -m)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# All subcommands (incl. aliases) understood by `repo`.
set -g __repo_subcommands \
    abandon branch branches checkout cherry-pick diff diffmanifests download \
    forall gc grep help info init list manifest overview prune rebase \
    selfupdate smartsync stage start status sync upload version wipe

# True if the current token is NOT the first positional argument of a subcommand.
function __fish_repo_not_first_arg
    not __fish_is_nth_token 2
end

# Project list: completes both project NAME and project PATH (repo matches both).
function __fish_repo_projects --description 'List repo projects (name + path)'
    if set -q __repo_project_cache
        printf '%s\n' $__repo_project_cache
        return
    end

    # Bail out fast if we are not inside a repo client checkout.
    repo --show-toplevel >/dev/null 2>&1
    or return

    set -l lines (repo list 2>/dev/null)
    test -n "$lines"
    or return

    set -g __repo_project_cache
    for line in $lines
        # repo list default format: "<relpath> : <name>"
        set -l parts (string split " : " -- $line)
        if test (count $parts) -eq 2
            set -l relpath $parts[1]
            set -l name $parts[2]
            printf '%s\t%s\n' $name $relpath
            printf '%s\t%s\n' $relpath $name
            set -a __repo_project_cache $name
            set -a __repo_project_cache $relpath
        else
            printf '%s\n' $line
            set -a __repo_project_cache $line
        end
    end
end

# Local topic branches across every project in the client.
function __fish_repo_branches --description 'List local branches across all repo projects'
    if set -q __repo_branch_cache
        printf '%s\n' $__repo_branch_cache
        return
    end

    repo --show-toplevel >/dev/null 2>&1
    or return

    set -l branches (
        # NB: the %(refname:short) format MUST be quoted — repo forall hands the
        # -c argument to `sh -c`, and bare parentheses are parsed as subshells.
        repo forall --ignore-missing -c \
            'git for-each-ref --format="%(refname:short)" refs/heads/' 2>/dev/null |
        string trim | sort -u
    )
    test -n "$branches"
    or return

    set -g __repo_branch_cache $branches
    printf '%s\n' $branches
end

# Manifest XML files (local manifest snapshots / -m inputs).
function __fish_repo_manifest_files --description 'List manifest XML files'
    set -l toplevel (repo --show-toplevel 2>/dev/null)
    or return
    set -l manifestsdir "$toplevel/.repo/manifests"
    test -d "$manifestsdir"
    or return
    find "$manifestsdir" -maxdepth 1 -name '*.xml' -exec basename {} \; 2>/dev/null | sort -u
end

# ---------------------------------------------------------------------------
# Top-level: `repo <TAB>` -> global options + subcommands
# ---------------------------------------------------------------------------

complete -c repo -n __fish_use_subcommand -f -a "$__repo_subcommands"

complete -c repo -n __fish_use_subcommand -s h -l help -d 'Show help'
complete -c repo -n __fish_use_subcommand -l help-all -d 'Show help for all subcommands'
complete -c repo -n __fish_use_subcommand -s p -l paginate -d 'Use pager for output'
complete -c repo -n __fish_use_subcommand -l no-pager -d 'Disable pager'
complete -c repo -n __fish_use_subcommand -l color -d 'Color: auto|always|never' -x -a "auto\t'' always\t'' never\t''"
complete -c repo -n __fish_use_subcommand -l trace -d 'Trace git command execution'
complete -c repo -n __fish_use_subcommand -l trace-to-stderr -d 'Send trace output to stderr too'
complete -c repo -n __fish_use_subcommand -l trace-python -d 'Trace python execution'
complete -c repo -n __fish_use_subcommand -l time -d 'Time repo command execution'
complete -c repo -n __fish_use_subcommand -l version -d 'Print repo version'
complete -c repo -n __fish_use_subcommand -l show-toplevel -d 'Print path of repo client checkout'
complete -c repo -n __fish_use_subcommand -l event-log -d 'Event log file to append to'
complete -c repo -n __fish_use_subcommand -l git-trace2-event-log -d 'Directory for git trace2 event log'
complete -c repo -n __fish_use_subcommand -l submanifest-path -d 'Submanifest path'

# ---------------------------------------------------------------------------
# Options common to (almost) every subcommand
# ---------------------------------------------------------------------------

# Set of subcommands that operate on projects within a manifest and therefore
# accept the common logging / multi-manifest flags.
set -g __repo_manifest_cmds \
    abandon branches checkout cherry-pick diff download forall grep info list \
    manifest overview prune rebase smartsync stage start status sync upload

for cmd in $__repo_manifest_cmds
    complete -c repo -n "__fish_seen_subcommand_from $cmd" -s v -l verbose -d 'Show all output'
    complete -c repo -n "__fish_seen_subcommand_from $cmd" -s q -l quiet -d 'Show errors only'
    complete -c repo -n "__fish_seen_subcommand_from $cmd" -l outer-manifest -d 'Start at outermost manifest'
    complete -c repo -n "__fish_seen_subcommand_from $cmd" -l no-outer-manifest -d 'Do not operate on outer manifests'
    complete -c repo -n "__fish_seen_subcommand_from $cmd" -l this-manifest-only -d 'Only this (sub)manifest'
    complete -c repo -n "__fish_seen_subcommand_from $cmd" -l no-this-manifest-only -l all-manifests -d 'This manifest and its submanifests'
end

# Commands with parallel jobs (-j).
set -g __repo_parallel_cmds \
    abandon branches checkout forall grep rebase stage start status sync upload
for cmd in $__repo_parallel_cmds
    complete -c repo -n "__fish_seen_subcommand_from $cmd" -s j -l jobs -d 'Number of parallel jobs' -r
end

# ---------------------------------------------------------------------------
# Per-subcommand options & positional arguments
# ---------------------------------------------------------------------------

# --- abandon -------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from abandon' -l all -d 'Delete all branches in all projects'
complete -c repo -n '__fish_seen_subcommand_from abandon; and __fish_is_nth_token 2' -f -a '(__fish_repo_branches)' -d 'branch'
complete -c repo -n '__fish_seen_subcommand_from abandon; and __fish_repo_not_first_arg' -f -a '(__fish_repo_projects)' -d 'project'

# --- branches / branch (alias) ------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from branches branch' -f -a '(__fish_repo_projects)' -d 'project'

# --- checkout -----------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from checkout; and __fish_is_nth_token 2' -f -a '(__fish_repo_branches)' -d 'branch'
complete -c repo -n '__fish_seen_subcommand_from checkout; and __fish_repo_not_first_arg' -f -a '(__fish_repo_projects)' -d 'project'

# --- cherry-pick --------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from cherry-pick; and __fish_is_nth_token 2' -f -d 'sha1'

# --- diff ---------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from diff' -l absolute -d 'Paths relative to repo root'
complete -c repo -n '__fish_seen_subcommand_from diff' -f -a '(__fish_repo_projects)' -d 'project'

# --- diffmanifests ------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from diffmanifests' -l raw -d 'Display raw diff'
complete -c repo -n '__fish_seen_subcommand_from diffmanifests' -l no-color -d 'Disable color'
complete -c repo -n '__fish_seen_subcommand_from diffmanifests' -l pretty-format -d 'Custom git pretty format' -r
complete -c repo -n '__fish_seen_subcommand_from diffmanifests' -f -a '(__fish_repo_manifest_files)' -d 'manifest'

# --- download -----------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from download' -s b -l branch -d 'Create a new branch first' -x -a '(__fish_repo_branches)'
complete -c repo -n '__fish_seen_subcommand_from download' -s c -l cherry-pick -d 'Cherry-pick instead of checkout'
complete -c repo -n '__fish_seen_subcommand_from download' -s x -l record-origin -d 'Pass -x when cherry-picking'
complete -c repo -n '__fish_seen_subcommand_from download' -s r -l revert -d 'Revert instead of checkout'
complete -c repo -n '__fish_seen_subcommand_from download' -s f -l ff-only -d 'Force fast-forward merge'
complete -c repo -n '__fish_seen_subcommand_from download' -f -a '(__fish_repo_projects)' -d 'project / change[/patchset]'

# --- forall -------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from forall' -s r -l regex -d 'Run on projects matching regex/wildcard'
complete -c repo -n '__fish_seen_subcommand_from forall' -s i -l inverse-regex -d 'Run on projects NOT matching regex'
complete -c repo -n '__fish_seen_subcommand_from forall' -s g -l groups -d 'Run on projects in these groups' -r
complete -c repo -n '__fish_seen_subcommand_from forall' -s c -l command -d 'Command (and args) to execute' -r
complete -c repo -n '__fish_seen_subcommand_from forall' -s e -l abort-on-errors -d 'Abort if command exits non-zero'
complete -c repo -n '__fish_seen_subcommand_from forall' -l ignore-missing -d 'Skip missing checkouts'
complete -c repo -n '__fish_seen_subcommand_from forall' -s p -d 'Show project headers before output'
complete -c repo -n '__fish_seen_subcommand_from forall' -l interactive -d 'Force interactive usage'
complete -c repo -n '__fish_seen_subcommand_from forall' -f -a '(__fish_repo_projects)' -d 'project'

# --- gc -----------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from gc' -s n -l dry-run -d 'Do everything except delete'
complete -c repo -n '__fish_seen_subcommand_from gc' -s y -l yes -d 'Answer yes to all safe prompts'
complete -c repo -n '__fish_seen_subcommand_from gc' -l repack -d 'Repack partial-clone projects'

# --- grep ---------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from grep' -s e -d 'Pattern to search for' -r
complete -c repo -n '__fish_seen_subcommand_from grep' -s i -l ignore-case -d 'Ignore case'
complete -c repo -n '__fish_seen_subcommand_from grep' -s a -l text -d 'Process binary as text'
complete -c repo -n '__fish_seen_subcommand_from grep' -s I -d "Don't match in binary files"
complete -c repo -n '__fish_seen_subcommand_from grep' -s w -l word-regexp -d 'Match at word boundaries'
complete -c repo -n '__fish_seen_subcommand_from grep' -s v -l invert-match -d 'Select non-matching lines'
complete -c repo -n '__fish_seen_subcommand_from grep' -s G -l basic-regexp -d 'POSIX basic regexp (default)'
complete -c repo -n '__fish_seen_subcommand_from grep' -s E -l extended-regexp -d 'POSIX extended regexp'
complete -c repo -n '__fish_seen_subcommand_from grep' -s F -l fixed-strings -d 'Fixed strings, not regexp'
complete -c repo -n '__fish_seen_subcommand_from grep' -l cached -d 'Search the index'
complete -c repo -n '__fish_seen_subcommand_from grep' -s r -l revision -d 'Tree-ish to search' -r
complete -c repo -n '__fish_seen_subcommand_from grep' -l all-match -d 'Lines must match all patterns'
complete -c repo -n '__fish_seen_subcommand_from grep' -l and -l or -l not -d 'Boolean operators'
complete -c repo -n '__fish_seen_subcommand_from grep' -s n -d 'Prefix line numbers'
complete -c repo -n '__fish_seen_subcommand_from grep' -s C -d 'Context lines around match' -r
complete -c repo -n '__fish_seen_subcommand_from grep' -s B -d 'Context lines before match' -r
complete -c repo -n '__fish_seen_subcommand_from grep' -s A -d 'Context lines after match' -r
complete -c repo -n '__fish_seen_subcommand_from grep' -s l -l name-only -l files-with-matches -d 'Only file names with matches'
complete -c repo -n '__fish_seen_subcommand_from grep' -s L -l files-without-match -d 'Only file names without matches'
complete -c repo -n '__fish_seen_subcommand_from grep; and __fish_repo_not_first_arg' -f -a '(__fish_repo_projects)' -d 'project'

# --- help ---------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from help' -s a -l all -d 'Show complete list of commands'
complete -c repo -n '__fish_seen_subcommand_from help' -l help-all -d 'Show --help of all commands'
complete -c repo -n '__fish_seen_subcommand_from help' -f -a "$__repo_subcommands"

# --- info ---------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from info' -s d -l diff -d 'Full info incl. remote branches'
complete -c repo -n '__fish_seen_subcommand_from info' -s o -l overview -d 'Overview of local commits'
complete -c repo -n '__fish_seen_subcommand_from info' -s c -l current-branch -d 'Only checked-out branches'
complete -c repo -n '__fish_seen_subcommand_from info' -l no-current-branch -d 'Consider all local branches'
complete -c repo -n '__fish_seen_subcommand_from info' -s l -l local-only -d 'Disable remote operations'
complete -c repo -n '__fish_seen_subcommand_from info' -l include-summary -l no-include-summary -d 'Toggle manifest summary'
complete -c repo -n '__fish_seen_subcommand_from info' -l include-projects -l no-include-projects -d 'Toggle project details'
complete -c repo -n '__fish_seen_subcommand_from info' -l format -d 'Output format' -r
complete -c repo -n '__fish_seen_subcommand_from info' -f -a '(__fish_repo_projects)' -d 'project'

# --- init ---------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from init' -s u -l manifest-url -d 'Manifest repository URL' -r
complete -c repo -n '__fish_seen_subcommand_from init' -s b -l manifest-branch -d 'Manifest branch/revision' -r
complete -c repo -n '__fish_seen_subcommand_from init' -l manifest-upstream-branch -d 'Ref holding the --manifest-branch commit' -r
complete -c repo -n '__fish_seen_subcommand_from init' -s m -l manifest-name -d 'Initial manifest file' -r -a '(__fish_repo_manifest_files)'
complete -c repo -n '__fish_seen_subcommand_from init' -s g -l groups -d 'Restrict to groups' -r
complete -c repo -n '__fish_seen_subcommand_from init' -s p -l platform -d 'Restrict to platform group' -r
complete -c repo -n '__fish_seen_subcommand_from init' -l submodules -d 'Sync manifest submodules'
complete -c repo -n '__fish_seen_subcommand_from init' -l standalone-manifest -d 'Download manifest as static file'
complete -c repo -n '__fish_seen_subcommand_from init' -l manifest-depth -d 'Shallow clone depth of manifest repo' -r
complete -c repo -n '__fish_seen_subcommand_from init' -s c -l current-branch -d 'Fetch only current branch (default)'
complete -c repo -n '__fish_seen_subcommand_from init' -l no-current-branch -d 'Fetch all branches'
complete -c repo -n '__fish_seen_subcommand_from init' -l tags -d 'Fetch tags'
complete -c repo -n '__fish_seen_subcommand_from init' -l no-tags -d "Don't fetch tags"
complete -c repo -n '__fish_seen_subcommand_from init' -l mirror -d 'Create a replica (mirror)'
complete -c repo -n '__fish_seen_subcommand_from init' -l archive -d 'Checkout an archive'
complete -c repo -n '__fish_seen_subcommand_from init' -l worktree -d 'Use git-worktree'
complete -c repo -n '__fish_seen_subcommand_from init' -l use-local-gitdirs -d 'Use standard git layout'
complete -c repo -n '__fish_seen_subcommand_from init' -l reference -d 'Location of mirror directory' -r
complete -c repo -n '__fish_seen_subcommand_from init' -l dissociate -d 'Dissociate from reference after clone'
complete -c repo -n '__fish_seen_subcommand_from init' -l depth -d 'Shallow clone depth' -r
complete -c repo -n '__fish_seen_subcommand_from init' -l partial-clone -l no-partial-clone -d 'Toggle partial clone'
complete -c repo -n '__fish_seen_subcommand_from init' -l partial-clone-exclude -d 'Exclude projects from partial clone' -r
complete -c repo -n '__fish_seen_subcommand_from init' -l clone-filter -d 'Filter for partial clone' -r
complete -c repo -n '__fish_seen_subcommand_from init' -l use-superproject -l no-use-superproject -d 'Toggle manifest superproject'
complete -c repo -n '__fish_seen_subcommand_from init' -l clone-bundle -l no-clone-bundle -d 'Toggle /clone.bundle'
complete -c repo -n '__fish_seen_subcommand_from init' -l git-lfs -l no-git-lfs -d 'Toggle Git LFS'
complete -c repo -n '__fish_seen_subcommand_from init' -l repo-url -d 'repo repository location' -r
complete -c repo -n '__fish_seen_subcommand_from init' -l repo-rev -d 'repo branch or revision' -r
complete -c repo -n '__fish_seen_subcommand_from init' -l no-repo-verify -d 'Do not verify repo source'
complete -c repo -n '__fish_seen_subcommand_from init' -l config-name -d 'Always prompt for name/email'
complete -c repo -n '__fish_seen_subcommand_from init' -l outer-manifest -d 'Start at outermost manifest'
complete -c repo -n '__fish_seen_subcommand_from init' -l no-outer-manifest -d 'Do not operate on outer manifests'
complete -c repo -n '__fish_seen_subcommand_from init' -l this-manifest-only -d 'Only this (sub)manifest'
complete -c repo -n '__fish_seen_subcommand_from init' -l no-this-manifest-only -l all-manifests -d 'This manifest and its submanifests'

# --- list ---------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from list' -s r -l regex -d 'Filter by regex/wildcard'
complete -c repo -n '__fish_seen_subcommand_from list' -s g -l groups -d 'Filter by groups' -r
complete -c repo -n '__fish_seen_subcommand_from list' -s a -l all -d 'Show regardless of checkout state'
complete -c repo -n '__fish_seen_subcommand_from list' -s n -l name-only -d 'Only show repo name'
complete -c repo -n '__fish_seen_subcommand_from list' -s p -l path-only -d 'Only show repo path'
complete -c repo -n '__fish_seen_subcommand_from list' -s f -l fullpath -d 'Show full work-tree path'
complete -c repo -n '__fish_seen_subcommand_from list' -l relative-to -d 'Paths relative to PATH' -r
complete -c repo -n '__fish_seen_subcommand_from list' -f -a '(__fish_repo_projects)' -d 'project'

# --- manifest -----------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from manifest' -s r -l revision-as-HEAD -d 'Save revisions as current HEAD'
complete -c repo -n '__fish_seen_subcommand_from manifest' -s m -l manifest-name -d 'Temporary manifest to use' -r -a '(__fish_repo_manifest_files)'
complete -c repo -n '__fish_seen_subcommand_from manifest' -l suppress-upstream-revision -d "In -r mode, omit upstream field"
complete -c repo -n '__fish_seen_subcommand_from manifest' -l suppress-dest-branch -d "In -r mode, omit dest-branch field"
complete -c repo -n '__fish_seen_subcommand_from manifest' -l json -d 'Output as JSON'
complete -c repo -n '__fish_seen_subcommand_from manifest' -l format -d 'Output format' -r
complete -c repo -n '__fish_seen_subcommand_from manifest' -l pretty -d 'Human-readable output'
complete -c repo -n '__fish_seen_subcommand_from manifest' -l no-local-manifests -d 'Ignore local manifests'
complete -c repo -n '__fish_seen_subcommand_from manifest' -s o -l output-file -d 'Save manifest to -|NAME.xml' -r

# --- overview -----------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from overview' -s c -l current-branch -d 'Only checked-out branches'
complete -c repo -n '__fish_seen_subcommand_from overview' -l no-current-branch -d 'Consider all local branches'
complete -c repo -n '__fish_seen_subcommand_from overview' -f -a '(__fish_repo_projects)' -d 'project'

# --- prune --------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from prune' -f -a '(__fish_repo_projects)' -d 'project'

# --- rebase -------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from rebase' -s i -l interactive -d 'Interactive rebase (single project)'
complete -c repo -n '__fish_seen_subcommand_from rebase' -l fail-fast -d 'Stop after first error'
complete -c repo -n '__fish_seen_subcommand_from rebase' -s f -l force-rebase -d 'Pass --force-rebase'
complete -c repo -n '__fish_seen_subcommand_from rebase' -l no-ff -d 'Pass --no-ff'
complete -c repo -n '__fish_seen_subcommand_from rebase' -l autosquash -d 'Pass --autosquash'
complete -c repo -n '__fish_seen_subcommand_from rebase' -l whitespace -d 'Pass --whitespace to git' -r
complete -c repo -n '__fish_seen_subcommand_from rebase' -l auto-stash -d 'Stash before rebasing'
complete -c repo -n '__fish_seen_subcommand_from rebase' -s m -l onto-manifest -d 'Rebase onto manifest version'
complete -c repo -n '__fish_seen_subcommand_from rebase' -f -a '(__fish_repo_projects)' -d 'project'

# --- selfupdate ---------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from selfupdate' -l no-repo-verify -d 'Do not verify repo source'

# --- smartsync ----------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from smartsync' -f -a '(__fish_repo_projects)' -d 'project'

# --- stage --------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from stage' -s i -l interactive -d 'Interactive staging'
complete -c repo -n '__fish_seen_subcommand_from stage' -f -a '(__fish_repo_projects)' -d 'project'

# --- start --------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from start' -l all -d 'Begin branch in all projects'
complete -c repo -n '__fish_seen_subcommand_from start' -s r -l rev -l revision -d 'Point branch at this revision' -r
complete -c repo -n '__fish_seen_subcommand_from start' -l head -l HEAD -d 'Abbreviation for --rev HEAD'
complete -c repo -n '__fish_seen_subcommand_from start; and __fish_repo_not_first_arg' -f -a '(__fish_repo_projects)' -d 'project'

# --- status -------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from status' -s o -l orphans -d 'Include objects outside repo projects'
complete -c repo -n '__fish_seen_subcommand_from status' -f -a '(__fish_repo_projects)' -d 'project'

# --- sync ---------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from sync' -l jobs-network -d 'Parallel network jobs' -r
complete -c repo -n '__fish_seen_subcommand_from sync' -l jobs-checkout -d 'Parallel checkout jobs' -r
complete -c repo -n '__fish_seen_subcommand_from sync' -s f -l force-broken -l fail-fast -d 'Stop after first error'
complete -c repo -n '__fish_seen_subcommand_from sync' -l force-sync -d 'Overwrite existing git dir if needed'
complete -c repo -n '__fish_seen_subcommand_from sync' -l force-checkout -d 'Force checkout (discard local changes)'
complete -c repo -n '__fish_seen_subcommand_from sync' -l force-remove-dirty -d 'Remove projects with uncommitted changes'
complete -c repo -n '__fish_seen_subcommand_from sync' -l rebase -d 'Rebase local commits onto upstream'
complete -c repo -n '__fish_seen_subcommand_from sync' -s l -l local-only -d 'Update working tree, no fetch'
complete -c repo -n '__fish_seen_subcommand_from sync' -l no-manifest-update -l nmu -d 'Use existing manifest as-is'
complete -c repo -n '__fish_seen_subcommand_from sync' -l interleaved -l no-interleaved -d 'Toggle interleaved fetch/checkout'
complete -c repo -n '__fish_seen_subcommand_from sync' -s n -l network-only -d 'Fetch only, no working-tree update'
complete -c repo -n '__fish_seen_subcommand_from sync' -s d -l detach -d 'Detach to manifest revision'
complete -c repo -n '__fish_seen_subcommand_from sync' -s c -l current-branch -l no-current-branch -d 'Toggle current-branch fetch'
complete -c repo -n '__fish_seen_subcommand_from sync' -s m -l manifest-name -d 'Temporary manifest to use' -r -a '(__fish_repo_manifest_files)'
complete -c repo -n '__fish_seen_subcommand_from sync' -l clone-bundle -l no-clone-bundle -d 'Toggle /clone.bundle'
complete -c repo -n '__fish_seen_subcommand_from sync' -s u -l manifest-server-username -d 'Manifest server username' -r
complete -c repo -n '__fish_seen_subcommand_from sync' -s p -l manifest-server-password -d 'Manifest server password' -r
complete -c repo -n '__fish_seen_subcommand_from sync' -l fetch-submodules -d 'Fetch submodules'
complete -c repo -n '__fish_seen_subcommand_from sync' -l use-superproject -l no-use-superproject -d 'Toggle manifest superproject'
complete -c repo -n '__fish_seen_subcommand_from sync' -l superproject-revision -d 'Sync to superproject revision' -r
complete -c repo -n '__fish_seen_subcommand_from sync' -l tags -l no-tags -d 'Toggle tag fetching'
complete -c repo -n '__fish_seen_subcommand_from sync' -l optimized-fetch -d 'Fetch only sha1-fixed projects if missing'
complete -c repo -n '__fish_seen_subcommand_from sync' -l retry-fetches -d 'Retries on transient errors' -r
complete -c repo -n '__fish_seen_subcommand_from sync' -l prune -l no-prune -d 'Toggle deleting stale refs'
complete -c repo -n '__fish_seen_subcommand_from sync' -l auto-gc -l no-auto-gc -d 'Toggle garbage collection'
complete -c repo -n '__fish_seen_subcommand_from sync' -s s -l smart-sync -d 'Smart sync from latest known good build'
complete -c repo -n '__fish_seen_subcommand_from sync' -s t -l smart-tag -d 'Smart sync from a known tag' -r
complete -c repo -n '__fish_seen_subcommand_from sync' -l no-repo-verify -d 'Do not verify repo source'
complete -c repo -n '__fish_seen_subcommand_from sync' -f -a '(__fish_repo_projects)' -d 'project'

# --- upload -------------------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from upload' -s t -l topic-branch -l topic -d 'Set topic for the change' -x -a '(__fish_repo_branches)'
complete -c repo -n '__fish_seen_subcommand_from upload' -l hashtag -l ht -d 'Add hashtags (comma delimited)' -r
complete -c repo -n '__fish_seen_subcommand_from upload' -l hashtag-branch -l htb -d 'Add local branch name as a hashtag'
complete -c repo -n '__fish_seen_subcommand_from upload' -s l -l label -d 'Add a label when uploading' -r
complete -c repo -n '__fish_seen_subcommand_from upload' -s p -l pd -l patchset-description -d 'Description for patchset' -r
complete -c repo -n '__fish_seen_subcommand_from upload' -l re -l reviewers -d 'Request reviews from these people' -r
complete -c repo -n '__fish_seen_subcommand_from upload' -l cc -d 'Also email these addresses' -r
complete -c repo -n '__fish_seen_subcommand_from upload' -l br -l branch -d 'Local branch to upload' -x -a '(__fish_repo_branches)'
complete -c repo -n '__fish_seen_subcommand_from upload' -s c -l current-branch -l no-current-branch -d 'Toggle current-branch upload'
complete -c repo -n '__fish_seen_subcommand_from upload' -l cbr -d 'Upload current git branch'
complete -c repo -n '__fish_seen_subcommand_from upload' -l ne -l no-emails -d 'No emails on upload'
complete -c repo -n '__fish_seen_subcommand_from upload' -l private -d 'Upload as private change (deprecated; use --wip)'
complete -c repo -n '__fish_seen_subcommand_from upload' -s w -l wip -d 'Upload as work-in-progress'
complete -c repo -n '__fish_seen_subcommand_from upload' -s r -l ready -d 'Mark change as ready'
complete -c repo -n '__fish_seen_subcommand_from upload' -s o -l push-option -d 'Additional push options' -r
complete -c repo -n '__fish_seen_subcommand_from upload' -s D -l destination -l dest -d 'Target branch for review' -r
complete -c repo -n '__fish_seen_subcommand_from upload' -s n -l dry-run -d 'Do everything except upload'
complete -c repo -n '__fish_seen_subcommand_from upload' -s y -l yes -d 'Answer yes to all safe prompts'
complete -c repo -n '__fish_seen_subcommand_from upload' -l ignore-untracked-files -l no-ignore-untracked-files -d 'Toggle untracked-file prompt'
complete -c repo -n '__fish_seen_subcommand_from upload' -l no-cert-checks -d 'Disable SSL cert verification (unsafe)'
complete -c repo -n '__fish_seen_subcommand_from upload' -f -a '(__fish_repo_projects)' -d 'project'

# --- version / wipe -----------------------------------------------------
complete -c repo -n '__fish_seen_subcommand_from wipe' -s f -l force -d 'Force wipe shared projects'
complete -c repo -n '__fish_seen_subcommand_from wipe' -l force-uncommitted -d 'Force wipe with uncommitted changes'
complete -c repo -n '__fish_seen_subcommand_from wipe' -l force-shared -d 'Force wipe if project shares object dir'
complete -c repo -n '__fish_seen_subcommand_from wipe' -f -a '(__fish_repo_projects)' -d 'project'
