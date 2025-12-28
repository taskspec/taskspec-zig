const std = @import("std");
const taskspec = @import("taskspec");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const parser = taskspec.Parser.init(allocator);

    // Example lines to parse
    const examples = [_][]const u8{
        "TODO: Fix the authentication bug",
        "FIXME: Update documentation due:2026-02-15",
        "TODO: Implement feature p:high @alice #backend",
        "- [ ] Write unit tests 📅 2026-03-01",
        "- [x] Deploy to production",
        "TODO: Review PR due:2026-02-20 priority:highest @bob +ProjectX #urgent",
        "BUG: Memory leak in parser 🔺 @martin",
        "TODO: Schedule meeting 📅 2026-02-15 ⏳ 2026-02-10 @team #planning",
    };

    const stdout = std.io.getStdOut().writer();

    try stdout.writeAll("Taskspec Parser Examples\n");
    try stdout.writeAll("========================\n\n");

    for (examples) |line| {
        try stdout.print("Input: {s}\n", .{line});
        
        if (try parser.parseLine(line)) |*task| {
            defer task.deinit();
            
            if (task.is_markdown_task) {
                try stdout.writeAll("  Type: Markdown Task List\n");
            } else if (task.keyword) |kw| {
                try stdout.print("  Keyword: {s}\n", .{@tagName(kw)});
            }
            
            try stdout.print("  Description: {s}\n", .{task.description});
            
            if (task.due_date) |date| {
                try stdout.print("  Due Date: {s}\n", .{date});
            }
            
            if (task.scheduled_date) |date| {
                try stdout.print("  Scheduled: {s}\n", .{date});
            }
            
            if (task.start_date) |date| {
                try stdout.print("  Start Date: {s}\n", .{date});
            }
            
            if (task.priority) |prio| {
                try stdout.print("  Priority: {s}\n", .{@tagName(prio)});
            }
            
            if (task.status) |status| {
                try stdout.print("  Status: {s}\n", .{@tagName(status)});
            }
            
            if (task.assignee) |assignee| {
                try stdout.print("  Assignee: {s}\n", .{assignee});
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
        } else {
            try stdout.writeAll("  (Not a valid taskspec annotation)\n");
        }
        
        try stdout.writeAll("\n");
    }
}
