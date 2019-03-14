#! /usr/bin/env bash

set -ex

sudo xcode-select -s /Library/Developer/CommandLineTools
ls -ld /usr/bin
sudo ln -s /usr/local/bin/wget /usr/bin/wget

"${BUILD_SOURCESDIRECTORY}"/prefix/staging-bootstrap.sh --sources="${BUILD_SOURCESDIRECTORY}" --staging="${BUILD_STAGINGDIRECTORY}"
