# Git Workflow & Branching Strategy

## Overview

This document outlines the Git workflow and branching strategy for the Federated Genomic Imputation Platform.

---

## Branch Structure

### Main Branches

#### `main` (Production)

- **Purpose**: Production-ready code
- **Protection**: Should be protected from direct commits
- **Deployment**: Automatically deployed or manually deployed to production
- **Merge Policy**: Only via Pull Requests with code review
- **Testing**: All tests must pass before merge

#### `develop` (Integration)

- **Purpose**: Integration branch for next release
- **Status**: Currently not used - we use feature branches directly
- **Future**: May be added for release staging

---

## Development Branches

### Feature Branches

**Naming Convention**: `dev/<feature-name>` or `feature/<feature-name>`

**Examples**:

- `dev/services-enhancement`
- `dev/job-queue-optimization`
- `feature/real-time-notifications`
- `feature/advanced-analytics`

**Workflow**:

```bash
# Create feature branch from main
git checkout main
git pull origin main
git checkout -b dev/services-enhancement

# Work on feature
git add .
git commit -m "Add service health monitoring"

# Push to remote
git push -u origin dev/services-enhancement

# Create Pull Request when ready
```

### Bug Fix Branches

**Naming Convention**: `fix/<bug-description>` or `bugfix/<issue-number>`

**Examples**:

- `fix/dashboard-loading-error`
- `fix/cors-configuration`
- `bugfix/issue-123`

**Workflow**:

```bash
# Create fix branch from main
git checkout main
git checkout -b fix/dashboard-loading-error

# Fix the bug
git add .
git commit -m "Fix dashboard API connection error"

# Push and create PR
git push -u origin fix/dashboard-loading-error
```

### Hotfix Branches

**Naming Convention**: `hotfix/<critical-fix>`

**Purpose**: Emergency fixes for production issues

**Workflow**:

```bash
# Create from main
git checkout main
git checkout -b hotfix/security-patch

# Apply fix
git add .
git commit -m "Apply critical security patch"

# Merge to main AND develop (if exists)
git checkout main
git merge hotfix/security-patch
git tag -a v1.5.1-hotfix -m "Security hotfix"
```

### Release Branches

**Naming Convention**: `release/<version>`

**Examples**:

- `release/v1.6.0`
- `release/v2.0.0-beta`

**Purpose**: Prepare for production release

**Workflow**:

```bash
# Create release branch
git checkout main
git checkout -b release/v1.6.0

# Version bump, changelog, final testing
git add .
git commit -m "Prepare v1.6.0 release"

# Merge to main
git checkout main
git merge release/v1.6.0
git tag -a v1.6.0 -m "Release v1.6.0"

# Push tags
git push origin main --tags
```

---

## Current Branch: `dev/services-enhancement`

### Purpose

Development branch for improving and enhancing the services functionality:

- Service health monitoring improvements
- Service discovery optimization
- Service registration enhancements
- Performance improvements
- New service features

### Created From

- **Base**: `main` branch
- **Commit**: `732fd56` (Add release notes for v1.5.0)
- **Date**: October 2, 2025

### Workflow

1. **Development**:

   ```bash
   # You are here
   git checkout dev/services-enhancement

   # Make changes
   git add .
   git commit -m "Improve service health checks"
   ```

2. **Regular Syncing with Main**:

   ```bash
   # Keep branch updated with main
   git checkout main
   git pull origin main
   git checkout dev/services-enhancement
   git merge main
   ```

3. **Push to Remote**:

   ```bash
   # First time
   git push -u origin dev/services-enhancement

   # Subsequent pushes
   git push
   ```

4. **Create Pull Request**:
   - When feature is complete and tested
   - Create PR on GitHub/GitLab
   - Request code review
   - Ensure all tests pass
   - Merge to main after approval

---

## Commit Message Convention

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, no logic change)
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Build process, dependencies, etc.
- **ci**: CI/CD changes

### Examples

**Feature**:

```
feat(services): Add automatic service health monitoring

Implemented background health checks that run every 30 seconds
for all registered services. Health status is cached and displayed
in the services dashboard.

Closes #123
```

**Bug Fix**:

```
fix(dashboard): Resolve API connection error

Added fallback logic for environment variables to handle Docker
deployment scenarios where REACT_APP_API_BASE_URL might not be set.

Fixes #456
```

**Documentation**:

```
docs(testing): Add comprehensive testing guide

Created 100+ test cases covering all pages, security testing,
performance benchmarks, and accessibility compliance.
```

---

## Tagging Strategy

### Semantic Versioning

Format: `vMAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]`

**Examples**:

- `v1.0.0` - Major release
- `v1.5.0` - Minor release (new features)
- `v1.5.1` - Patch release (bug fixes)
- `v2.0.0-beta.1` - Pre-release
- `v1.5.0+20251002` - Build metadata

### Version Bumping Rules

**MAJOR** (v2.0.0):

- Breaking changes
- Major architectural changes
- API changes that break compatibility

**MINOR** (v1.5.0):

- New features (backward compatible)
- Significant enhancements
- New endpoints/functionality

**PATCH** (v1.5.1):

- Bug fixes
- Security patches
- Minor improvements

### Tag Types

**Release Tags**:

```bash
git tag -a v1.5.0 -m "Release v1.5.0: Dashboard fix and testing framework"
git push origin v1.5.0
```

**Component Tags**:

```bash
# Tag specific components or features
git tag -a testing-framework-v1.0 -m "Testing framework v1.0"
git tag -a microservices-v1.0 -m "Microservices architecture v1.0"
```

**Hotfix Tags**:

```bash
git tag -a v1.5.1-hotfix -m "Hotfix: Security patch"
```

---

## Pull Request Guidelines

### PR Title Format

```
[TYPE] Brief description
```

**Examples**:

- `[FEATURE] Add real-time service monitoring`
- `[FIX] Resolve CORS configuration issue`
- `[DOCS] Update API documentation`

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Changes Made
- List of changes
- Another change

## Testing
- [ ] Unit tests added/updated
- [ ] E2E tests added/updated
- [ ] Manual testing completed
- [ ] All tests passing

## Screenshots (if applicable)
[Add screenshots]

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings introduced
- [ ] Tests added/updated
- [ ] Backward compatibility maintained

## Related Issues
Closes #123
Relates to #456
```

---

## Code Review Process

### For Reviewers

**Checklist**:

- [ ] Code quality and style
- [ ] Test coverage adequate
- [ ] Documentation updated
- [ ] No security vulnerabilities
- [ ] Performance impact considered
- [ ] Breaking changes noted
- [ ] Backward compatibility maintained

**Review Types**:

- **Approve**: Ready to merge
- **Request Changes**: Issues found
- **Comment**: Questions or suggestions

### For Authors

**Before Requesting Review**:

1. Self-review all changes
2. Run all tests locally
3. Update documentation
4. Add/update tests
5. Resolve merge conflicts
6. Update PR description

**After Review**:

1. Address all comments
2. Make requested changes
3. Re-request review
4. Thank reviewers

---

## Merge Strategies

### Merge Commit (Recommended for features)

```bash
git checkout main
git merge --no-ff dev/services-enhancement
```

- Preserves branch history
- Creates merge commit
- Easy to revert if needed

### Squash and Merge (For small fixes)

```bash
git checkout main
git merge --squash fix/small-bug
git commit -m "Fix: Small bug description"
```

- Clean linear history
- Single commit for feature
- Lose individual commit history

### Rebase and Merge (For clean history)

```bash
git checkout dev/services-enhancement
git rebase main
git checkout main
git merge dev/services-enhancement
```

- Linear history
- No merge commits
- **Caution**: Don't rebase public branches

---

## Branch Lifecycle

### Creating a Branch

```bash
# Always start from latest main
git checkout main
git pull origin main
git checkout -b dev/my-feature
```

### Working on Branch

```bash
# Regular commits
git add .
git commit -m "feat: Add new feature"

# Push to remote
git push -u origin dev/my-feature
```

### Keeping Branch Updated

```bash
# Regularly sync with main
git checkout main
git pull origin main
git checkout dev/my-feature
git merge main

# Or rebase (if branch not shared)
git rebase main
```

### Completing Branch

```bash
# Create Pull Request
# After PR approved and merged
git checkout main
git pull origin main

# Delete local branch
git branch -d dev/my-feature

# Delete remote branch
git push origin --delete dev/my-feature
```

---

## Common Workflows

### Workflow 1: New Feature Development

```bash
# 1. Create feature branch
git checkout main
git pull origin main
git checkout -b dev/new-feature

# 2. Develop feature
# Make changes...
git add .
git commit -m "feat: Implement new feature"

# 3. Push to remote
git push -u origin dev/new-feature

# 4. Keep updated with main
git checkout main
git pull origin main
git checkout dev/new-feature
git merge main

# 5. Create Pull Request on GitHub/GitLab

# 6. After merge, cleanup
git checkout main
git pull origin main
git branch -d dev/new-feature
```

### Workflow 2: Bug Fix

```bash
# 1. Create fix branch
git checkout main
git checkout -b fix/bug-description

# 2. Fix the bug
# Make changes...
git add .
git commit -m "fix: Resolve bug description"

# 3. Push and create PR
git push -u origin fix/bug-description

# 4. After merge
git checkout main
git pull origin main
git branch -d fix/bug-description
```

### Workflow 3: Hotfix for Production

```bash
# 1. Create hotfix branch
git checkout main
git checkout -b hotfix/critical-fix

# 2. Apply fix
# Make changes...
git add .
git commit -m "hotfix: Apply critical fix"

# 3. Merge to main immediately
git checkout main
git merge hotfix/critical-fix
git tag -a v1.5.1-hotfix -m "Hotfix v1.5.1"
git push origin main --tags

# 4. Cleanup
git branch -d hotfix/critical-fix
```

---

## Useful Git Commands

### Branch Management

```bash
# List all branches
git branch -a

# Show current branch
git branch --show-current

# Switch branches
git checkout branch-name

# Create and switch
git checkout -b new-branch

# Delete branch (local)
git branch -d branch-name
git branch -D branch-name  # Force delete

# Delete branch (remote)
git push origin --delete branch-name

# Rename branch
git branch -m old-name new-name
```

### Syncing

```bash
# Fetch all changes
git fetch --all

# Pull latest from main
git checkout main
git pull origin main

# Update current branch from main
git merge main

# Rebase on main
git rebase main
```

### Stashing

```bash
# Save current changes
git stash

# List stashes
git stash list

# Apply latest stash
git stash pop

# Apply specific stash
git stash apply stash@{0}

# Clear stashes
git stash clear
```

### History

```bash
# View commit history
git log --oneline
git log --graph --oneline --all

# View changes
git diff
git diff main..dev/services-enhancement

# View file history
git log --follow filename
```

### Undoing Changes

```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Undo changes to file
git checkout -- filename

# Revert commit (create new commit)
git revert commit-hash
```

---

## Best Practices

### Do's ✅

- Always branch from latest `main`
- Keep branches short-lived (< 1 week if possible)
- Commit often with descriptive messages
- Push to remote regularly
- Keep branch updated with `main`
- Delete branches after merge
- Use meaningful branch names
- Tag releases properly
- Review your own PR first

### Don'ts ❌

- Don't commit directly to `main`
- Don't rebase public/shared branches
- Don't force push to shared branches
- Don't commit sensitive data (keys, passwords)
- Don't create long-running branches
- Don't commit generated files (node_modules, etc.)
- Don't squash commits on shared branches
- Don't forget to pull before pushing

---

## Emergency Procedures

### Accidentally Committed to Main

```bash
# Move commits to new branch
git branch dev/emergency-branch
git reset --hard origin/main
git checkout dev/emergency-branch
```

### Need to Undo Last Commit

```bash
# Keep changes
git reset --soft HEAD~1

# Discard changes
git reset --hard HEAD~1
```

### Lost Commits After Reset

```bash
# Find commit hash
git reflog

# Restore commit
git checkout -b recovery-branch commit-hash
```

### Merge Conflicts

```bash
# During merge
git merge main
# Fix conflicts in files
git add .
git commit -m "Merge main and resolve conflicts"

# To abort merge
git merge --abort
```

---

## Current Project Status

### Active Branches

- **`main`**: Production branch (v1.5.0)
- **`dev/services-enhancement`**: Services improvement (active)

### Recent Tags

- `v1.5.0-dashboard-fix` - Latest release
- `testing-framework-v1.0` - Testing framework component

### Next Steps

1. Work on services enhancement in `dev/services-enhancement`
2. Regular commits with descriptive messages
3. Push to remote for backup
4. Create PR when ready
5. Merge to main after review

---

## References

- [Git Documentation](https://git-scm.com/doc)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)

---

**Last Updated**: October 2, 2025
**Version**: 1.0
**Current Branch**: `dev/services-enhancement`
