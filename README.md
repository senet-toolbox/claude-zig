# claude-zig

A Claude API client for Zig, with a Vertex AI variant.

Split out of [Reverb](https://github.com/senet-toolbox/reverb), which is an
HTTP server and has no business carrying an LLM client.

## Requirements

Zig 0.16.0. No dependencies beyond `std`.

## Usage

```zig
const claude = @import("claude");

var provider: claude.Provider = undefined;
claude.Provider.init(&provider, .{ .api_key = api_key }, allocator);
defer provider.deinit();

const reply = try provider.chat("What is 2+2?", null);
```

Two modules: `claude` for the direct Anthropic API, `vertex` for the same
surface over Vertex AI, which authenticates differently.

```sh
zig build test      # analyses every declaration
zig build example   # a real billable call; needs ANTHROPIC_API_KEY
```

## Status

Extracted on 2026-10-07. This code had **never been compiled** — it was
unreachable from every build root in reverb. Turning it on surfaced two
problems:

- `std.posix.getenv`, removed in Zig 0.16.
- `chat()` hardcoded `@embedFile("context_v2.txt")` as its system prompt —
  a 20 KB prompt for an unrelated UI framework, sent on every call and
  billed as input tokens each time. The caller supplies the system prompt
  now, matching `conversation()`.

Tests force analysis via `refAllDecls` but do not exercise behaviour.
Treat it as unproven.
