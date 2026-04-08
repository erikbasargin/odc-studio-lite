#!/bin/sh
set -eu

cd ..

if [ "${CI_BRANCH:-}" != "develop" ]; then
    echo "Not on develop branch, skipping post-xcodebuild steps"
    exit 0
fi

if [ "${CI_XCODEBUILD_EXIT_CODE:-1}" != "0" ]; then
    echo "Build failed, skipping post-xcodebuild steps"
    exit 0
fi

"$HOME/.local/bin/mise" exec -- tuist cache
