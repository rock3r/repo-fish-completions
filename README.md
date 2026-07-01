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

Copy `completions/repo.fish` into your fish completions directory:

```sh
mkdir -p ~/.config/fish/completions
cp completions/repo.fish ~/.config/fish/completions/
```

Fish loads it automatically on the next prompt — no restart needed.

## Performance notes

* Project and branch lists are **cached for the session** (`$__repo_project_cache` / `$__repo_branch_cache`) so `repo list` and `repo forall` are only run once. To refresh, start a new shell or `set -e __repo_project_cache __repo_branch_cache`.
* All dynamic helpers silently return nothing when run outside a repo client checkout (or before `repo init`), so completions degrade gracefully.

## Compatibility

Tested against Fish 4.x and repo launcher 2.54.

## License

Licensed under the [Unenshittifiable License (UEL) v1.0](https://uelicense.eu/) — see [LICENSE](LICENSE). Use it, fork it, learn from it, self-host it, improve it — just don't turn the commons into a toll booth.
