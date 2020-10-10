const std = @import("std");
const DiscordLogger = @import("./discord_logger/discord_logger.zig").DiscordLogger;
const TwitchLogger = @import("./twitch_logger/twitch_logger.zig").TwitchLogger;

// Set the log level to warning
pub const log_level: std.log.Level = .warn;

pub var discord: ?DiscordLogger = null;
const discord_channel_id = "757722210742829059";
pub var twitch: ?TwitchLogger = null;
const twitch_channel = "kristoff_it";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // Discord
    {
        const auth = std.os.getenv("DISCORD_TOKEN") orelse @panic("missing discord auth");
        discord = DiscordLogger.init(auth, &gpa.allocator);
    }

    // Twitch
    {
        const auth = std.os.getenv("TWITCH_OAUTH") orelse @panic("missing twitch auth");
        const nick = "kristoff_it";
        twitch = TwitchLogger.init(auth, nick, &gpa.allocator);
    }

    std.log.warn("Shields at 80% captain!", .{});
}

// Define root.log to override the std implementation
pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    // Ignore all non-critical logging from sources other than
    // .my_project, .nice_library and .default
    const scope_prefix = "(" ++ switch (scope) {
        .my_project, .nice_library, .default => @tagName(scope),
        else => if (@enumToInt(level) <= @enumToInt(std.log.Level.crit))
            @tagName(scope)
        else
            return,
    } ++ "): ";

    const prefix = "[" ++ @tagName(level) ++ "] " ++ scope_prefix;

    // Print the message to stderr, silently ignoring any errors
    const held = std.debug.getStderrMutex().acquire();
    defer held.release();
    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(prefix ++ format ++ "\n", args) catch return;
    (discord orelse return).sendMessage(discord_channel_id, prefix ++ format, args) catch return;
    (twitch orelse return).sendMessage(twitch_channel, prefix ++ format, args) catch return;
}

// pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
//     std.debug.print("{}\n", .{msg});
//     twitch.?.sendSimpleMessage(twitch_channel, msg) catch unreachable;
//     discord.?.sendSimpleMessage(discord_channel_id, msg) catch unreachable;
//     @breakpoint();
//     unreachable;
// }
