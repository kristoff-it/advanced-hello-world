const std = @import("std");
const format = @import("format.zig");
const request = @import("request.zig");

pub const DiscordLogger = struct {
    // Token format: "Bot <token>"
    discord_auth: []const u8,
    allocator: *std.mem.Allocator,

    pub fn init(discord_auth: []const u8, allocator: *std.mem.Allocator) DiscordLogger {
        if (!std.mem.startsWith(u8, discord_auth, "Bot ") and !std.mem.startsWith(u8, discord_auth, "User "))
            @panic("The discord_auth property needs to start with 'Bot ' or 'User '.");

        return .{ .discord_auth = discord_auth, .allocator = allocator };
    }

    pub fn sendMessage(self: DiscordLogger, channel_id: []const u8, comptime fmt: []const u8, args: anytype) !void {
        const discord_token = std.os.getenv("DISCORD_TOKEN") orelse @panic("no token!");
        var path: [0x100]u8 = undefined;
        var req = try request.Https.init(.{
            .allocator = self.allocator,
            .pem = @embedFile("./certs/discord-com-chain.pem"),
            .host = "discord.com",
            .method = "POST",
            .path = try std.fmt.bufPrint(&path, "/api/v6/channels/{}/messages", .{channel_id}),
        });
        defer req.deinit();

        try req.client.writeHeaderValue("Accept", "application/json");
        try req.client.writeHeaderValue("Content-Type", "application/json");
        try req.client.writeHeaderValue("Authorization", discord_token);

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
        try req.printSend(
            \\{{
            \\  "content": "",
            \\  "tts": false,
            \\  "embed": {{
            \\    "title": "{0}",
            \\    "description": "{1}",
            \\    "color": {2}
            \\  }}
            \\}}
        ,
            .{
                "New Log Line",
                FmtWrapper{ .args = args },
                @enumToInt(HexColor.blue),
            },
        );

        _ = try req.expectSuccessStatus();
    }

    const HexColor = enum(u24) {
        black = 0,
        aqua = 0x1ABC9C,
        green = 0x2ECC71,
        blue = 0x3498DB,
        red = 0xE74C3C,
        gold = 0xF1C40F,
        _,

        pub fn init(raw: u32) HexColor {
            return @intToEnum(HexColor, raw);
        }
    };
};
