const std = @import("std");
const net = std.net;

pub const TwitchLogger = struct {
    oauth: []const u8,
    nick: []const u8,
    allocator: *std.mem.Allocator,
    pub fn init(oauth: []const u8, nick: []const u8, allocator: *std.mem.Allocator) TwitchLogger {
        if (!std.mem.startsWith(u8, oauth, "oauth:"))
            @panic("The oauth property needs to start with 'oauth:'");

        return .{ .oauth = oauth, .nick = nick, .allocator = allocator };
    }

    pub fn sendSimpleMessage(self: TwitchLogger, channel: []const u8, msg: []const u8) !void {
        const con = try net.tcpConnectToHost(self.allocator, "irc.chat.twitch.tv", 6667);
        defer con.close();
        try con.writer().print(
            \\PASS {0}
            \\NICK {1}
            \\JOIN #{2}
            \\PRIVMSG #{2} :{3}
            \\PART #{2}
        , .{ self.oauth, self.nick, channel, msg });
    }
    pub fn sendMessage(self: TwitchLogger, channel: []const u8, comptime fmt: []const u8, args: anytype) !void {
        const con = try net.tcpConnectToHost(self.allocator, "irc.chat.twitch.tv", 6667);
        defer con.close();

        const FmtWrapper = struct {
            args: @TypeOf(args),
            pub fn format(
                wrapper: @This(),
                comptime _: []const u8,
                options: std.fmt.FormatOptions,
                writer: anytype,
            ) !void {
                try writer.print(fmt, wrapper.args);
            }
        };

        try con.writer().print(
            \\PASS {0}
            \\NICK {1}
            \\JOIN #{2}
            \\PRIVMSG #{2} :{3}
            \\PART #{2}
        , .{ self.oauth, self.nick, channel, FmtWrapper{ .args = args } });
    }
};
