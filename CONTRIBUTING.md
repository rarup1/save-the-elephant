# Contributing to Save The Elephant

Thank you for your interest in contributing to the Save The Elephant Helm chart! This document provides guidelines for contributing to this project.

## Table of Contents

- [Getting Started](#getting-started)
- [Branch Naming Convention](#branch-naming-convention)
- [PR Submission Process](#pr-submission-process)
- [PR Review & Labeling](#pr-review--labeling)
- [Release Process](#release-process)
- [Development Workflow](#development-workflow)

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/save-the-elephant.git
   cd save-the-elephant
   ```
3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/rarup1/save-the-elephant.git
   ```
4. **Keep your fork synced**:
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

## Branch Naming Convention

All branches must use one of the following prefixes:

### Core Prefixes

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feature/` | New features or enhancements | `feature/add-ingress-support` |
| `bugfix/` | Bug fixes | `bugfix/fix-replication-timeout` |
| `hotfix/` | Urgent production fixes | `hotfix/security-patch` |
| `release/` | Release preparation branches | `release/v0.3.0` |

### Supporting Prefixes

| Prefix | Purpose | Example |
|--------|---------|---------|
| `docs/` | Documentation changes | `docs/update-backup-guide` |
| `chore/` | Maintenance tasks, dependency updates | `chore/update-dependencies` |
| `ci/` | CI/CD pipeline changes | `ci/add-lint-check` |
| `refactor/` | Code restructuring without feature changes | `refactor/simplify-hba-config` |
| `test/` | Test additions or modifications | `test/add-backup-tests` |
| `perf/` | Performance improvements | `perf/optimize-startup` |

### Branch Naming Examples

✅ **Good:**
- `feature/add-prometheus-metrics`
- `bugfix/fix-backup-schedule`
- `docs/improve-installation-guide`

❌ **Bad:**
- `my-changes`
- `fix-stuff`
- `update`

## PR Submission Process

### 1. Create Your Branch

```bash
# Start from updated main branch
git checkout main
git pull upstream main

# Create your feature branch with proper prefix
git checkout -b feature/add-ingress-support
```

### 2. Make Your Changes

- Follow existing code style and conventions
- Update documentation if needed
- Test your changes locally (use `make` commands if available)
- Commit with clear, descriptive messages

### 3. Submit Pull Request

When submitting a PR, include the following information:

#### PR Title Format
```
[TYPE] Brief description of changes
```

Examples:
- `[FEATURE] Add Ingress support`
- `[BUGFIX] Fix replication authentication issue`
- `[DOCS] Update README with new configuration options`

#### PR Description Template

```markdown
## Change Type
<!-- Check one -->
- [ ] Major (breaking changes)
- [ ] Minor (new features, backwards compatible)
- [ ] Patch (bug fixes, no new features)

## Description
<!-- Describe your changes in detail -->

## Motivation and Context
<!-- Why is this change required? What problem does it solve? -->

## Testing
<!-- Describe how you tested your changes -->
- [ ] Tested locally with minikube/kind
- [ ] Tested with replication enabled
- [ ] Updated documentation
- [ ] Added/updated tests (if applicable)

## Breaking Changes
<!-- List any breaking changes and migration steps -->
- None

## Related Issues
<!-- Link to related issues: Fixes #123, Closes #456 -->

## Checklist
- [ ] Chart version bumped (if chart changes)
- [ ] CHANGELOG.md updated (for release PRs)
- [ ] Documentation updated
- [ ] Branch name follows convention
```

### 4. Keep Your PR Updated

```bash
# Sync with upstream main
git fetch upstream
git rebase upstream/main

# Force push to your branch (only for your fork!)
git push -f origin feature/add-ingress-support
```

## PR Review & Labeling

**For Maintainers:** After a PR is submitted, add appropriate labels:

### Version Impact Labels

| Label | Usage | Example |
|-------|-------|---------|
| `major` | Breaking changes (v1.0.0 → v2.0.0) | Removing deprecated features |
| `minor` | New features, backwards compatible (v1.0.0 → v1.1.0) | Adding new configuration options |
| `patch` | Bug fixes, no new features (v1.0.0 → v1.0.1) | Fixing a broken feature |

### Release Target Labels

| Label | Usage |
|-------|-------|
| `release:next` | Include in next scheduled release |
| `release:v0.3.0` | Target specific release version |

### Type Labels

| Label | Usage |
|-------|-------|
| `bug` | Bug fixes |
| `feature` | New features |
| `enhancement` | Improvements to existing features |
| `documentation` | Documentation changes |
| `dependencies` | Dependency updates |

## Release Process

Releases are managed by maintainers following this process:

### 1. Continuous Integration to Main

PRs are merged to `main` continuously after review and approval:

```bash
feature/add-metrics → main ✓
bugfix/fix-tls → main ✓
docs/update-readme → main ✓
```

### 2. Create Release Branch

When ready to release, create a short-lived release branch:

```bash
# Start from latest main
git checkout main
git pull

# Create release branch with version number
git checkout -b release/v0.3.0
```

### 3. Release Preparation

Perform the following tasks in the release branch:

#### Update Chart Version
```yaml
# save-the-elephant/Chart.yaml
version: 0.3.0  # Bump from 0.2.0
```

#### Update CHANGELOG.md
```markdown
## [0.3.0] - 2024-01-15

### Chart Changes

#### Added
- New Ingress support with TLS configuration
- Custom ServiceMonitor for Prometheus metrics

#### Changed
- Improved backup schedule configuration
- Enhanced documentation

#### Fixed
- Replication authentication timeout issue

---

### General Repository Updates

#### CI/CD
- Added automated linting checks
```

#### Update Version References

Update any hardcoded version references in README.md or examples:
```bash
# Find version references
grep -r "0.2.0" README.md examples/
```

### 4. Create Release PR

```bash
# Commit release prep changes
git add save-the-elephant/Chart.yaml CHANGELOG.md README.md
git commit -m "Prepare release v0.3.0"

# Push release branch
git push origin release/v0.3.0
```

Create a PR from `release/v0.3.0` → `main` with title: `Release v0.3.0`

### 5. Merge and Tag

Once the release PR is approved:

```bash
# Merge to main (via GitHub)
# Then tag the merge commit locally

git checkout main
git pull

# Create annotated tag
git tag -a v0.3.0 -m "Release v0.3.0

## Chart Changes (v0.2.0 → v0.3.0)

### Added
- Feature descriptions

### Changed
- Change descriptions

### Fixed
- Bug fix descriptions

---

## General Repository Updates

### CI/CD
- Pipeline improvements
"

# Push tag to trigger release workflow
git push origin v0.3.0
```

### 6. Automated Publishing

The GitHub Actions workflow automatically:
1. Packages the Helm chart
2. Creates a GitHub Release
3. Updates the Helm chart repository index
4. Syncs README.md to GitHub Pages

## Development Workflow

### Local Development

```bash
# Install dependencies
make setup  # If Makefile is available

# Deploy locally for testing
make full-deploy

# Deploy with replication
make full-deploy-replication

# Clean up
make clean
```

### Testing Changes

Before submitting a PR, ensure:

1. **Chart installs successfully:**
   ```bash
   # Basic deployment (uses values from save-the-elephant/values.yaml)
   helm upgrade --install test_release ./save-the-elephant \
     --namespace default \
     --create-namespace \
     --atomic \
     --wait \
     --timeout 5m
   ```

2. **Chart upgrades work:**
   ```bash
   # Make your changes, then upgrade
   helm upgrade test_release ./save-the-elephant \
     --namespace default \
     --atomic \
     --wait \
     --timeout 5m
   ```

3. **Test with replication (if applicable):**
   ```bash
   # Deploy with replication enabled
   helm upgrade --install test_release ./save-the-elephant \
     -f examples/replication.values.yaml \
     --namespace default \
     --create-namespace \
     --atomic \
     --wait \
     --timeout 5m
   ```

4. **Documentation is updated:**
   - Update README.md if adding new features and values parameters
   - Update values.yaml comments
   - Add examples if needed

**Note:** Automated CI/CD testing and linting will be added soon. Currently, linting and validation will happen during the PR review process.

### Commit Message Guidelines

Use clear, descriptive commit messages:

**Format:**
```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `chore`: Maintenance tasks
- `refactor`: Code restructuring
- `test`: Adding/updating tests
- `ci`: CI/CD changes

**Examples:**

```
feat: add Ingress support with TLS configuration

Add configurable Ingress resource with optional TLS support.
Includes examples for both HTTP and HTTPS configurations.

Closes #123
```

```
fix: resolve replication authentication timeout

The replication init container was timing out when waiting for
the primary pod. Updated to use the primary service instead of
headless service for initial connectivity check.

Fixes #456
```

## Questions or Issues?

- **Questions:** Open a [GitHub Discussion](https://github.com/rarup1/save-the-elephant/discussions)
- **Bug Reports:** Open a [GitHub Issue](https://github.com/rarup1/save-the-elephant/issues)
- **Feature Requests:** Open a [GitHub Issue](https://github.com/rarup1/save-the-elephant/issues) with the `enhancement` label

## Code of Conduct

Be respectful and constructive in all interactions. We aim to foster an inclusive and welcoming community.

## License

By contributing to Save The Elephant, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing! 🐘
