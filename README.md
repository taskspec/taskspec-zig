# taskspec-zig

A Zig library for parsing [Taskspec](https://github.com/taskspec/spec) annotations - a universal TODO annotation format.

## Features

- ✅ Parse TODO, FIXME, and other standard keywords
- ✅ Support for both text and emoji metadata formats
- ✅ Markdown task list format (`- [ ]` and `- [x]`)
- ✅ Parse dates (ISO 8601), priorities, status, assignees, tags, and more
- ✅ Escape character handling
- ✅ Comprehensive test coverage

## Installation

Add this to your `build.zig.zon`:

```zig
.dependencies = .{
    .taskspec = .{
        .url = "https://github.com/taskspec/taskspec-zig/archive/<commit-hash>.tar.gz",
        .hash = "<hash>",
    },
},
```

Then in your `build.zig`:

```zig
const taskspec = b.dependency("taskspec", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("taskspec", taskspec.module("taskspec"));
```

## Usage

```zig
const std = @import("std");
const taskspec = @import("taskspec");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const parser = taskspec.Parser.init(allocator);
    
    const line = "TODO: Fix bug due:2026-02-15 p:high @alice";
    
    if (try parser.parseLine(line)) |*task| {
        defer task.deinit();
        
        std.debug.print("Description: {s}\n", .{task.description});
        std.debug.print("Due: {s}\n", .{task.due_date.?});
        std.debug.print("Priority: {s}\n", .{@tagName(task.priority.?)});
        std.debug.print("Assignee: {s}\n", .{task.assignee.?});
    }
}
```

## Building

Requires Zig 0.15.2 or later.

```bash
# Build the library
zig build

# Run tests
zig build test

# Build and run example
zig build example
zig build run-example
```

## Supported Formats

### Standard Keywords
- TODO, FIXME, BUG, HACK, NOTE, INFO, IDEA, REFACTOR, REMINDER

### Metadata Fields

Both text and emoji formats are supported:

| Field | Text | Emoji | Example |
|-------|------|-------|---------|
| Due Date | `due:` | 📅 | `due:2026-02-15` |
| Scheduled | `scheduled:` | ⏳ | `scheduled:2026-02-01` |
| Start Date | `start:` | 🛫 | `start:2026-01-15` |
| Priority | `priority:`/`p:` | 🔺⏫🔼🔽⏬ | `p:high` |
| Recurrence | `repeat:`/`rec:` | 🔁 | `repeat:every week` |
| ID | `id:` | 🆔 | `id:TODO-1234` |
| Assignee | `@` | 👤 | `@martin` |
| Tags | `#` | - | `#backend` |
| Projects | `+` | - | `+ProjectX` |
| Status | `status:` | ✅🚧❌⬜🚫 | `status:in-progress` |
| Created | `created:` | ➕ | `created:2026-01-01` |
| Completed | `done:` | ✅ | `done:2026-01-20` |
| Estimate | `estimate:` | ⏱️ | `estimate:2h` |

### Priority Levels
- Highest (🔺): `highest`, `critical`, `1`
- High (⏫): `high`, `2`
- Medium (🔼): `medium`, `normal`, `3`
- Low (🔽): `low`, `4`
- Lowest (⏬): `lowest`, `5`

### Status Values
- `todo` (⬜): Not started
- `in-progress` (🚧): Currently being worked on
- `done` (✅): Completed
- `cancelled` (❌): Will not be done
- `blocked` (🚫): Waiting on something

## Examples

```
TODO: Fix authentication bug
FIXME: Update documentation due:2026-02-15
TODO: Implement feature p:high @alice #backend
- [ ] Write unit tests 📅 2026-03-01
- [x] Deploy to production
BUG: Memory leak 🔺 @martin
```

## Specification

This library implements version 0.1.0-draft of the [Taskspec specification](https://github.com/taskspec/spec).

## License

See LICENSE file.
