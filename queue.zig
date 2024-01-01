const std = @import("std");
const dbg = std.debug;
const Allocator = std.mem.Allocator;
const testing = std.testing;

const list = @import("./list.zig");

pub fn Queue(comptime T: type, comptime comparatorFn: *const fn (a: T, b: T) i2) type {
    return struct {
        const Self = @This();

        const List = list.SinglyLinkedList(T, comparatorFn);

        _list: List,

        pub fn create(allocator: Allocator) Self {
            return Self{
                ._list = List.create(allocator),
            };
        }

        pub fn enqueue(self: *Self, value: T) !void {
            try self._list.append(value);
        }

        pub fn dequeue(self: *Self) !T {
            const value = try self._list.getFirst();
            try self._list.removeFirst();

            return value;
        }

        pub fn isEmpty(self: *Self) bool {
            return self._list.length == 0;
        }
    };
}

fn i8comparator(a: i8, b: i8) i2 {
    return if (a < b) -1 else if (b < a) 1 else 0;
}

test "create queue" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const I8Queue = Queue(i8, i8comparator);
    var queue = I8Queue.create(allocator);

    try testing.expectEqual(true, queue.isEmpty());
}

test "enqueue" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const I8Queue = Queue(i8, i8comparator);
    var queue = I8Queue.create(allocator);

    try testing.expectEqual(true, queue.isEmpty());
    try queue.enqueue(42);
    try testing.expectEqual(false, queue.isEmpty());
}

test "dequeue" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const I8Queue = Queue(i8, i8comparator);
    var queue = I8Queue.create(allocator);

    try testing.expectEqual(true, queue.isEmpty());
    try queue.enqueue(42);
    try testing.expectEqual(false, queue.isEmpty());
    try queue.enqueue(127);

    var val: i8 = undefined;
    val = try queue.dequeue();
    try testing.expectEqual(@as(i8, 42), val);
    val = try queue.dequeue();
    try testing.expectEqual(@as(i8, 127), val);
    try testing.expectEqual(true, queue.isEmpty());
}
