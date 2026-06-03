const std = @import("std");

pub const InputEvent = extern struct {
    time: std.os.linux.timeval,
    type: u16,
    code: u16,
    value: i32,
};

fn ioc(comptime dir: u32, comptime typ: u32, comptime nr: u32, comptime size: u32) u32 {
    return (dir << 30) | (typ << 8) | (nr << 0) | (size << 16);
}

pub fn eviocgbit(comptime ev: u32, comptime len: u32) u32 {
    return ioc(2, 'E', 0x20 + ev, len);
}

pub fn test_bit(nr: u32, addr: []const u64) bool {
    const shift: u6 = @intCast(nr & (64 - 1));
    return 1 & (addr[nr / 64] >> shift) != 0;
}
