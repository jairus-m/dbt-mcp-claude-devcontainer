#!/bin/bash
set -e

# Verify the container builds
docker build -t dbt-cloud-cli-test -f src/dbt-cloud-cli/.devcontainer/Dockerfile .

# Test dbt-cloud-cli installation
docker run --rm dbt-cloud-cli-test dbt --version

# Test Python installation
docker run --rm dbt-cloud-cli-test python --version

# Test uv installation
docker run --rm dbt-cloud-cli-test uv --version

# Test pre-commit installation
docker run --rm dbt-cloud-cli-test pre-commit --version

# Test git installation
docker run --rm dbt-cloud-cli-test git --version

# Test xdg-utils installation
docker run --rm dbt-cloud-cli-test xdg-open --version

# Test Claude Code installation
docker run --rm dbt-cloud-cli-test claude --version

echo "All tests passed!" 