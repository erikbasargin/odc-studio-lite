#!/bin/sh
set -eu

cd "$CI_PRIMARY_REPOSITORY_PATH"

if [ "${CI_BRANCH:-}" != "main" ]; then
    echo "Not on main branch, skipping post-xcodebuild steps"
    exit 0
fi

if [ "${CI_XCODEBUILD_EXIT_CODE:-1}" != "0" ]; then
    echo "Build failed, skipping post-xcodebuild steps"
    exit 0
fi

"$HOME/.local/bin/mise" exec -- tuist cache
