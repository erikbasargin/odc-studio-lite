#!/bin/sh
set -eu

cd "$CI_PRIMARY_REPOSITORY_PATH"

# Mise installation taken from https://mise.jdx.dev/installing-mise.html#installation-methods
# and https://mise.jdx.dev/continuous-integration.html#xcode-cloud
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

# Installing and activating tools
mise install
eval "$(mise activate bash --shims)"

# Resolving dependencies
tuist install

if [ -n "${CI_ARCHIVE_PATH:-}" ]; then
    echo "Archive action detected, generating without cache profile"
    tuist generate --cache-profile none --no-open
else
    tuist generate --no-open
    tuist setup cache
fi

tuist inspect dependencies --only implicit
