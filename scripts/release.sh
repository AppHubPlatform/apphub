#!/bin/bash

if [ -z "$1" ]; then
    echo "usage: releash.sh [tag version]"
    exit 1
fi

read -r -p "Releasing version $1: Did you remember to bump the version (1) in AHConstants.m (2) in the NPM file (3) in the PodSpec? [y/N] " response
case $response in
    [yY][eE][sS]|[yY])
      git tag $1
      git push --tags
      npm publish
      pod trunk push AppHub.podspec --allow-warnings
        ;;
    *)

        ;;
esac
