# changelog.sh

Generate a structured `CHANGELOG.md` from your project's git history.

## Setup

1. Place `changelog.sh` in your project root.
2. Make it executable: `chmod +x changelog.sh`
3. Run: `bash changelog.sh`

## Usage

```bash
bash changelog.sh            # Writes CHANGELOG.md
bash changelog.sh --stdout   # Prints to terminal (dry-run)
```

## How it works

- Scans commits since the **latest version tag** (or from the first commit if no tags exist)
- Auto-categorizes into: **Added**, **Fixed**, **Changed**, **Removed**
- Supports **Conventional Commits** (`feat:`, `fix:`, `refactor:`, etc.) and plain messages
- Produces a clean Markdown file ready for publishing

## Sample output

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## v1.2.0 (2026-05-21)

### Added
  - User authentication via OAuth2
  - Dark mode toggle in settings

### Fixed
  - Crash on empty search results
  - Memory leak in WebSocket handler

### Changed
  - Upgrade dependencies to latest versions
  - Refactor database access layer

### Removed
  - Deprecated v1 API endpoints
```
