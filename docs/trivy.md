# Trivy

`trivy.yaml` is a GitHub Actions workflow that utilizes Trivy,
an open-source vulnerability scanner for Docker containers and images.
The action is triggered when a workflow is called with an image-ref input.
It performs the following:

* A scan of the specified Docker image with Trivy using the [trivy action](https://github.com/aquasecurity/trivy-action).
* Upload the Trivy scan results in SARIF format to GitHub Security tab
using the [upload-sarif](https://docs.github.com/en/code-security/code-scanning/integrating-with-code-scanning/uploading-a-sarif-file-to-github) action.

This configuration file enables easy integration of vulnerability scanning
for Docker images into a GitHub CI/CD pipeline. Results can be viewed in the
GitHub Security tab for further analysis and vulnerability remediation.
