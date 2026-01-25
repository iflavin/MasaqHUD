# Releasing MasaqHUD

## Pre-release Checklist

1. Update version in `Sources/MasaqHUD/Version.swift`
2. Commit the version bump:
   ```sh
   git add Sources/MasaqHUD/Version.swift
   git commit -m "Bump version to X.Y.Z"
   ```

## Create Release

1. Tag the release:
   ```sh
   git tag vX.Y.Z
   git push origin main --tags
   ```

2. Create GitHub release (optional):
   - Go to https://github.com/iflavin/MasaqHUD/releases
   - Click "Draft a new release"
   - Select the tag and add release notes

## Update Homebrew Formula

1. Get the new tarball SHA:
   ```sh
   curl -sL https://github.com/iflavin/MasaqHUD/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
   ```

2. Update `homebrew-masaqhud` tap:
   - Update `url` to point to new tag
   - Update `sha256` with the new hash
