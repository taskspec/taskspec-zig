# Contributing to taskspec-zig

Thank you for your interest in contributing to taskspec-zig!

## Development Setup

### Prerequisites

- Zig 0.15.2 or later
- Git

### Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/taskspec-zig.git
   cd taskspec-zig
   ```

3. Build the project:
   ```bash
   zig build
   ```

4. Run tests:
   ```bash
   zig build test
   ```

5. Run examples:
   ```bash
   zig build run-example
   zig build run-advanced
   ```

## Making Changes

1. Create a new branch for your feature or fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes, following the coding style of the existing code

3. Add tests for new functionality

4. Ensure all tests pass:
   ```bash
   zig build test
   ```

5. Update documentation as needed (README.md, inline comments, etc.)

6. Commit your changes with a descriptive commit message:
   ```bash
   git commit -m "Add feature: description of what you added"
   ```

7. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

8. Open a Pull Request

## Coding Guidelines

- Follow Zig's standard formatting (use `zig fmt`)
- Add doc comments for public APIs using `///`
- Write descriptive variable and function names
- Keep functions focused and relatively small
- Add tests for new features and bug fixes

## Testing

- All public APIs should have tests
- Tests should be comprehensive and cover edge cases
- Use descriptive test names that explain what is being tested

## Documentation

- Update the README.md if you add new features
- Add inline documentation for all public functions and types
- Update examples if they're affected by your changes
- Update CHANGELOG.md following [Keep a Changelog](https://keepachangelog.com/) format

## Specification Compliance

This library implements the [Taskspec specification](https://github.com/taskspec/spec). When adding features:

- Ensure they align with the specification
- If the spec is ambiguous, document your interpretation
- Consider backward compatibility

## Questions?

Feel free to open an issue if you have questions or need clarification!
