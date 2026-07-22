# repo-fish-completions

[Fish](https://fishshell.com/) shell completions for the Android [`repo`](https://gerrit.googlesource.com/git-repo/) multi-repository tool.

Completions are generated from the repo source tree and cover **every** subcommand, its options, and the dynamic values that each command accepts.

## What you get

* **Subcommand names** — `repo <Tab>` lists all commands (and the `branch` alias for `branches`).
* **Project names & paths** — any command that takes `[<project>...]` (`sync`, `upload`, `status`, `start`, `checkout`, …) completes both the project **name** (e.g. `platform/frameworks/base`) **and** its relative **path** (e.g. `frameworks/base`), since `repo` matches either.
* **Local topic branches** — `start`, `checkout`, `abandon`, `download -b` and `upload --branch/--topic` complete branch names gathered across all projects.
* **Manifest XML files** — `diffmanifests`, `manifest -m` and `sync -m` complete files from `.repo/manifests/`.
* **Per-subcommand options** — short and long flags with descriptions, extracted from each subcommand's `argparse` definition (including the shared `-j/--jobs`, `-v/--verbose`, `-q/--quiet` and multi-manifest flags).
* **`repo help <Tab>`** — completes the list of subcommands.

Positional context is respected: e.g. `repo checkout` offers **branches** for the first argument and **projects** for everything after it.

## Installation

Three pieces, all optional and independent:

```sh
# 1. Completions (the main feature).
mkdir -p ~/.config/fish/completions
cp completions/repo.fish ~/.config/fish/completions/

# 2. Cache invalidation — clears the cached project/branch lists automatically
#    after `repo start` / `abandon` / `sync` / `init` / `wipe` / `checkout` /
#    `download`, so Tab always reflects the current state. Lives in conf.d/
#    (sourced at startup) rather than completions/ because completion files load
#    lazily — too late to register an event handler.
mkdir -p ~/.config/fish/conf.d
cp conf.d/repo.fish ~/.config/fish/conf.d/

# 3. repo-stale-branches helper and its Fish completions (see below).
cp bin/repo-stale-branches ~/bin/
cp completions/repo-stale-branches.fish ~/.config/fish/completions/
```

Fish loads the completion + conf.d files on the next prompt — no restart needed.

## Performance notes

* Project and branch lists are **cached for the session** (`$__repo_project_cache` / `$__repo_branch_cache`) so `repo list` and `repo forall` are only run once.
* The caches are **invalidated automatically** after mutating commands via a `fish_postexec` handler (see `conf.d/repo.fish`). To refresh by hand, run `repo-clear-completions-cache` (alias `rcc`) — handy when a change happened outside the handler's view, e.g. via `repo forall -c 'git ...'` or from another terminal.
* All dynamic helpers silently return nothing when run outside a repo client checkout (or before `repo init`), so completions degrade gracefully.

## repo-stale-branches

A companion script that finds local topic branches already merged upstream, detected by **Gerrit Change-Id**.

`repo prune` can't do this: it compares commit SHAs, but Gerrit rewrites SHAs on submission, so a submitted branch never looks merged to `git branch -d`. Matching by Change-Id (which Gerrit preserves) is the only reliable signal.

```sh
repo-stale-branches                 # list stale branches (dry run)
repo-stale-branches --abandon       # delete inactive stale branches
repo-stale-branches --checkout-upstream-and-abandon
                                    # cleanly detach active stale branches,
                                    # then delete all stale branches
repo-stale-branches --since='2 years ago'   # widen the upstream history scan
```

A branch is reported stale when every commit it adds on top of upstream carries a Change-Id that also appears in the project's upstream history. Branches whose changes are still under review (or that have commits without a Change-Id) are left alone. An active stale branch is listed as not abandonable: `--abandon` skips it. Use the explicit `--checkout-upstream-and-abandon` mode only when its worktree is clean; it detaches the worktree at the manifest upstream before deleting the branch.

## Compatibility

Tested against Fish 4.x and repo launcher 2.54.

## License

Licensed under the [Unenshittifiable License (UEL) v1.0](https://uelicense.eu/) — see [LICENSE](LICENSE). Use it, fork it, learn from it, self-host it, improve it — just don't turn the commons into a toll booth.
