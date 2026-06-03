const std = @import("std");
const input = @import("input.zig");
const event_codes = @import("event_codes.zig");

const linux = std.os.linux;

const Stat = struct {
    mouse: u64 = 0,
    keyboard: u64 = 0,
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.gpa;

    var stat = Stat{};

    var buf: [1024]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(io, &buf);
    const writer = &stdout.interface;

    var devices = try getDevices(io, allocator);
    defer devices.deinit(allocator);

    var ev: input.InputEvent = undefined;

    while (true) {
        const poll = linux.poll(devices.items.ptr, devices.items.len, -1);
        if (linux.errno(poll) != .SUCCESS) continue;

        for (devices.items) |device| {
            if (device.revents & linux.POLL.IN != 1) continue;

            const bytes = linux.read(device.fd, std.mem.asBytes(&ev), @sizeOf(input.InputEvent));
            if (linux.errno(bytes) != .SUCCESS) continue;

            if (ev.value != 0 or ev.type != event_codes.EV.KEY) continue;
            if (ev.code <= 255) {
                stat.keyboard += 1;
            } else if (ev.code > 255 and ev.code < 288) {
                stat.mouse += 1;
            }
        }

        try writer.writeAll("\x1B[2J\x1B[H");
        try writer.print("mouse: {}\nkeyboard: {}\n", .{ stat.mouse, stat.keyboard });
        try writer.flush();
    }
}

pub fn getDevices(io: std.Io, allocator: std.mem.Allocator) !std.ArrayList(linux.pollfd) {
    var devices: std.ArrayList(linux.pollfd) = .empty;

    const events_dir = try std.Io.Dir.openDirAbsolute(io, "/dev/input/", .{ .iterate = true });
    var iterator = events_dir.iterate();

    while (try iterator.next(io)) |entry| {
        if (std.mem.startsWith(u8, entry.name, "event")) {
            const event = try events_dir.openFile(io, entry.name, .{ .mode = .read_only });

            var bitmask: [event_codes.KEY.MAX / 64 + 1]u64 = undefined;
            const request = input.eviocgbit(event_codes.EV.KEY, @sizeOf(@TypeOf(bitmask)));

            const status = linux.ioctl(event.handle, request, @intFromPtr(&bitmask));
            if (linux.errno(status) != .SUCCESS) {
                return error.Unknown;
            }

            if (input.test_bit(event_codes.KEY.ESC, &bitmask) or input.test_bit(event_codes.BTN.MOUSE, &bitmask)) {
                try devices.append(allocator, .{ .fd = event.handle, .events = linux.POLL.IN, .revents = 0 });
            }
        }
    }

    return devices;
}
