const std = @import("std");

const Stat = struct {
    mouse: u64 = 0,
    keyboard: u64 = 0,
};

const InputEvent = extern struct {
    time: std.os.linux.timeval,
    type: u16,
    code: u16,
    value: i32,
};

pub fn main(init: std.process.Init) !void {
    var stat = Stat{};

    var buf: [1024]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(init.io, &buf);
    const writer = &stdout.interface;

    const mouse_fd = try open("/dev/input/event0"); // todo
    const keyboard_fd = try open("/dev/input/event0"); // todo

    var devices: [2]std.os.linux.pollfd = .{
        .{ .fd = mouse_fd, .events = std.os.linux.POLL.IN, .revents = 0 },
        .{ .fd = keyboard_fd, .events = std.os.linux.POLL.IN, .revents = 0 },
    };

    var ev: InputEvent = undefined;

    while (true) {
        const poll = std.os.linux.poll(&devices, 2, -1);
        const errno = std.os.linux.errno(poll);

        if (errno != .SUCCESS) {
            continue;
        }

        for (devices) |device| {
            if (device.revents & std.os.linux.POLL.IN != 1) continue;

            _ = std.os.linux.read(device.fd, std.mem.asBytes(&ev), @sizeOf(InputEvent));
            if (ev.type == 1 and ev.value == 0) {
                if (device.fd == mouse_fd) {
                    stat.mouse = stat.mouse + 1;
                } else {
                    stat.keyboard = stat.keyboard + 1;
                }
            }
        }

        try writer.writeAll("\x1B[2J\x1B[H");
        try writer.print("mouse: {}\nkeyboard: {}\n", .{ stat.mouse, stat.keyboard });
        try writer.flush();
    }
}

pub fn open(path: [*:0]const u8) !i32 {
    const fd = std.os.linux.open(path, .{ .ACCMODE = .RDONLY }, 0);
    const errno = std.os.linux.errno(fd);

    switch (errno) {
        .SUCCESS => {
            return @intCast(fd);
        },
        .ACCES => {
            return error.AccessDenied;
        },
        else => {
            return error.Unknown;
        },
    }
}
