const std = @import("std");
const dbg = std.debug;
const Allocator = std.mem.Allocator;
const testing = std.testing;

const ListError = error{
    IndexOverflow,
    EmptyListAccess,
    TryToRemoveFromEmptyList,
};

pub fn SinglyLinkedList(comptime T: type, comptime comparatorFn: *const fn (a: T, b: T) i2) type {
    return struct {
        const Self = @This();

        pub const Node = struct {
            val: T,
            next: ?*Node = null,
        };

        _head: ?*Node = null,
        _allocator: Allocator,
        _tail: ?*Node = null,
        _comparatorFn: *const fn (a: T, b: T) i2,

        length: i16 = 0,

        pub fn create(allocator: Allocator) Self {
            return Self{
                ._allocator = allocator,
                ._comparatorFn = comparatorFn,
            };
        }

        fn createNode(self: *Self, value: T) !*Node {
            const newNode: *Node = try self._allocator.create(Node);
            newNode.next = null;
            newNode.val = value;

            return newNode;
        }

        pub fn append(self: *Self, value: T) !void {
            if (self._head == null) {
                try self.prepend(value);
                self._tail = self._head;
                return;
            }

            const newNode = try self.createNode(value);
            var tmp = self._tail;

            tmp.?.next = newNode;
            self._tail = newNode;

            self.length += 1;
        }

        pub fn insertInOrder(self: *Self, value: T) !void {
            if (self._head == null) {
                try self.prepend(value);
                self._tail = self._head;
                return;
            }

            var tmp = self._head;
            if (self._comparatorFn(tmp.?.val, value) > 0) {
                try self.prepend(value);
            } else {
                const newNode = try self.createNode(value);
                while (tmp.?.next orelse null != null and self._comparatorFn(tmp.?.next.?.val, value) < 0) tmp = tmp.?.next;

                newNode.next = tmp.?.next;
                tmp.?.next = newNode;

                if (newNode.next == null) {
                    self._tail = newNode;
                }
                self.length += 1;
            }
        }

        pub fn insertUnique(self: *Self, value: T) !bool {
            if (self._head == null) {
                try self.prepend(value);
                self._tail = self._head;
                return true;
            }

            var newNode: *Node = undefined;
            var tmp = self._head;

            while (tmp.?.next != null and self._comparatorFn(tmp.?.val, value) != 0) tmp = tmp.?.next;

            if (self._comparatorFn(tmp.?.val, value) == 0) return false;

            newNode = try self.createNode(value);

            newNode.next = tmp.?.next;
            tmp.?.next = newNode;

            if (newNode.next == null) {
                self._tail = newNode;
            }

            self.length += 1;

            return true;
        }

        pub fn prepend(self: *Self, value: T) !void {
            const newNode = try self.createNode(value);

            newNode.next = self._head;
            self._head = newNode;

            if (newNode.next == null) {
                self._tail = newNode;
            }
            self.length += 1;
        }

        pub fn display(self: *Self) void {
            var tmp = self._head;

            dbg.print("[ ", .{});
            defer dbg.print("]", .{});

            while (tmp != null) : (tmp = tmp.?.next) {
                dbg.print("{} ", .{tmp.?.val});
            }
        }

        pub fn removeFirst(self: *Self) ListError!void {
            if (self._head == null) {
                return ListError.TryToRemoveFromEmptyList;
            }

            const remove: *Node = self._head.?;

            if (self._head.?.next == null) {
                self._tail = self._head;
            }

            self._head = remove.next;

            self._allocator.destroy(remove);
            self.length -= 1;
        }

        pub fn removeLast(self: *Self) ListError!void {
            if (self._head == null) {
                return ListError.TryToRemoveFromEmptyList;
            }

            var prev: ?*Node = self._head;
            var cur: ?*Node = prev.?.next;

            if (cur == null) {
                return self.removeFirst();
            }

            while (cur.?.next orelse null != null) : (cur = cur.?.next) {
                prev = cur;
            }

            prev.?.next = null;
            self._tail = prev;

            self._allocator.destroy(cur.?);
            self.length -= 1;
        }

        pub fn removeAtPos(self: *Self, pos: u16) ListError!void {
            if (pos == 0) {
                return self.removeFirst();
            }

            if (pos >= self.length) {
                return ListError.IndexOverflow;
            }

            var tmp = self._head;
            var curPos: u16 = 0;

            while (tmp.?.next orelse null != null and curPos + 1 < pos) : (tmp = tmp.?.next) {
                curPos += 1;
            }
            // if (tmp == null) {
            //     return ListError.Unexpected;
            // }
            const delete = tmp.?.next;
            tmp.?.next = delete.?.next;

            if (tmp.?.next == null) {
                self._tail = tmp;
            }

            self._allocator.destroy(delete.?);
        }

        pub fn getAtPos(self: *Self, pos: u16) ListError!T {
            if (pos >= self.length) {
                return ListError.IndexOverflow;
            }

            if (pos == self.length - 1) {
                return self.getLast();
            }

            var tmp = self._head;
            var curPos: u16 = 0;

            while (tmp != null and curPos < pos) : (tmp = tmp.?.next) {
                curPos += 1;
            }
            // if (tmp == null) {
            //     return ListError.Unexpected;
            // }
            return tmp.?.val;
        }

        pub fn getFirst(self: *Self) ListError!T {
            if (self._head == null) {
                return ListError.EmptyListAccess;
            }

            return self._head.?.val;
        }

        pub fn getLast(self: *Self) ListError!T {
            if (self._tail == null) {
                return ListError.EmptyListAccess;
            }

            return self._tail.?.val;
        }

        pub fn clear(self: *Self) !void {
            while (self._head != null) {
                try self.removeFirst();
            }
        }
    };
}

fn i8comparator(a: i8, b: i8) i2 {
    return if (a < b) -1 else if (b < a) 1 else 0;
}

test "create list" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const LinkedListI8 = SinglyLinkedList(i8, i8comparator);
    var list = LinkedListI8.create(allocator);

    try testing.expectEqual(list.length, 0);
    try testing.expect(list.getFirst() == ListError.EmptyListAccess);
}

test "clear" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const LinkedListI8 = SinglyLinkedList(i8, i8comparator);
    var list = LinkedListI8.create(allocator);

    try testing.expectEqual(list.length, 0);
    try testing.expect(list.getFirst() == ListError.EmptyListAccess);

    try list.append(42);
    try list.append(90);
    try list.append(8);
    try testing.expectEqual(list.length, 3);

    try list.clear();
    try testing.expectEqual(list.length, 0);
    try testing.expect(list.getFirst() == ListError.EmptyListAccess);
}

test "clear empty list" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const LinkedListI8 = SinglyLinkedList(i8, i8comparator);
    var list = LinkedListI8.create(allocator);

    try testing.expectEqual(list.length, 0);

    try list.clear();
    try testing.expectEqual(list.length, 0);
}

test "append to list" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const LinkedListI8 = SinglyLinkedList(i8, i8comparator);
    var list = LinkedListI8.create(allocator);

    try list.append(42);
    try list.append(90);
    try list.append(8);

    try testing.expectEqual(list.length, 3);

    var val: i8 = undefined;
    val = try list.getAtPos(0);
    try testing.expectEqual(val, 42);
    val = try list.getAtPos(1);
    try testing.expectEqual(val, 90);
    val = try list.getAtPos(2);
    try testing.expectEqual(val, 8);
}

test "prepend to list" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const LinkedListI8 = SinglyLinkedList(i8, i8comparator);
    var list = LinkedListI8.create(allocator);

    try list.prepend(42);
    try list.prepend(90);
    try list.prepend(8);

    try testing.expectEqual(list.length, 3);

    var val: i8 = undefined;
    val = try list.getAtPos(2);
    try testing.expectEqual(val, 42);
    val = try list.getAtPos(1);
    try testing.expectEqual(val, 90);
    val = try list.getAtPos(0);
    try testing.expectEqual(val, 8);
}

test "remove first" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const LinkedListI8 = SinglyLinkedList(i8, i8comparator);
    var list = LinkedListI8.create(allocator);

    try list.append(42);
    try list.append(90);
    try testing.expectEqual(list.length, 2);

    var val: i8 = undefined;
    val = try list.getAtPos(0);
    try testing.expectEqual(val, 42);

    try list.removeFirst();
    try testing.expectEqual(list.length, 1);
    val = try list.getAtPos(0);
    try testing.expectEqual(val, 90);

    try list.removeFirst();
    try testing.expectEqual(list.length, 0);
}

test "remove first of empty list" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const LinkedListI8 = SinglyLinkedList(i8, i8comparator);
    var list = LinkedListI8.create(allocator);

    try testing.expect(list.removeFirst() == ListError.TryToRemoveFromEmptyList);
}

test "remove last" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const LinkedListI8 = SinglyLinkedList(i8, i8comparator);
    var list = LinkedListI8.create(allocator);

    try list.prepend(42);
    try list.prepend(90);
    try testing.expectEqual(list.length, 2);

    var val: i8 = undefined;
    val = try list.getAtPos(1);
    try testing.expectEqual(val, 42);

    try list.removeLast();
    try testing.expectEqual(list.length, 1);
    val = try list.getAtPos(0);
    try testing.expectEqual(val, 90);

    try list.removeLast();
    try testing.expectEqual(list.length, 0);
}

test "remove last of empty list" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const LinkedListI8 = SinglyLinkedList(i8, i8comparator);
    var list = LinkedListI8.create(allocator);

    try testing.expect(list.removeLast() == ListError.TryToRemoveFromEmptyList);
}

test "insert in order" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const LinkedListI8 = SinglyLinkedList(i8, i8comparator);
    var list = LinkedListI8.create(allocator);

    try list.insertInOrder(42);
    try list.insertInOrder(64);
    try list.insertInOrder(3);
    try list.insertInOrder(90);

    try testing.expectEqual(list.length, 4);

    var val: i8 = undefined;
    val = try list.getAtPos(0);
    try testing.expectEqual(val, 3);
    val = try list.getAtPos(1);
    try testing.expectEqual(val, 42);
    val = try list.getAtPos(2);
    try testing.expectEqual(val, 64);
    val = try list.getAtPos(3);
    try testing.expectEqual(val, 90);
}

test "insert unique" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const LinkedListI8 = SinglyLinkedList(i8, i8comparator);
    var list = LinkedListI8.create(allocator);
    var inserted: bool = undefined;

    inserted = try list.insertUnique(42);
    try testing.expect(inserted == true);
    inserted = try list.insertUnique(64);
    try testing.expect(inserted == true);
    inserted = try list.insertUnique(3);
    try testing.expect(inserted == true);

    try testing.expectEqual(list.length, 3);

    var val: i8 = undefined;
    val = try list.getAtPos(0);
    try testing.expectEqual(val, 42);
    val = try list.getAtPos(1);
    try testing.expectEqual(val, 64);
    val = try list.getAtPos(2);
    try testing.expectEqual(val, 3);

    inserted = try list.insertUnique(3);
    try testing.expect(inserted == false);
    inserted = try list.insertUnique(64);
    try testing.expect(inserted == false);
    inserted = try list.insertUnique(42);
    try testing.expect(inserted == false);

    try testing.expectEqual(list.length, 3);
}

const MyType = struct {
    name: []const u8,
    age: u8,
};

fn myTypeComparator(a: MyType, b: MyType) i2 {
    return if (a.age < b.age) -1 else if (a.age > b.age) 1 else 0;
}

test "test custom type" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const LinkedListMyType = SinglyLinkedList(MyType, myTypeComparator);
    var list = LinkedListMyType.create(allocator);
    var inserted: bool = undefined;

    inserted = try list.insertUnique(MyType{
        .name = "A",
        .age = 22,
    });
    try testing.expect(inserted == true);
    inserted = try list.insertUnique(MyType{
        .name = "B",
        .age = 24,
    });
    try testing.expect(inserted == true);
    inserted = try list.insertUnique(MyType{
        .name = "C",
        .age = 12,
    });
    try testing.expect(inserted == true);

    try testing.expectEqual(list.length, 3);

    var val: MyType = undefined;
    val = try list.getAtPos(0);
    try testing.expectEqual(val, MyType{
        .name = "A",
        .age = 22,
    });
    val = try list.getAtPos(1);
    try testing.expectEqual(val, MyType{
        .name = "B",
        .age = 24,
    });
    val = try list.getAtPos(2);
    try testing.expectEqual(val, MyType{
        .name = "C",
        .age = 12,
    });

    inserted = try list.insertUnique(MyType{
        .name = "D",
        .age = 22,
    });
    try testing.expect(inserted == false);
    inserted = try list.insertUnique(MyType{
        .name = "E",
        .age = 24,
    });
    try testing.expect(inserted == false);
    inserted = try list.insertUnique(MyType{
        .name = "E",
        .age = 24,
    });
    try testing.expect(inserted == false);

    try testing.expectEqual(list.length, 3);
}
