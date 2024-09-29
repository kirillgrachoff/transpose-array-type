const std = @import("std");
const builtin = std.builtin;
const testing = std.testing;

pub fn Transpose(Seq: type) type {
    const array = ArrayKind(Seq);
    const T = array.child;
    const info = switch (@typeInfo(T)) {
        .Struct => |s| s,
        else => @compileError("unsupported type"),
    };
    var fields: [info.fields.len]builtin.Type.StructField = undefined;
    inline for (info.fields, 0..) |field, i| {
        fields[i] = builtin.Type.StructField{
            .name = field.name,
            .type = array.fillWith(field.type),
            .default_value = null,
            .is_comptime = false,
            .alignment = field.alignment,
        };
    }
    const Ans: std.builtin.Type = .{ .Struct = .{
        .decls = info.decls,
        .fields = &fields,
        .layout = .auto,
        .is_tuple = false,
    } };
    return @Type(Ans);
}

pub fn ArrayKind(Seq: type) type {
    const info = @typeInfo(Seq);
    return switch (info) {
        .Array => |array| struct {
            pub const child: type = array.child;
            pub const len = array.len;
            pub fn fillWith(T: type) type {
                return [len]T;
            }
        },
        else => @compileError("unsupported type"),
    };
}

fn ChildType(Seq: type) type {
    return ArrayKind(Seq).child;
}

test "array kind" {
    const info = ArrayKind([10]i32);
    try testing.expect(info.child == i32);
    try testing.expect(info.len == 10);
    try testing.expect(ChildType(info.fillWith(u31)) == u31);
}

test "transpose" {
    const T = struct {
        x: i32,
        y: u64,
    };
    const expected = struct {
        x: [10]i32,
        y: [10]u64,
    };
    const inputType = [10]T;
    const actual = comptime Transpose(inputType);
    try testing.expect(@hasField(actual, "x"));
    try testing.expect(@hasField(actual, "y"));
    const obj = actual{
        .x = undefined,
        .y = undefined,
    };
    try testing.expect(obj.x.len == obj.y.len and obj.x.len == 10);
    try testing.expect(ChildType(@TypeOf(obj.x)) == i32);
    try testing.expect(ChildType(@TypeOf(obj.y)) == u64);
    try testing.expect(ArrayKind(inputType).child == T);
    const eI = @typeInfo(expected).Struct;
    const aI = @typeInfo(actual).Struct;
    try testing.expect(eI.fields.len == aI.fields.len);
    try testing.expect(eI.backing_integer == aI.backing_integer);
    try testing.expectEqual(eI.decls, aI.decls);
    try testing.expect(eI.is_tuple == aI.is_tuple);
    try testing.expect(eI.layout == aI.layout);
    inline for (eI.fields, aI.fields) |e, a| {
        try testing.expectEqualStrings(e.name, a.name);
        try testing.expect(e.alignment == a.alignment);
        try testing.expect(e.default_value == a.default_value);
        try testing.expect(e.type == a.type);
        try testing.expect(e.is_comptime == a.is_comptime);
    }
    comptime testing.expectEqualDeep(@typeInfo(expected), @typeInfo(actual)) catch |err| {
        std.debug.print("ERROR: types are not equal, I don't know why\n", .{});
        return err;
    };
}
