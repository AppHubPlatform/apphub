#!/bin/bash

read -r -p "Did you remember to bump the version (1) in AHConstants.m (2) in the NPM file (3) in the PodSpec? [y/N] " response
case $response in
    [yY][eE][sS]|[yY])
      git tag $1
      git push --tags
      npm publish
      pod push trunk AppHub.podspec
        ;;
    *)

        ;;
esac
