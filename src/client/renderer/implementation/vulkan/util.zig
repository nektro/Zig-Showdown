const std = @import("std");
const vk = @import("vulkan");

fn ManyPtr(comptime Ptr: type) type {
    var type_info = @typeInfo(Ptr);
    type_info.Pointer.size = .Many;
    return @Type(type_info);
}

fn ArrayPtr(comptime Ptr: type) type {
    const type_info = @typeInfo(Ptr);
    var array_ptr_info = @typeInfo(*[1]type_info.Pointer.child);
    array_ptr_info.Pointer.is_const = type_info.Pointer.is_const;
    array_ptr_info.Pointer.is_volatile = type_info.Pointer.is_volatile;
    array_ptr_info.Pointer.alignment = type_info.Pointer.alignment;
    array_ptr_info.Pointer.is_allowzero = type_info.Pointer.is_allowzero;
    return @Type(array_ptr_info);
}

pub fn asManyPtr(ptr: anytype) ManyPtr(@TypeOf(ptr)) {
    // For some reason this doesn't work with @as
    const x: ArrayPtr(@TypeOf(ptr)) = ptr;
    return x;
}

pub fn initFeatures(comptime Features: type, overrides: anytype) Features {
    var features: Features = undefined;

    // Initialize the features to all false (or struct member default)
    inline for (std.meta.fields(Features)) |field| {
        if (field.default_value) |default| {
            @field(features, field.name) = default;
        } else {
            std.debug.assert(field.field_type == vk.Bool32);
            @field(features, field.name) = vk.FALSE;
        }
    }

    // Override the fields passed in the overrides struct
    inline for (std.meta.fields(@TypeOf(overrides))) |field| {
        @field(features, field.name) = @field(overrides, field.name);
    }

    return features;
}

pub fn SmallBuf(comptime max_size: comptime_int, comptime T: type) type {
    return struct {
        const Self = @This();

        items: [max_size]T = undefined,
        len: std.math.IntFittingRange(0, max_size) = 0,

        pub fn append(self: *Self, item: T) !void {
            if (self.len == max_size) {
                return error.OutOfMemory;
            }

            self.items[self.len] = item;
            self.len += 1;
        }

        pub fn appendAssumeCapacity(self: *Self, item: T) void {
            std.debug.assert(self.len != max_size);

            self.items[self.len] = item;
            self.len += 1;
        }

        pub fn asSlice(self: *Self) []T {
            return self.items[0 .. self.len];
        }

        pub fn asConstSlice(self: *const Self) []const T {
            return self.items[0 .. self.len];
        }
    };
}
