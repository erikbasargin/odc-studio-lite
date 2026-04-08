#!/bin/sh
set -eu

# Mise installation taken from https://mise.jdx.dev/continuous-integration.html#xcode-cloud
curl https://mise.run | sh # Install Mise
export PATH="$HOME/.local/bin:$PATH"

cd "$CI_WORKSPACE_PATH"

mise install
eval "$(mise activate bash --shims)"

tuist install

if [ -n "${CI_ARCHIVE_PATH:-}" ]; then
    echo "Archive action detected, generating without cache profile"
    tuist generate --cache-profile none --no-open
else
    tuist generate --no-open
fi

tuist setup cache
tuist inspect dependencies --only implicit
