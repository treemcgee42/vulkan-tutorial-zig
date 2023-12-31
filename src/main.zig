const std = @import("std");
const builtin = @import("builtin");

const glfw = @import("c.zig").glfw;
const cglm = @import("c.zig").cglm;

const VulkanSystem = @import("vulkan/vulkan.zig");
const Math = @import("math.zig");

const WIDTH: u32 = 800;
const HEIGHT: u32 = 600;

pub const HelloTriangleApp = struct {
    allocator: std.mem.Allocator,
    window: *glfw.GLFWwindow,
    vulkan_system: VulkanSystem,

    const App = @This();

    pub const InitError = error{
        glfw_init_failed,
        glfw_create_window_failed,

        vulkan_init_failed,
    } || std.mem.Allocator.Error;

    fn init_window() InitError!*glfw.GLFWwindow {
        if (glfw.glfwInit() == 0) {
            return InitError.glfw_init_failed;
        }

        glfw.glfwWindowHint(glfw.GLFW_CLIENT_API, glfw.GLFW_NO_API);

        glfw.glfwWindowHint(glfw.GLFW_RESIZABLE, glfw.GLFW_TRUE);

        const maybe_window = glfw.glfwCreateWindow(WIDTH, HEIGHT, "Vulkan", null, null);
        if (maybe_window == null) {
            return InitError.glfw_create_window_failed;
        }
        return maybe_window.?;
    }

    pub fn init(allocator_: std.mem.Allocator) InitError!HelloTriangleApp {
        const window = try init_window();
        const vulkan_system = VulkanSystem.init(allocator_, window) catch {
            return InitError.vulkan_init_failed;
        };

        return .{
            .allocator = allocator_,
            .window = window,
            .vulkan_system = vulkan_system,
        };
    }

    pub fn setup_resize(self: *HelloTriangleApp) void {
        glfw.glfwSetWindowUserPointer(self.window, self);
        _ = glfw.glfwSetFramebufferSizeCallback(self.window, window_resize_callback);
    }

    fn window_resize_callback(window: ?*glfw.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
        _ = height;
        _ = width;
        var app: *HelloTriangleApp = @ptrCast(@alignCast(glfw.glfwGetWindowUserPointer(window)));
        app.vulkan_system.framebuffer_resized = true;
    }

    pub fn deinit(self: *HelloTriangleApp) void {
        self.vulkan_system.deinit();

        glfw.glfwDestroyWindow(self.window);

        glfw.glfwTerminate();
    }

    pub fn run(self: *HelloTriangleApp) !void {
        try self.main_loop();
    }

    fn main_loop(self: *HelloTriangleApp) !void {
        while (glfw.glfwWindowShouldClose(self.window) == 0) {
            glfw.glfwPollEvents();
            try self.vulkan_system.draw_frame();
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var app = try HelloTriangleApp.init(allocator);
    app.setup_resize();
    defer app.deinit();

    try app.run();
}
