const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

const list = @import("./list.zig");

pub fn Stack(comptime T: type, comptime comparatorFn: *const fn (a: T, b: T) i2) type {
    return struct {
        const Self = @This();
        const List = list.SinglyLinkedList(T, comparatorFn);

        _list: List,

        pub fn create(allocator: Allocator) Self {
            return Self{
                ._list = List.create(allocator),
            };
        }

        pub fn push(self: *Self, value: T) !void {
            try self._list.prepend(value);
        }

        pub fn see(self: *Self) !T {
            return try self._list.getFirst();
        }

        pub fn pop(self: *Self) !T {
            const t = try self._list.getFirst();
            try self._list.removeFirst();

            return t;
        }

        pub fn isEmpty(self: *Self) bool {
            return self._list.length == 0;
        }
    };
}

fn i8comparator(a: i8, b: i8) i2 {
    return if (a < b) -1 else if (b < a) 1 else 0;
}

test "create stack" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const I8Stack = Stack(i8, i8comparator);
    var stack = I8Stack.create(allocator);

    try testing.expectEqual(true, stack.isEmpty());
}

test "push" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const I8Stack = Stack(i8, i8comparator);
    var stack = I8Stack.create(allocator);

    try stack.push(10);
    try testing.expectEqual(false, stack.isEmpty());
    var val: i8 = try stack.see();
    try testing.expectEqual(val, 10);

    try stack.push(12);
    val = try stack.see();
    try testing.expectEqual(val, 12);
}

test "pop" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const I8Stack = Stack(i8, i8comparator);
    var stack = I8Stack.create(allocator);

    try stack.push(10);
    try testing.expectEqual(false, stack.isEmpty());
    var val: i8 = try stack.see();
    try testing.expectEqual(val, 10);

    try stack.push(12);
    val = try stack.see();
    try testing.expectEqual(val, 12);

    val = try stack.pop();
    try testing.expectEqual(val, 12);

    val = try stack.see();
    try testing.expectEqual(val, 10);

    val = try stack.pop();
    try testing.expectEqual(val, 10);

    try testing.expectEqual(true, stack.isEmpty());
}
