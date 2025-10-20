# Contributing to Save The Elephant

Thank you for considering contributing to Save The Elephant! This document provides guidelines for contributing to this Helm chart.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/save-the-elephant.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`

## Development Setup

### Prerequisites

- Docker or Podman
- Minikube
- kubectl
- Helm 3.0+
- Make

### Local Development

```bash
# Start minikube and deploy
make full-deploy

# Make changes to the chart...

# Test your changes
make lint
make deploy

# Check status
make status
make logs
```

## Testing

Before submitting a pull request, ensure:

1. **Helm lint passes**:
   ```bash
   make lint
   ```

2. **Chart deploys successfully**:
   ```bash
   make clean
   make deploy
   ```

3. **Replication works** (if making replication changes):
   ```bash
   make deploy-replication
   make check-replication
   ```

4. **Documentation is updated** if you've changed configuration options

## Making Changes

### Chart Changes

- Update templates in `save-the-elephant/templates/`
- Update default values in `save-the-elephant/values.yaml`
- Update `Chart.yaml` version if making changes:
  - Patch version (0.1.X) for bug fixes
  - Minor version (0.X.0) for new features
  - Major version (X.0.0) for breaking changes

### Documentation Changes

- Update `README.md` for significant changes
- Update `QUICKSTART.md` if changing installation steps
- Update example files in `examples/` directory

## Commit Guidelines

- Use clear, descriptive commit messages
- Reference issue numbers when applicable
- Keep commits focused on a single change

Example:
```
Add support for custom PostgreSQL parameters

- Allow users to pass custom postgresql.conf parameters
- Update values.yaml with new configuration section
- Add documentation for custom parameters

Fixes #123
```

## Pull Request Process

1. Update documentation for any changed functionality
2. Add or update examples if needed
3. Ensure all tests pass (`make lint`, `make deploy`)
4. Update CHANGELOG.md (if present) with your changes
5. Submit pull request with clear description of changes

### PR Title Format

- `feat: Add new feature`
- `fix: Fix bug description`
- `docs: Update documentation`
- `chore: Update dependencies`
- `test: Add tests`

## Code Review

All submissions require review. We'll review your PR and may request changes before merging.

## Questions?

Feel free to open an issue for:
- Bug reports
- Feature requests
- Questions about usage
- Documentation improvements

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

## Thank You!

Your contributions make this project better for everyone!
