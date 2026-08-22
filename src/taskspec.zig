const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

/// Priority levels for tasks
pub const Priority = enum {
    highest,
    high,
    medium,
    low,
    lowest,

    /// Parse priority from text or numeric value
    pub fn fromString(s: []const u8) ?Priority {
        if (mem.eql(u8, s, "highest") or mem.eql(u8, s, "critical") or mem.eql(u8, s, "1")) {
            return .highest;
        } else if (mem.eql(u8, s, "high") or mem.eql(u8, s, "2")) {
            return .high;
        } else if (mem.eql(u8, s, "medium") or mem.eql(u8, s, "normal") or mem.eql(u8, s, "3")) {
            return .medium;
        } else if (mem.eql(u8, s, "low") or mem.eql(u8, s, "4")) {
            return .low;
        } else if (mem.eql(u8, s, "lowest") or mem.eql(u8, s, "5")) {
            return .lowest;
        }
        return null;
    }

    /// Parse priority from emoji
    pub fn fromEmoji(s: []const u8) ?Priority {
        if (mem.eql(u8, s, "🔺")) return .highest;
        if (mem.eql(u8, s, "⏫")) return .high;
        if (mem.eql(u8, s, "🔼")) return .medium;
        if (mem.eql(u8, s, "🔽")) return .low;
        if (mem.eql(u8, s, "⏬")) return .lowest;
        return null;
    }
};

/// Status of a task
pub const Status = enum {
    todo,
    in_progress,
    done,
    cancelled,
    blocked,

    pub fn fromString(s: []const u8) ?Status {
        if (mem.eql(u8, s, "todo")) return .todo;
        if (mem.eql(u8, s, "in-progress")) return .in_progress;
        if (mem.eql(u8, s, "done")) return .done;
        if (mem.eql(u8, s, "cancelled")) return .cancelled;
        if (mem.eql(u8, s, "blocked")) return .blocked;
        return null;
    }

    pub fn fromEmoji(s: []const u8) ?Status {
        if (mem.eql(u8, s, "⬜")) return .todo;
        if (mem.eql(u8, s, "🚧")) return .in_progress;
        if (mem.eql(u8, s, "✅")) return .done;
        if (mem.eql(u8, s, "❌")) return .cancelled;
        if (mem.eql(u8, s, "🚫")) return .blocked;
        return null;
    }
};

/// Keyword types for task annotations
pub const Keyword = enum {
    TODO,
    FIXME,
    BUG,
    HACK,
    NOTE,
    INFO,
    IDEA,
    REFACTOR,
    REMINDER,

    pub fn fromString(s: []const u8) ?Keyword {
        var upper_buf: [32]u8 = undefined;
        if (s.len > upper_buf.len) return null;

        const upper = std.ascii.upperString(upper_buf[0..s.len], s);
        
        if (mem.eql(u8, upper, "TODO")) return .TODO;
        if (mem.eql(u8, upper, "FIXME")) return .FIXME;
        if (mem.eql(u8, upper, "BUG")) return .BUG;
        if (mem.eql(u8, upper, "HACK")) return .HACK;
        if (mem.eql(u8, upper, "NOTE")) return .NOTE;
        if (mem.eql(u8, upper, "INFO")) return .INFO;
        if (mem.eql(u8, upper, "IDEA")) return .IDEA;
        if (mem.eql(u8, upper, "REFACTOR")) return .REFACTOR;
        if (mem.eql(u8, upper, "REMINDER")) return .REMINDER;
        return null;
    }
};

/// A parsed taskspec annotation
pub const Task = struct {
    /// The keyword type (TODO, FIXME, etc.), null for Markdown task lists
    keyword: ?Keyword,
    /// The task description text
    description: []const u8,
    /// Due date in ISO 8601 format (YYYY-MM-DD or with time)
    due_date: ?[]const u8,
    /// Scheduled date in ISO 8601 format
    scheduled_date: ?[]const u8,
    /// Start date in ISO 8601 format
    start_date: ?[]const u8,
    /// Priority level
    priority: ?Priority,
    /// Recurrence pattern (e.g., "every week" or RRULE format)
    recurrence: ?[]const u8,
    /// Unique identifier for the task
    id: ?[]const u8,
    /// Assignee username
    assignee: ?[]const u8,
    /// List of tags
    tags: std.ArrayList([]const u8),
    /// List of project names
    projects: std.ArrayList([]const u8),
    /// Current status of the task
    status: ?Status,
    /// Created date in ISO 8601 format
    created_date: ?[]const u8,
    /// Completed date in ISO 8601 format
    completed_date: ?[]const u8,
    /// Estimated time/effort (e.g., "2h", "3d")
    estimate: ?[]const u8,
    /// True if parsed from Markdown task list format (- [ ] or - [x])
    is_markdown_task: bool,
    /// Custom metadata fields not in the standard specification
    custom_fields: std.StringHashMap([]const u8),

    /// Initialize a new Task with default values
    pub fn init(allocator: Allocator) Task {
        return Task{
            .keyword = null,
            .description = "",
            .due_date = null,
            .scheduled_date = null,
            .start_date = null,
            .priority = null,
            .recurrence = null,
            .id = null,
            .assignee = null,
            .tags = std.ArrayList([]const u8).init(allocator),
            .projects = std.ArrayList([]const u8).init(allocator),
            .status = null,
            .created_date = null,
            .completed_date = null,
            .estimate = null,
            .is_markdown_task = false,
            .custom_fields = std.StringHashMap([]const u8).init(allocator),
        };
    }

    /// Free resources allocated by the Task
    pub fn deinit(self: *Task) void {
        self.tags.deinit();
        self.projects.deinit();
        self.custom_fields.deinit();
    }
};

/// Parser for taskspec annotations
pub const Parser = struct {
    allocator: Allocator,

    /// Initialize a new Parser with the given allocator
    pub fn init(allocator: Allocator) Parser {
        return Parser{ .allocator = allocator };
    }

    /// Parse a single line containing a taskspec annotation
    /// Returns a Task if the line contains a valid taskspec annotation, null otherwise
    /// Caller is responsible for calling deinit() on the returned Task
    pub fn parseLine(self: Parser, line: []const u8) !?Task {
        var task = Task.init(self.allocator);
        errdefer task.deinit();

        const trimmed = mem.trim(u8, line, " \t\r\n");
        if (trimmed.len == 0) return null;

        // Check for Markdown task list format
        if (mem.startsWith(u8, trimmed, "- [ ]") or mem.startsWith(u8, trimmed, "- [x]") or mem.startsWith(u8, trimmed, "- [X]")) {
            task.is_markdown_task = true;
            const after_checkbox = if (mem.startsWith(u8, trimmed, "- [ ]"))
                mem.trimLeft(u8, trimmed[5..], " ")
            else
                mem.trimLeft(u8, trimmed[6..], " ");

            if (mem.startsWith(u8, trimmed, "- [x]") or mem.startsWith(u8, trimmed, "- [X]")) {
                task.status = .done;
            }

            try self.parseDescriptionAndMetadata(&task, after_checkbox);
            return task;
        }

        // Parse regular format with keyword
        const colon_idx = mem.indexOf(u8, trimmed, ":") orelse return null;
        
        const keyword_str = mem.trim(u8, trimmed[0..colon_idx], " \t");
        task.keyword = Keyword.fromString(keyword_str);
        
        // If no valid keyword found, this is not a taskspec annotation
        if (task.keyword == null) {
            task.deinit();
            return null;
        }

        const after_colon = mem.trimLeft(u8, trimmed[colon_idx + 1 ..], " ");
        try self.parseDescriptionAndMetadata(&task, after_colon);
        
        return task;
    }

    fn parseDescriptionAndMetadata(self: Parser, task: *Task, content: []const u8) !void {
        var desc_end: usize = content.len;

        // Find the start of the first metadata field
        var i: usize = 0;
        while (i < content.len) : (i += 1) {
            // Check for escape character
            if (content[i] == '\\' and i + 1 < content.len) {
                i += 1; // Skip the next character
                continue;
            }

            // Check for metadata markers
            if (self.isMetadataStart(content, i)) {
                desc_end = i;
                break;
            }
        }

        // Extract and store description
        task.description = mem.trim(u8, content[0..desc_end], " \t");

        // Parse metadata fields
        if (desc_end < content.len) {
            try self.parseMetadata(task, content[desc_end..]);
        }
    }

    fn isMetadataStart(self: Parser, content: []const u8, pos: usize) bool {
        _ = self;
        if (pos >= content.len) return false;

        const remaining = content[pos..];
        
        // Text-based fields
        const text_fields = [_][]const u8{
            "due:", "scheduled:", "start:", "priority:", "p:", 
            "repeat:", "rec:", "id:", "status:", "created:", 
            "done:", "estimate:",
        };
        
        for (text_fields) |field| {
            if (mem.startsWith(u8, remaining, field)) return true;
        }

        // Check for @ (assignee) or # (tag) or + (project)
        if (remaining[0] == '@' or remaining[0] == '#' or remaining[0] == '+') {
            return true;
        }

        // Check for emojis (multi-byte UTF-8)
        const emojis = [_][]const u8{
            "📅", "⏳", "🛫", "🔺", "⏫", "🔼", "🔽", "⏬",
            "🔁", "🆔", "👤", "✅", "🚧", "❌", "⬜", "🚫", "➕", "⏱️",
        };
        
        for (emojis) |emoji| {
            if (mem.startsWith(u8, remaining, emoji)) return true;
        }

        return false;
    }

    fn parseMetadata(self: Parser, task: *Task, metadata_str: []const u8) !void {
        var pos: usize = 0;
        
        while (pos < metadata_str.len) {
            // Skip whitespace
            while (pos < metadata_str.len and std.ascii.isWhitespace(metadata_str[pos])) {
                pos += 1;
            }
            
            if (pos >= metadata_str.len) break;

            const remaining = metadata_str[pos..];
            var consumed: usize = 0;

            // Try to parse a metadata field
            if (try self.parseMetadataField(task, remaining, &consumed)) {
                pos += consumed;
            } else {
                // Skip unknown character
                pos += 1;
            }
        }
    }

    fn parseMetadataField(self: Parser, task: *Task, str: []const u8, consumed: *usize) !bool {
        if (str.len == 0) return false;

        // Try emoji-based fields first
        if (mem.startsWith(u8, str, "📅")) {
            const value = try self.extractValue(str[4..]);
            task.due_date = value;
            consumed.* = 3 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "⏳")) {
            const value = try self.extractValue(str[3..]);
            task.scheduled_date = value;
            consumed.* = 3 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "🛫")) {
            const value = try self.extractValue(str[4..]);
            task.start_date = value;
            consumed.* = 4 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "🔁")) {
            const value = try self.extractValue(str[3..]);
            task.recurrence = value;
            consumed.* = 3 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "🆔")) {
            const value = try self.extractValue(str[4..]);
            task.id = value;
            consumed.* = 4 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "➕")) {
            const value = try self.extractValue(str[3..]);
            task.created_date = value;
            consumed.* = 3 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "⏱️") or mem.startsWith(u8, str, "⏱")) {
            const emoji_len: usize = if (mem.startsWith(u8, str, "⏱️")) 6 else 3;
            const value = try self.extractValue(str[emoji_len..]);
            task.estimate = value;
            consumed.* = emoji_len + value.len;
            return true;
        }

        // Priority emojis
        if (Priority.fromEmoji(str[0..@min(4, str.len)])) |priority| {
            task.priority = priority;
            const emoji_len = self.getEmojiLength(str[0..@min(4, str.len)]);
            consumed.* = emoji_len;
            return true;
        }

        // Status emojis
        if (Status.fromEmoji(str[0..@min(4, str.len)])) |status| {
            task.status = status;
            const emoji_len = self.getEmojiLength(str[0..@min(4, str.len)]);
            consumed.* = emoji_len;
            return true;
        }

        // Assignee with emoji
        if (mem.startsWith(u8, str, "👤")) {
            const value = try self.extractValue(str[4..]);
            task.assignee = value;
            consumed.* = 4 + value.len;
            return true;
        }

        // Text-based fields
        if (mem.startsWith(u8, str, "due:")) {
            const value = try self.extractValue(str[4..]);
            task.due_date = value;
            consumed.* = 4 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "scheduled:")) {
            const value = try self.extractValue(str[10..]);
            task.scheduled_date = value;
            consumed.* = 10 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "start:")) {
            const value = try self.extractValue(str[6..]);
            task.start_date = value;
            consumed.* = 6 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "priority:")) {
            const value = try self.extractValue(str[9..]);
            task.priority = Priority.fromString(value);
            consumed.* = 9 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "p:")) {
            const value = try self.extractValue(str[2..]);
            task.priority = Priority.fromString(value);
            consumed.* = 2 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "repeat:")) {
            const value = try self.extractValue(str[7..]);
            task.recurrence = value;
            consumed.* = 7 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "rec:")) {
            const value = try self.extractValue(str[4..]);
            task.recurrence = value;
            consumed.* = 4 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "id:")) {
            const value = try self.extractValue(str[3..]);
            task.id = value;
            consumed.* = 3 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "status:")) {
            const value = try self.extractValue(str[7..]);
            task.status = Status.fromString(value);
            consumed.* = 7 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "created:")) {
            const value = try self.extractValue(str[8..]);
            task.created_date = value;
            consumed.* = 8 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "done:")) {
            const value = try self.extractValue(str[5..]);
            task.completed_date = value;
            consumed.* = 5 + value.len;
            return true;
        }
        if (mem.startsWith(u8, str, "estimate:")) {
            const value = try self.extractValue(str[9..]);
            task.estimate = value;
            consumed.* = 9 + value.len;
            return true;
        }

        // Assignee
        if (str[0] == '@') {
            const value = try self.extractIdentifier(str[1..]);
            task.assignee = value;
            consumed.* = 1 + value.len;
            return true;
        }

        // Tags
        if (str[0] == '#') {
            const value = try self.extractIdentifier(str[1..]);
            try task.tags.append(value);
            consumed.* = 1 + value.len;
            return true;
        }

        // Projects
        if (str[0] == '+') {
            const value = try self.extractIdentifier(str[1..]);
            try task.projects.append(value);
            consumed.* = 1 + value.len;
            return true;
        }

        return false;
    }

    fn extractValue(self: Parser, str: []const u8) ![]const u8 {
        _ = self;
        const trimmed = mem.trimLeft(u8, str, " \t");
        var end: usize = 0;
        
        while (end < trimmed.len) : (end += 1) {
            if (std.ascii.isWhitespace(trimmed[end])) break;
            // Stop at next metadata field indicator
            if (trimmed[end] == '@' or trimmed[end] == '#' or trimmed[end] == '+') break;
        }
        
        return trimmed[0..end];
    }

    fn extractIdentifier(self: Parser, str: []const u8) ![]const u8 {
        _ = self;
        var end: usize = 0;
        
        while (end < str.len) : (end += 1) {
            const c = str[end];
            if (std.ascii.isWhitespace(c)) break;
            if (c == '@' or c == '#' or c == '+') break;
        }
        
        return str[0..end];
    }

    fn getEmojiLength(self: Parser, str: []const u8) usize {
        _ = self;
        // Simple heuristic: most emojis are 3-4 bytes in UTF-8
        if (str.len >= 4) return 4;
        if (str.len >= 3) return 3;
        return str.len;
    }
};

// Tests
test "parse TODO with description" {
    const allocator = std.testing.allocator;
    const parser = Parser.init(allocator);
    
    const line = "TODO: Fix the bug";
    var task = (try parser.parseLine(line)).?;
    defer task.deinit();
    
    try std.testing.expectEqual(Keyword.TODO, task.keyword.?);
    try std.testing.expectEqualStrings("Fix the bug", task.description);
}

test "parse FIXME with due date" {
    const allocator = std.testing.allocator;
    const parser = Parser.init(allocator);
    
    const line = "FIXME: Update documentation due:2026-02-15";
    var task = (try parser.parseLine(line)).?;
    defer task.deinit();
    
    try std.testing.expectEqual(Keyword.FIXME, task.keyword.?);
    try std.testing.expectEqualStrings("Update documentation", task.description);
    try std.testing.expectEqualStrings("2026-02-15", task.due_date.?);
}

test "parse with priority text" {
    const allocator = std.testing.allocator;
    const parser = Parser.init(allocator);
    
    const line = "TODO: Important task p:high";
    var task = (try parser.parseLine(line)).?;
    defer task.deinit();
    
    try std.testing.expectEqual(Priority.high, task.priority.?);
}

test "parse with priority emoji" {
    const allocator = std.testing.allocator;
    const parser = Parser.init(allocator);
    
    const line = "TODO: Critical bug 🔺";
    var task = (try parser.parseLine(line)).?;
    defer task.deinit();
    
    try std.testing.expectEqual(Priority.highest, task.priority.?);
}

test "parse with assignee" {
    const allocator = std.testing.allocator;
    const parser = Parser.init(allocator);
    
    const line = "TODO: Review code @martin";
    var task = (try parser.parseLine(line)).?;
    defer task.deinit();
    
    try std.testing.expectEqualStrings("martin", task.assignee.?);
}

test "parse with tags and projects" {
    const allocator = std.testing.allocator;
    const parser = Parser.init(allocator);
    
    const line = "TODO: Backend work #backend +ProjectX";
    var task = (try parser.parseLine(line)).?;
    defer task.deinit();
    
    try std.testing.expectEqual(@as(usize, 1), task.tags.items.len);
    try std.testing.expectEqualStrings("backend", task.tags.items[0]);
    try std.testing.expectEqual(@as(usize, 1), task.projects.items.len);
    try std.testing.expectEqualStrings("ProjectX", task.projects.items[0]);
}

test "parse markdown task list unchecked" {
    const allocator = std.testing.allocator;
    const parser = Parser.init(allocator);
    
    const line = "- [ ] Write tests due:2026-03-01";
    var task = (try parser.parseLine(line)).?;
    defer task.deinit();
    
    try std.testing.expect(task.is_markdown_task);
    try std.testing.expectEqualStrings("Write tests", task.description);
    try std.testing.expectEqualStrings("2026-03-01", task.due_date.?);
}

test "parse markdown task list checked" {
    const allocator = std.testing.allocator;
    const parser = Parser.init(allocator);
    
    const line = "- [x] Completed task";
    var task = (try parser.parseLine(line)).?;
    defer task.deinit();
    
    try std.testing.expect(task.is_markdown_task);
    try std.testing.expectEqual(Status.done, task.status.?);
}

test "parse with emoji metadata" {
    const allocator = std.testing.allocator;
    const parser = Parser.init(allocator);
    
    const line = "TODO: Schedule meeting 📅 2026-02-15 👤alice";
    var task = (try parser.parseLine(line)).?;
    defer task.deinit();
    
    try std.testing.expectEqualStrings("Schedule meeting", task.description);
    try std.testing.expectEqualStrings("2026-02-15", task.due_date.?);
    try std.testing.expectEqualStrings("alice", task.assignee.?);
}

test "parse multiple metadata fields" {
    const allocator = std.testing.allocator;
    const parser = Parser.init(allocator);
    
    const line = "TODO: Complex task due:2026-02-15 p:high @bob #urgent +ProjectY";
    var task = (try parser.parseLine(line)).?;
    defer task.deinit();
    
    try std.testing.expectEqualStrings("Complex task", task.description);
    try std.testing.expectEqualStrings("2026-02-15", task.due_date.?);
    try std.testing.expectEqual(Priority.high, task.priority.?);
    try std.testing.expectEqualStrings("bob", task.assignee.?);
    try std.testing.expectEqual(@as(usize, 1), task.tags.items.len);
    try std.testing.expectEqualStrings("urgent", task.tags.items[0]);
    try std.testing.expectEqual(@as(usize, 1), task.projects.items.len);
    try std.testing.expectEqualStrings("ProjectY", task.projects.items[0]);
}

test "parse status field" {
    const allocator = std.testing.allocator;
    const parser = Parser.init(allocator);
    
    const line = "TODO: In progress task status:in-progress";
    var task = (try parser.parseLine(line)).?;
    defer task.deinit();
    
    try std.testing.expectEqual(Status.in_progress, task.status.?);
}

test "parse case insensitive keyword" {
    const allocator = std.testing.allocator;
    const parser = Parser.init(allocator);
    
    const line = "todo: Lowercase keyword";
    var task = (try parser.parseLine(line)).?;
    defer task.deinit();
    
    try std.testing.expectEqual(Keyword.TODO, task.keyword.?);
}

test "priority from string variations" {
    try std.testing.expectEqual(Priority.highest, Priority.fromString("highest").?);
    try std.testing.expectEqual(Priority.highest, Priority.fromString("critical").?);
    try std.testing.expectEqual(Priority.highest, Priority.fromString("1").?);
    try std.testing.expectEqual(Priority.medium, Priority.fromString("normal").?);
    try std.testing.expectEqual(Priority.medium, Priority.fromString("3").?);
}

test "parse with escaped characters" {
    const allocator = std.testing.allocator;
    const parser = Parser.init(allocator);
    
    const line = "TODO: This is about the \\#backend team @alice";
    var task = (try parser.parseLine(line)).?;
    defer task.deinit();
    
    // The escaped # should be part of the description
    try std.testing.expect(mem.indexOf(u8, task.description, "\\#backend") != null);
    try std.testing.expectEqualStrings("alice", task.assignee.?);
    // Should not have parsed a tag
    try std.testing.expectEqual(@as(usize, 0), task.tags.items.len);
}
