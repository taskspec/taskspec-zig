# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-12-28

### Added
- Initial implementation of Taskspec parser for Zig 0.15.2
- Support for all standard Taskspec keywords (TODO, FIXME, BUG, HACK, NOTE, INFO, IDEA, REFACTOR, REMINDER)
- Support for both text and emoji metadata formats
- Markdown task list format parsing (`- [ ]` and `- [x]`)
- Parse ISO 8601 dates (due, scheduled, start, created, completed)
- Priority levels (highest, high, medium, low, lowest)
- Status values (todo, in-progress, done, cancelled, blocked)
- Assignee parsing (@username or 👤username)
- Tags and projects (#tag and +project)
- Recurrence patterns
- Task IDs
- Estimate field
- Escape character handling for special characters in descriptions
- Comprehensive unit tests
- Example program demonstrating library usage
- CI workflow for automated testing

[0.1.0]: https://github.com/taskspec/taskspec-zig/releases/tag/v0.1.0
