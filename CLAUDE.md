# CLAUDE.md

## Project overview

This is **scality/workflows**, a repository of reusable GitHub Actions workflows shared across the Scality organization. Downstream repos call these workflows via `workflow_call`.

## Repository structure

- `.github/workflows/` — Reusable workflow definitions (the core asset)
- `docs/` — MkDocs Material documentation for each workflow
- `tests/` — Dockerfiles used as fixtures to validate workflows on PR
- `mkdocs.yml` — Documentation site configuration
- `requirements.txt` — Python dependency for docs (`mkdocs-material`)

## Workflows

| File | Purpose |
|------|---------|
| `docker-build.yaml` | Build and push Docker images with Buildx, caching, multi-platform support |
| `trivy.yaml` | Container vulnerability scanning, uploads SARIF to GitHub Security tab |
| `lfs-warning.yaml` | Validates file sizes in PRs, warns about files not tracked by Git LFS |
| `claude-code-review.yml` | AI-powered PR review via Vertex AI |

## Conventions

- Workflow files use `.yaml` extension (except `claude-code-review.yml`)
- All workflows use `workflow_call` trigger with typed `inputs` and `secrets`
- Secrets have sensible defaults where possible (e.g., `GITHUB_TOKEN` for registry auth)
- Actions are pinned to major version tags (e.g., `@v6`, `@v3`)
- `tests.yaml` calls all workflows locally (`./.github/workflows/...`) to validate on PR

## Testing

There is no test framework. Workflows are tested by `tests.yaml` which calls each reusable workflow with test fixtures from `tests/docker/`.

## Documentation

Documentation is built with MkDocs Material (`mkdocs build --strict`). When adding or modifying a workflow, update the corresponding page in `docs/`.

## Downstream impact

Changes to workflow `inputs`, `secrets`, or `outputs` can break consuming repos. Treat these as public API surfaces — avoid removing or renaming parameters without a migration path.
