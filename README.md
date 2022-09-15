# workflows

A place to share GitHub Actions reusable workflows.

## Docker build

`docker-build.yaml` is a workflow capable of building and pushing
docker images.

### Usage

By default the workflow will:

* cache the build context
* tag the image with the value of `${{ github.sha }}`
* use org/repo-name as namespace
* push the image to [ghcr.io](https://ghcr.io)
* require that the image `name` is specified

Resulting in making the image available on:
`ghcr.io/<org>/<repo-name>/<image-name>:<git sha>`

```yaml
# my-workflow.yaml
jobs:
  docker-build:
    uses: scality/workflows/.github/workflows/docker-build.yaml@v1
    with:
      name: my-image
```

To specify a private registry you can use the following inputs:

```yaml
# my-workflow.yaml
jobs:
  docker-build:
    uses: scality/workflows/.github/workflows/docker-build.yaml@v1
    with:
      name: my-image
      registry: my.registry.com
      namespace: my-namespace
  # secrets: inherit -> when the secret key matches the workflow
    secrets:
      REGISTRY_LOGIN: "${{ secrets.MY_REGISTRY_LOGIN }}"
      REGISTRY_PASSWORD: "${{ secrets.MY_REGISTRY_PASSWORD }}"
```

For more information about all inputs available checkout
the [workflow definition](./.github/workflows/docker-build.yaml).


## Known issues

### Using secrets or env properties as inputs is not supported

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