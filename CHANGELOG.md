# Changelog

All notable changes to the Save The Elephant Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

---

## [0.2.1] - 2025-11-20

### Fixed
- Added `podLabels` support to backup CronJob template to match StatefulSet behavior

### Changed
- Minor documentation fix in CONTRIBUTING.md (Supporting → Supported)

---

## [0.2.0] - 2025-10-22

### Added
- Configurable pg_hba.conf authentication via `postgresql.hba.enabled` and `postgresql.hba.authMode`
- SCRAM-SHA-256 password authentication mode (default)
- Trust authentication mode for development environments
- HBA ConfigMap template (`configmap-hba.yaml`)
- Automatic README.md sync to GitHub Pages on release
- HBA configuration documentation in README.md

### Changed
- Updated `configmap-init.yaml` to prevent duplicate pg_hba entries
- Updated `statefulset.yaml` to mount HBA ConfigMap

### Security
- **BREAKING**: Network connections now require password authentication by default
- Unix socket connections remain trusted for pod-internal operations
- Set `postgresql.hba.authMode: "trust"` to restore previous behavior

---

## [0.1.0] - 2025-10-21

Initial release.

### Added
- PostgreSQL 17.4 StatefulSet deployment
- S3 backup capabilities with CronJob scheduler
- Streaming replication support with configurable replicas
- Service Account with image pull secrets
- Primary, read-only, and headless services
- Configurable PostgreSQL parameters (connections, buffers, WAL settings)
- Resource limits and persistent volume configuration
- Security contexts and secret management
- Example configurations for common scenarios
- Documentation (README.md, QUICKSTART.md, MAKEFILE_GUIDE.md)
- Makefile for local development
- GitHub Actions workflow for automated releases

---

[Unreleased]: https://github.com/rarup1/save-the-elephant/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/rarup1/save-the-elephant/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/rarup1/save-the-elephant/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/rarup1/save-the-elephant/releases/tag/v0.1.0
