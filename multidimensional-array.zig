const std = @import("std");
const dbg = std.debug;
const testing = std.testing;

pub fn MultidimensionalArray(comptime T: type) type {
    return struct {
        const Self = @This();

        data: []T,
        dimensions: []const u3,
        fullSize: usize,

        pub fn create(comptime dimensions: []const u3, data: []T) Self {
            return Self{
                .data = data,
                .dimensions = dimensions,
                .fullSize = getSize(dimensions),
            };
        }

        pub fn set(self: *Self, pos: []const u3, value: T) void {
            const linearPos: usize = self.getLinearPos(pos);
            self.data[linearPos] = value;
        }

        pub fn get(self: *Self, pos: []const u3) T {
            const linearPos: usize = self.getLinearPos(pos);
            return self.data[linearPos];
        }

        fn getLinearPos(self: *Self, pos: []const u3) usize {
            var index: usize = 0;
            var linearPos: usize = 0;

            for (pos) |axisPos| {
                if (index < pos.len - 1) {
                    linearPos += axisPos * self.dimensions[index + 1];
                }
                index += 1;
            }

            return linearPos + pos[index - 1];
        }

        fn getSize(pos: []const u3) usize {
            var linearPos: usize = 1;
            for (pos) |axisPos| {
                linearPos *= axisPos;
            }

            return linearPos;
        }
    };
}

test "create Multidimensional array" {
    const i8MultidimensionalArray = MultidimensionalArray(i8);

    const size = [2]u3{ 2, 2 };
    var data = [4]i8{ 1, 2, 3, 5 };
    const array: i8MultidimensionalArray = i8MultidimensionalArray.create(&size, &data);

    _ = array;
}

test "get" {
    const i8MultidimensionalArray = MultidimensionalArray(i8);

    const size = [2]u3{ 2, 2 };
    var data = [4]i8{ 1, 2, 3, 5 };
    var array: i8MultidimensionalArray = i8MultidimensionalArray.create(&size, &data);

    var i: u3 = 0;
    var j: u3 = 0;
    var val: i8 = undefined;
    var cur: usize = 0;

    while (i < 2) : (i += 1) {
        while (j < 2) : (j += 1) {
            val = array.get(.{ i, j });
            try testing.expectEqual(data[cur], val);
            cur += 1;
        }
    }
}

test "set" {
    const i8MultidimensionalArray = MultidimensionalArray(i8);

    const size = [2]u3{ 2, 2 };
    var data = [4]i8{ 1, 2, 3, 5 };
    var array: i8MultidimensionalArray = i8MultidimensionalArray.create(&size, &data);

    var i: u3 = 0;
    var j: u3 = 0;
    var val: i8 = undefined;

    while (i < 2) : (i += 1) {
        while (j < 2) : (j += 1) {
            array.set(.{ i, j }, i * 2 + j);
        }
    }

    while (i < 2) : (i += 1) {
        while (j < 2) : (j += 1) {
            val = array.get(.{ i, j });
            try testing.expectEqual(@as(i8, i * 2 + j), val);
        }
    }
}
