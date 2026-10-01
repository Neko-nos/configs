#!/usr/bin/env bash

set -euo pipefail

GOBIN="${HOME}/.local/bin" go install mvdan.cc/sh/v3/cmd/shfmt@latest
