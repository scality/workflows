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
