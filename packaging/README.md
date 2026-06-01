# Packaging Notes

This repository now builds release artifacts in GitHub Actions, but publishing
is intentionally left as maintainer-owned follow-up work.

Release flow:

1. Update `pyproject.toml` to the intended version.
2. Push a matching `vX.Y.Z` tag.
3. The `Package` workflow builds artifacts from that tag and creates the
   GitHub Release with versioned files, manifests, and checksums.

The package workflow builds these 15 artifact targets:

- Python wheel/sdist
- Docker image
- Git source archive
- AUR metadata/source package
- DEB: Debian 12, Debian 13, Ubuntu 24.04, Ubuntu 26.04
- RPM: Fedora 43, Fedora 44, CentOS Stream 10, openSUSE Tumbleweed
- APK-style tarballs: Alpine 3.20, Alpine 3.22, Alpine 3.23

Publishing placeholders:

- AUR publishing needs a maintainer-owned `AUR_SSH_PRIVATE_KEY` secret and a
  separately reviewed publish job.
- Snap publishing needs a maintainer-owned `SNAPCRAFT_STORE_CREDENTIALS`
  secret and a Snapcraft package definition.
- Flatpak publishing needs a Flathub submission/update workflow and maintainer
  credentials.
- Docker publishing uses `GITHUB_TOKEN` for GHCR and is gated to pushes/tags.

No third-party store credentials are required for pull requests.
The project website/GitHub Pages deployment is intentionally out of scope for
this packaging pipeline.
