//! Sends a message through the Claude API.
//!
//! Needs ANTHROPIC_API_KEY, and makes a real billable call.
//! Run with `zig build example`.
//!
//! This used to be a `main` inside the library, which meant a consumer
//! linked a second entry point and the library read the environment.

const std = @import("std");
const claude = @import("claude");
const Provider = claude.Provider;
const Message = claude.Message;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    // `std.posix.getenv` was removed in Zig 0.16; the environment now
    // arrives through the entry point.
    const api_key = init.environ_map.get("ANTHROPIC_API_KEY") orelse {
        std.log.err("ANTHROPIC_API_KEY not set", .{});
        return error.MissingApiKey;
    };

    var provider: Provider = undefined;
    Provider.init(&provider, .{ .api_key = api_key }, allocator);
    defer provider.deinit();

    // ---- Test 1: Simple one-shot chat ----
    std.log.info("Sending simple message...", .{});
    const reply = try provider.chat("Hello! What's 2+2?", null);
    std.log.info("Claude says: {s}", .{reply});

    // ---- Test 2: Full message with system prompt ----
    std.log.info("Sending message with system prompt...", .{});
    const msgs = [_]Message{
        .{ .role = .user, .content = "Explain monads in one sentence." },
    };
    const resp = try provider.createMessage(.{
        .messages = &msgs,
        .system = "You are a concise programming tutor. Keep answers under 50 words.",
        .temperature = 0.3,
    });
    for (resp.content) |block| {
        if (block.text) |text| {
            std.log.info("Response: {s}", .{text});
        }
    }
    if (resp.usage) |usage| {
        std.log.info("Tokens — in: {d}, out: {d}", .{ usage.input_tokens, usage.output_tokens });
    }

    // ---- Test 3: Multi-turn conversation ----
    std.log.info("Starting multi-turn conversation...", .{});
    const convo = [_]Message{
        .{ .role = .user, .content = "My name is Alice." },
        .{ .role = .assistant, .content = "Hello Alice! Nice to meet you." },
        .{ .role = .user, .content = "What's my name?" },
    };
    const convo_resp = try provider.conversation(&convo, null);
    for (convo_resp.content) |block| {
        if (block.text) |text| {
            std.log.info("Claude remembers: {s}", .{text});
        }
    }
}
