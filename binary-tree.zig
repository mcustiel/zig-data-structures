const std = @import("std");
const dbg = std.debug;
const Allocator = std.mem.Allocator;
const testing = std.testing;
const stack = @import("./stack.zig");
const queue = @import("./queue.zig");

const BinaryTreeError = error{
    BSTValueExists,
    CallbackError,
};

pub fn BinaryTree(comptime T: type, comptime comparatorFn: *const fn (a: T, b: T) i2) type {
    return struct {
        const Self = @This();
        const TStack = stack.Stack(*Node, nodeCompare);
        const TQueue = queue.Queue(*Node, nodeCompare);
        const TCallback = *const fn (val: T) anyerror!bool;

        fn nodeCompare(n1: *Node, n2: *Node) i2 {
            return @as(
                i2,
                @truncate(
                    @as(i64, @intCast(@intFromPtr(n1))) - @as(i64, @intCast(@intFromPtr(n2))),
                ),
            );
        }

        pub const Node = struct {
            val: T,
            left: ?*Node = null,
            right: ?*Node = null,
        };

        _root: ?*Node = null,
        _allocator: Allocator,
        _comparatorFn: *const fn (a: T, b: T) i2,

        pub fn create(allocator: Allocator) Self {
            return Self{
                ._allocator = allocator,
                ._comparatorFn = comparatorFn,
            };
        }

        fn createNode(self: *Self, value: T) !*Node {
            const newNode: *Node = try self._allocator.create(Node);
            newNode.left = null;
            newNode.right = null;
            newNode.val = value;

            return newNode;
        }

        pub fn insertBST(self: *Self, val: T) !void {
            if (self._root == null) {
                self._root = try self.createNode(val);
                return;
            }

            var tmp: ?*Node = self._root;
            var prev: *Node = undefined;

            while (tmp != null) {
                prev = tmp.?;
                if (tmp.?.val > val) {
                    tmp = tmp.?.left;
                } else if (tmp.?.val < val) {
                    tmp = tmp.?.right;
                } else {
                    return BinaryTreeError.BSTValueExists;
                }
            }

            const node = try self.createNode(val);
            if (prev.val < val) {
                prev.right = node;
            } else {
                prev.left = node;
            }
        }

        pub fn isEmpty(self: *Self) bool {
            return self._root == null;
        }

        pub fn traverseInOrderRecursive(self: *Self, callback: TCallback) !void {
            _ = try _traverseInOrderRecursive(self._root, callback);
        }

        pub fn traversePreOrderRecursive(self: *Self, callback: TCallback) !void {
            _ = try _traversePreOrderRecursive(self._root, callback);
        }

        pub fn traversePostOrderRecursive(self: *Self, callback: TCallback) !void {
            _ = try _traversePostOrderRecursive(self._root, callback);
        }

        pub fn traverseInOrderIterative(self: *Self, callback: TCallback) !void {
            if (self._root == null) {
                return;
            }

            var tmp: ?*Node = undefined;

            var nodeStack: TStack = TStack.create(self._allocator);
            try nodeStack.push(self._root.?);
            tmp = self._root.?.left;

            while (!nodeStack.isEmpty()) {
                if (tmp != null) {
                    try nodeStack.push(tmp.?);
                    tmp = tmp.?.left;
                } else {
                    tmp = try nodeStack.pop();
                    if (!try callback(tmp.?.val)) return;
                    tmp = tmp.?.right;
                }
            }
        }

        pub fn traversePreOrderIterative(self: *Self, callback: TCallback) !void {
            if (self._root == null) {
                return;
            }

            var tmp: ?*Node = undefined;

            var nodeStack: TStack = TStack.create(self._allocator);
            try nodeStack.push(self._root.?);
            if (!try callback(self._root.?.val)) return;
            tmp = self._root.?.left;

            while (!nodeStack.isEmpty()) {
                if (tmp != null) {
                    if (!try callback(tmp.?.val)) return;
                    try nodeStack.push(tmp.?);
                    tmp = tmp.?.left;
                } else {
                    tmp = try nodeStack.pop();
                    tmp = tmp.?.right;
                }
            }
        }

        pub fn traversePosOrderIterative(self: *Self, callback: TCallback) !void {
            if (self._root == null) {
                return;
            }

            var tmp: ?*Node = undefined;

            var nodeStack: TStack = TStack.create(self._allocator);
            if (self._root.?.right orelse null != null) {
                nodeStack.push(self._root.?.right);
            }
            nodeStack.push(self._root);
            tmp = self._root.?.left;

            while (!nodeStack.isEmpty()) {
                if (tmp != null) {
                    if (tmp.?.right orelse null != null) {
                        nodeStack.push(self._root.?.right);
                    }
                    try nodeStack.push(tmp);
                    tmp = tmp.?.left;
                } else {
                    tmp = try nodeStack.pop();
                    if (tmp.?.right orelse null != null and tmp.?.right == nodeStack.see()) {
                        _ = nodeStack.pop();
                        try nodeStack.push(tmp);
                        tmp = tmp.?.right;
                    } else {
                        if (!try callback(tmp.?.val)) return;
                        tmp = null;
                    }
                }
            }
        }

        pub fn traverseBFS(self: *Self, callback: TCallback) !void {
            if (self._root == null) {
                return;
            }

            var nodeQueue: TQueue = TQueue.create(self._allocator);
            var tmp: *Node = undefined;

            try nodeQueue.enqueue(self._root.?);

            while (!nodeQueue.isEmpty()) {
                tmp = try nodeQueue.dequeue();
                if (tmp.left != null) {
                    try nodeQueue.enqueue(tmp.left.?);
                }
                if (tmp.right != null) {
                    try nodeQueue.enqueue(tmp.right.?);
                }
                if (!(try callback(tmp.val))) return;
            }
        }

        fn _traverseInOrderRecursive(node: ?*Node, callback: TCallback) !bool {
            if (node == null) {
                return true;
            }
            if (!(try _traverseInOrderRecursive(node.?.left, callback))) return false;
            if (!(try callback(node.?.val))) return false;
            if (!(try _traverseInOrderRecursive(node.?.right, callback))) return false;

            return true;
        }

        fn _traversePreOrderRecursive(node: ?*Node, callback: TCallback) !bool {
            if (node == null) {
                return true;
            }
            if (!(try callback(node.?.val))) return false;
            if (!(try _traversePreOrderRecursive(node.?.left, callback))) return false;
            if (!(try _traversePreOrderRecursive(node.?.right, callback))) return false;

            return true;
        }

        fn _traversePostOrderRecursive(node: ?*Node, callback: TCallback) !bool {
            if (node == null) {
                return true;
            }
            if (!(try _traversePostOrderRecursive(node.?.left, callback))) return false;
            if (!(try _traversePostOrderRecursive(node.?.right, callback))) return false;
            if (!(try callback(node.?.val))) return false;

            return true;
        }
    };
}

fn i8comparator(a: i8, b: i8) i2 {
    return if (a < b) -1 else if (b < a) 1 else 0;
}

test "create binary tree" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const I8BinaryTree = BinaryTree(i8, i8comparator);
    var btree = I8BinaryTree.create(allocator);

    try testing.expectEqual(true, btree.isEmpty());
}

test "insert into binary search tree" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const I8BinaryTree = BinaryTree(i8, i8comparator);
    var btree = I8BinaryTree.create(allocator);

    try testing.expectEqual(true, btree.isEmpty());
    try btree.insertBST(10);
    try testing.expectEqual(false, btree.isEmpty());
    try btree.insertBST(15);
    try btree.insertBST(5);
    try btree.insertBST(12);
    try btree.insertBST(17);
    try btree.insertBST(8);
    try btree.insertBST(3);
}

const CallbackError = error{
    TestFailed,
};
fn TraverseCallback(comptime expected: []const i8) type {
    return struct {
        const Self = @This();

        var iteration: u8 = 0;
        var expectedValues: []const i8 = expected;
        callback: *const fn (val: i8) CallbackError!bool,

        fn _callback(val: i8) CallbackError!bool {
            testing.expectEqual(expectedValues[iteration], val) catch return CallbackError.TestFailed;
            iteration += 1;
            return true;
        }

        pub fn create() Self {
            iteration = 0;
            return Self{
                .callback = Self._callback,
            };
        }
    };
}

fn SearchCallback(comptime search: i8) type {
    return struct {
        var iteration: u8 = 0;
        var searchValue: i8 = search;

        pub fn callback(val: i8) CallbackError!bool {
            const ret: bool = searchValue != val;
            iteration += 1;
            return ret;
        }

        pub fn visitedNodesCount() u8 {
            return iteration;
        }
    };
}

test "traverse binary tree: InOrder - Recursive" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const I8BinaryTree = BinaryTree(i8, i8comparator);
    var btree = I8BinaryTree.create(allocator);

    try testing.expectEqual(true, btree.isEmpty());
    try btree.insertBST(10);
    try testing.expectEqual(false, btree.isEmpty());
    try btree.insertBST(15);
    try btree.insertBST(5);
    try btree.insertBST(12);
    try btree.insertBST(17);
    try btree.insertBST(8);
    try btree.insertBST(3);

    const expected = [7]i8{ 3, 5, 8, 10, 12, 15, 17 };
    const callbackStruct = TraverseCallback(expected[0..]).create();
    try btree.traverseInOrderRecursive(callbackStruct.callback);
}

test "traverse binary tree with stop: InOrder - Recursive" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const I8BinaryTree = BinaryTree(i8, i8comparator);
    var btree = I8BinaryTree.create(allocator);

    try testing.expectEqual(true, btree.isEmpty());
    try btree.insertBST(10);
    try testing.expectEqual(false, btree.isEmpty());
    try btree.insertBST(15);
    try btree.insertBST(5);
    try btree.insertBST(12);
    try btree.insertBST(17);
    try btree.insertBST(8);
    try btree.insertBST(3);

    const values = [7]i8{ 3, 5, 8, 10, 12, 15, 17 };
    inline for (values, 0..) |value, i| {
        const callbackStruct = SearchCallback(value);
        try btree.traverseInOrderRecursive(callbackStruct.callback);
        try testing.expectEqual(callbackStruct.visitedNodesCount(), i + 1);
    }
}

test "traverse binary tree: InOrder - Iterative" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const I8BinaryTree = BinaryTree(i8, i8comparator);
    var btree = I8BinaryTree.create(allocator);

    try testing.expectEqual(true, btree.isEmpty());
    try btree.insertBST(10);
    try testing.expectEqual(false, btree.isEmpty());
    try btree.insertBST(15);
    try btree.insertBST(5);
    try btree.insertBST(12);
    try btree.insertBST(17);
    try btree.insertBST(8);
    try btree.insertBST(3);

    const expected = [7]i8{ 3, 5, 8, 10, 12, 15, 17 };
    const callbackStruct = TraverseCallback(expected[0..]).create();
    try btree.traverseInOrderIterative(callbackStruct.callback);
}

test "traverse binary tree: PreOrder - Recursive" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const I8BinaryTree = BinaryTree(i8, i8comparator);
    var btree = I8BinaryTree.create(allocator);

    try testing.expectEqual(true, btree.isEmpty());
    try btree.insertBST(10);
    try testing.expectEqual(false, btree.isEmpty());
    try btree.insertBST(15);
    try btree.insertBST(5);
    try btree.insertBST(12);
    try btree.insertBST(17);
    try btree.insertBST(8);
    try btree.insertBST(3);

    const expected = [7]i8{ 10, 5, 3, 8, 15, 12, 17 };
    const callbackStruct = TraverseCallback(expected[0..]).create();
    try btree.traversePreOrderRecursive(callbackStruct.callback);
}

test "traverse binary tree: PreOrder - Iterative" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const I8BinaryTree = BinaryTree(i8, i8comparator);
    var btree = I8BinaryTree.create(allocator);

    try testing.expectEqual(true, btree.isEmpty());
    try btree.insertBST(10);
    try testing.expectEqual(false, btree.isEmpty());
    try btree.insertBST(15);
    try btree.insertBST(5);
    try btree.insertBST(12);
    try btree.insertBST(17);
    try btree.insertBST(8);
    try btree.insertBST(3);

    const expected = [7]i8{ 10, 5, 3, 8, 15, 12, 17 };
    const callbackStruct = TraverseCallback(expected[0..]).create();
    try btree.traversePreOrderIterative(callbackStruct.callback);
}

test "traverse binary tree: BFS" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const I8BinaryTree = BinaryTree(i8, i8comparator);
    var btree = I8BinaryTree.create(allocator);

    try testing.expectEqual(true, btree.isEmpty());
    try btree.insertBST(10);
    try testing.expectEqual(false, btree.isEmpty());
    try btree.insertBST(15);
    try btree.insertBST(5);
    try btree.insertBST(12);
    try btree.insertBST(17);
    try btree.insertBST(8);
    try btree.insertBST(3);

    const expected = [7]i8{ 10, 5, 15, 3, 8, 12, 17 };
    const callbackStruct = TraverseCallback(expected[0..]).create();
    try btree.traverseBFS(callbackStruct.callback);
}
