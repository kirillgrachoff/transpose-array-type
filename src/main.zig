const std = @import("std");
const t = @import("./transpose.zig");

const Point = struct {
    x: i64,
    y: i64,
};

pub fn main() !void {
    var arr: t.Transpose([10]Point) = undefined;
    for (&arr.x, &arr.y, 0..) |*x, *y, i| {
        x.* = @intCast(i);
        y.* = @intCast(2 *| i);
    }
    for (0..9) |i| {
        std.debug.print("x: {}, y: {}\n", .{arr.x[i], arr.y[i]});
    }
}
