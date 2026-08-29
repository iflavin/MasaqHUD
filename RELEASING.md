# Releasing MasaqHUD

Pushing a version tag triggers `.github/workflows/release.yml`, which verifies
the release and publishes it. Pushing the tag is the only manual trigger;
everything after it is automated.

## Pre-release Checklist

1. Update the version in `Sources/MasaqHUD/Version.swift`
2. Update the `## Current Release:` heading and the sentence below it in `ROADMAP.md`
3. Open a pull request with the bump and merge it once CI passes:
   ```sh
   git checkout -b release/vX.Y.Z
   git add Sources/MasaqHUD/Version.swift ROADMAP.md
   git commit -m "Bump version to X.Y.Z"
   ```

The tag and both version declarations must agree. The release workflow checks
this and refuses to publish if they do not.

## Create Release

Tag the merged bump commit on `main`:

```sh
git checkout main && git pull
git tag vX.Y.Z
git push origin vX.Y.Z
```

The workflow then:

1. Verifies the tag matches `Version.swift` and `ROADMAP.md`
2. Builds and tests on every supported toolchain (macos-14, macos-15, macos-26)
3. Creates the GitHub release, with notes generated from the merged pull requests
4. Prints the tarball `url` and `sha256` for the Homebrew formula in the run summary

Nothing is published unless all of it passes. Only tags of the form `vX.Y.Z`
trigger a release.

If the workflow fails, delete the tag, fix the problem, and re-tag:

```sh
git tag -d vX.Y.Z
git push origin :refs/tags/vX.Y.Z
```

## Update Homebrew Formula

The tap is a separate repository and is **not** updated automatically.

Take the `url` and `sha256` from the release run's summary and update
`iflavin/homebrew-masaqhud` via a pull request. Check that its `depends_on
macos:` still matches the minimum in `Package.swift`.

To compute the checksum manually:

```sh
curl -sL https://github.com/iflavin/MasaqHUD/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
```
