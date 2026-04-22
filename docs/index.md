# Workflows

This repository is used to share GitHub Actions reusable workflows across the organization.

## Calling conventions

When calling any workflow from this repository, prefer `secrets: inherit` over listing
secrets explicitly:

```yaml
jobs:
  docker-build:
    uses: scality/workflows/.github/workflows/docker-build.yaml@v2
    with:
      name: my-image
    secrets: inherit
```

This way, if a reusable workflow starts requiring a new secret, consuming repos pick it
up automatically instead of silently breaking until each caller is patched. Only fall
back to explicit `secrets:` mapping when the caller's secret name does not match the
name expected by the reusable workflow.
