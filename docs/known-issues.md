# Known issues

## Using secrets or env properties as inputs is not supported

When calling a reusable workflow, if you are using a property
that is not defined inside the `github` context, it won't be available.

This is because GitHub considers that you are at a job level where those
properties are not transmitted yet, they become available only when
a runner is involved, at the steps level.

Example:

```yaml
jobs:
  workflow-job:
    uses: scality/workflow/.github/workflows/my-workflow.yaml@v1
    with:
      foo: ${{ secrets.foo }} # Doesn't work
      key: ${{ env.VALUE }} # Doesn't work
      param: ${{ github.sha }} # Works
```

Workaround:

* All the secrets you want to use should be defined inside the reusable workflow
to be called with the `secrets` parameter
* Other parameters can be outputs from previous builds like:
  ```yaml
  jobs:
    previous-job:
      outputs:
        foo: bar
    workflow-job:
      needs:
      - previous-job
      uses: scality/workflow/.github/workflows/my-workflow.yaml@v1
      with:
        foo: ${{ needs.previous-job.outputs.foo }}
  ```