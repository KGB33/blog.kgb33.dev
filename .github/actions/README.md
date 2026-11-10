# Local Dagger actions

These actions support one Dagger engine per job on an Ubuntu runner with Docker,
GNU tar, and passwordless sudo. Check out the repository before using them.

```yaml
steps:
  - uses: actions/checkout@v6
  - uses: ./.github/actions/setup-dagger
    id: dagger
    with:
      version: "0.21.11"
  - name: Run Dagger pipeline
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      DAGGER_CLOUD_TOKEN: ${{ secrets.DAGGER_CLOUD_TOKEN }}
      _EXPERIMENTAL_DAGGER_RUNNER_HOST: ${{ steps.dagger.outputs.runner-host }}
    run: dagger call publish --token env://GITHUB_TOKEN
  - uses: ./.github/actions/snapshot-dagger
```

## Setup

`setup-dagger` requires `version` without a `v` prefix. It installs that CLI
version and returns `runner-host` for the pipeline's environment.

- The engine image is cached by runner OS, architecture, and Dagger version.
  A hit loads it into Docker; a miss pulls and archives it.
- Engine state is restored from the latest cache for that Dagger version.
  Each successful run saves a new snapshot using its run ID and attempt.
- Cache keys remain compatible with the previous inline workflow.

The engine container is `dagger-engine-ci`, its volume is `dagger-state`, and
archives live at `/tmp/dagger-engine.tar` and `/tmp/dagger-state.tar`.

## Snapshot

Call `snapshot-dagger` after a successful pipeline in the same job. It stops the
engine and archives the volume, preserving ownership, permissions, extended
attributes, ACLs, and sparse files. The cache actions registered during setup
save both archives at the end of a successful job. Keep both actions together;
setup alone does not capture updated engine state.

Secrets stay in the calling workflow, not in the setup or snapshot actions.
