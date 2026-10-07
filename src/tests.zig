//! Test root.
//!
//! `refAllDecls` forces every declaration to be analysed. Zig only checks
//! what is reachable, so without this a function nothing calls is never
//! compiled -- which is how these files kept a call to `std.posix.getenv`,
//! removed in Zig 0.16, long after it stopped existing.

const std = @import("std");

test {
    std.testing.refAllDecls(@import("claude.zig"));
    std.testing.refAllDecls(@import("vertex.zig"));
}

test {
    _ = @import("claude.zig");
    _ = @import("vertex.zig");
}
