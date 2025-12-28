const std = @import("std");
const taskspec = @import("taskspec");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const parser = taskspec.Parser.init(allocator);

    // Simulated comment extraction from a source file
    const source_lines = [_][]const u8{
        "// TODO: Refactor authentication module due:2026-02-15 p:high @alice #security",
        "// FIXME: Memory leak in parser 🔺 @bob",
        "# BUG: API returns 500 on invalid input status:in-progress @charlie #backend +API-v2",
        "<!-- TODO: Update user documentation 📅 2026-03-01 estimate:4h -->",
        "-- NOTE: Consider using prepared statements for SQL queries #database",
        "",
        "Some regular code here...",
        "",
        "// TODO: Add rate limiting rec:FREQ=DAILY id:TASK-123",
    };

    const stdout = std.io.getStdOut().writer();

    try stdout.writeAll("Taskspec Advanced Example: Parsing Source Code Comments\n");
    try stdout.writeAll("========================================================\n\n");

    var task_count: usize = 0;

    for (source_lines, 0..) |line, line_num| {
        // Extract comment content (simplified - real implementation would handle various comment styles)
        var comment_content: ?[]const u8 = null;
        
        if (std.mem.indexOf(u8, line, "//")) |idx| {
            comment_content = std.mem.trimLeft(u8, line[idx + 2..], " ");
        } else if (std.mem.indexOf(u8, line, "#")) |idx| {
            comment_content = std.mem.trimLeft(u8, line[idx + 1..], " ");
        } else if (std.mem.indexOf(u8, line, "<!--")) |idx| {
            if (std.mem.indexOf(u8, line, "-->")) |end_idx| {
                comment_content = std.mem.trim(u8, line[idx + 4..end_idx], " ");
            }
        } else if (std.mem.indexOf(u8, line, "--")) |idx| {
            comment_content = std.mem.trimLeft(u8, line[idx + 2..], " ");
        }

        if (comment_content) |content| {
            if (try parser.parseLine(content)) |*task| {
                defer task.deinit();
                
                task_count += 1;
                
                try stdout.print("Task #{d} (line {d}):\n", .{task_count, line_num + 1});
                try stdout.print("  Source: {s}\n", .{line});
                
                if (task.keyword) |kw| {
                    try stdout.print("  Type: {s}\n", .{@tagName(kw)});
                }
                
                try stdout.print("  Description: {s}\n", .{task.description});
                
                if (task.due_date) |date| {
                    try stdout.print("  Due: {s}\n", .{date});
                }
                
                if (task.priority) |prio| {
                    try stdout.print("  Priority: {s}\n", .{@tagName(prio)});
                }
                
                if (task.assignee) |assignee| {
                    try stdout.print("  Assigned to: @{s}\n", .{assignee});
                }
                
                if (task.status) |status| {
                    try stdout.print("  Status: {s}\n", .{@tagName(status)});
                }
                
                if (task.tags.items.len > 0) {
                    try stdout.writeAll("  Tags:");
                    for (task.tags.items) |tag| {
                        try stdout.print(" #{s}", .{tag});
                    }
                    try stdout.writeAll("\n");
                }
                
                if (task.projects.items.len > 0) {
                    try stdout.writeAll("  Projects:");
                    for (task.projects.items) |project| {
                        try stdout.print(" +{s}", .{project});
                    }
                    try stdout.writeAll("\n");
                }
                
                if (task.id) |id| {
                    try stdout.print("  ID: {s}\n", .{id});
                }
                
                if (task.recurrence) |rec| {
                    try stdout.print("  Recurrence: {s}\n", .{rec});
                }
                
                if (task.estimate) |est| {
                    try stdout.print("  Estimate: {s}\n", .{est});
                }
                
                try stdout.writeAll("\n");
            }
        }
    }

    try stdout.print("\nTotal tasks found: {d}\n", .{task_count});
}
