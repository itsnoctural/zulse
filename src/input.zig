const std = @import("std");

pub const InputEvent = extern struct {
    time: std.os.linux.timeval,
    type: u16,
    code: u16,
    value: i32,
};

// https://github.com/torvalds/linux/blob/v7.0/rust/kernel/ioctl.rs#L13
inline fn ioc(dir: u32, typ: u32, nr: u32, size: usize) u32 {
    return (dir << 30) | (typ << 8) | (nr << 0) | (size << 16);
}

pub inline fn eviocgbit(ev: u32, len: usize) u32 {
    return ioc(2, 'E', 0x20 + ev, len);
}

// https://github.com/torvalds/linux/blob/v7.0/tools/include/asm-generic/bitops/non-atomic.h#L110
pub inline fn test_bit(nr: u64, addr: []const u64) bool {
    const shift: u6 = @intCast(nr & (64 - 1));
    return 1 & (addr[nr / 64] >> shift) != 0;
}
