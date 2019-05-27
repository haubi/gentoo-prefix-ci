#! /usr/bin/env bash

set -ex

[[ -d /usr/include ]] || sudo xcode-select --install
sudo xcode-select -s /Library/Developer/CommandLineTools

"${BUILD_SOURCESDIRECTORY}"/prefix/staging-bootstrap.sh --sources="${BUILD_SOURCESDIRECTORY}" --staging="${BUILD_STAGINGDIRECTORY}"
