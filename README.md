# claude-code-statusline

A Claude Code plugin that sets the status line to:

```
ctx 42% | Opus 5.5 | 48 tok/s | Claude Plan | 5h 75% · 7d 12% | ~/path/to/project | main
```

- context window usage, model, output speed of the last API call (tok/s), provider (Claude Plan / Vertex AI / Bedrock / Custom API)
- 5-hour and 7-day quota (subscription plans only)
- current directory and git branch (yellow when the working tree has changes)

Percentages are green below 70, yellow from 70, red from 90.

Claude Code plugins cannot provide `statusLine` directly, so on each session start the plugin writes `statusLine` into `~/.claude/settings.json`, pointing at its own `statusline.sh`. It also updates that path after a plugin update. A `statusLine` you set yourself is left alone: remove it to use this one. The status line appears from the session after the one where you install the plugin.

Each refresh also writes the session's usage to `~/.claude/usage/<session id>.json`, so Claude can check it from inside the session (Bash sees the id as `$CLAUDE_CODE_SESSION_ID`):

```json
{ "updated_at": 1793868719, "context_used_percentage": 7,
  "rate_limits": { "five_hour": { "used_percentage": 36, "resets_at": 1793877000 },
                   "seven_day": { "used_percentage": 50, "resets_at": 1794020400 } } }
```

`updated_at` and `resets_at` are unix seconds. The file refreshes only while the status line refreshes. `rate_limits` is absent off subscription plans.

Requires `jq`.

## Install

At the prompt of a Claude Code terminal session:

```
/plugin install statusline --marketplace ymy88/claude-code-statusline
```

Answer `y` to add the marketplace, then pick a scope (user scope applies it to every project).
