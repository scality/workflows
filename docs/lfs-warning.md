# Git LFS warning

The `lfs-warning.yaml` workflow will check if the files committed
in a pull request are properly tracked by Git LFS when needed.

## Usage

This workflow can be called as a job in any workflow that needs,
for example:

```yaml
# my-workflow.yaml
on: pull_request

jobs:
  lfs-warning:
    uses: scality/workflows/.github/workflows/lfs-warning.yaml@v1
```

## Inputs

Additional inputs to modify the default behavior of the workflow.

| Name            | Description                                | Default |
| --------------- | ------------------------------------------ | ------- |
| `filesizelimit` | Maximum file size before warning           | `1MB`   |
| `labelname`     | Label name to use when a warning is issued | `bug`   |

```yaml
# my-workflow.yaml

on: pull_request

jobs:
  lfs-warning:
    uses: scality/workflows/.github/workflows/lfs-warning.yaml@v1
    with:
      filesizelimit: 10MB
      labelname: 'my-label'
```
