## To do a release:

1. Bump the version in `AHConstants.m` and in the relevant test case.
2. Bump the version in `package.json`.
3. Bump the version in `AppHub.podspec`.
4. Run `scripts/release.sh`.

## To publish docs:

1. Run `scripts/generate-docs.sh`.
2. Upload the generated docs to the site repository.
