//--------------------------------------------------------------------------------------------------
//
// SIMD math library for game developers
// https://github.com/michal-z/zig-gamedev/tree/main/libs/zmath
//
// See zmath.zig for more details.
// See util.zig for additional functionality.
//
//--------------------------------------------------------------------------------------------------
pub const version = @import("std").SemanticVersion{ .major = 0, .minor = 10, .patch = 0 };

pub usingnamespace @import("zmath.zig");
pub const util = @import("util.zig");

// ensure transitive closure of test coverage
comptime {
    _ = util;
}
