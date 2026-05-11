# Contributing

Welcome! This project welcomes contributions of all kinds.

## Development Setup

### Prerequisites

- [Claude Code](https://claude.ai/code) installed and authenticated
- Git

### Local Installation

```bash
git clone https://github.com/opszn/claude-code-audit.git
cd claude-code-audit
/plugin install ./
```

This installs the skills from your local clone. Any edits you make will be immediately available on next Claude Code session.

## Project Structure

Each skill is a directory under `skills/` with at minimum a `SKILL.md` file:

```
skills/{skill-name}/
├── SKILL.md              # Required: skill definition + instructions
├── references/           # Optional: detailed checklists, templates
└── scripts/              # Optional: helper shell scripts
```

### SKILL.md Format

```yaml
---
name: skill-name
description: "When Claude should use this skill. Include both English and Chinese keywords."
version: 1.0.0
license: MIT
author: your-name
user-invocable: true
tags: [tag1, tag2]
compatibility: [claude-code]
---

# Skill Title

Brief description of what this skill does.

## Trigger Conditions

Keywords that auto-trigger this skill.

## Instructions

Step-by-step instructions for Claude to follow.
```

**Keep SKILL.md under 500 lines.** Move detailed content to `references/`.

## Pull Requests

### Before Submitting

1. Test your changes by installing locally: `/plugin install ./`
2. Run the skill against a real project to verify it works
3. Update `docs/changelog.md` with your changes

### PR Guidelines

- Small, focused changes are preferred over large PRs
- Include a brief description of what and why
- Screenshots or example output are helpful for UI-related changes
- All contributions must be MIT-compatible licensed

### Review Process

1. Open a PR with a description of your changes
2. Maintainers will review for: correctness, security, clarity
3. Feedback will be addressed before merge
4. Once approved, changes are merged into `main`

## Adding a New Skill

1. Create directory: `skills/{skill-name}/`
2. Create `SKILL.md` with YAML frontmatter + instructions
3. Add `references/` for detailed checklists/templates (if needed)
4. Add `scripts/` for helper shell scripts (if needed)
5. Update `.claude-plugin/marketplace.json` with plugin description
6. Update `README.md` with skill description
7. Update `docs/changelog.md` with version note

## Improving Existing Skills

- Fix incorrect patterns or false positives in audit/test logic
- Add multi-language support (e.g., new grep patterns for additional languages)
- Improve clarity of instructions
- Add new reference checklists
- Update documentation

## Release Process

Releases are tagged on `main` with semantic versioning:

- **v1.x.y** — minor improvements and bug fixes
- **v2.0.0** — breaking changes or major new features

Each release includes:
- Tagged git commit
- Updated `docs/changelog.md`
- Bumped `version` in SKILL.md frontmatter
