#!/bin/sh
set -eu

if [ "${CI_XCODEBUILD_ACTION:-}" != "build-for-testing" ]; then
    echo "Not a build-for-testing action, skipping post-xcodebuild steps"
    exit 0
fi

if [ "${CI_XCODEBUILD_EXIT_CODE:-1}" != "0" ]; then
    echo "Build failed, skipping post-xcodebuild steps"
    exit 0
fi

if [ "${CI_BRANCH:-}" != "develop" ]; then
    echo "Not on develop branch, skipping post-xcodebuild steps"
    exit 0
fi

cd "$CI_PRIMARY_REPOSITORY_PATH"
"$HOME/.local/bin/mise" exec -- tuist cache
