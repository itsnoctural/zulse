pub const EV = struct {
    pub const SYN = 0x00;
    pub const KEY = 0x01;
    pub const REL = 0x02;

    pub const MAX = 0x1f;
};

pub const KEY = struct {
    pub const RESERVED = 0;
    pub const ESC = 1;

    pub const MAX = 0x2ff;
};

pub const BTN = struct {
    pub const MOUSE = 0x110;
};
