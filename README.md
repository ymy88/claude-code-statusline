# claude-code-statusline

A Claude Code plugin that sets the status line to:

```
ctx 42% | Opus 5.5 | Claude Plan | 5h 75% · 7d 12% | ~/path/to/project | main
```

- context window usage, model, provider (Claude Plan / Vertex AI / Bedrock / Custom API)
- 5-hour and 7-day quota (subscription plans only)
- current directory and git branch (yellow when the working tree has changes)

Percentages are green below 70, yellow from 70, red from 90.

Claude Code plugins cannot provide `statusLine` directly, so on each session start the plugin writes `statusLine` into `~/.claude/settings.json`, pointing at its own `statusline.sh`. It also updates that path after a plugin update. A `statusLine` you set yourself is left alone: remove it to use this one. The status line appears from the session after the one where you install the plugin.

Requires `jq`.

## Install

At the prompt of a Claude Code terminal session:

```
/plugin install statusline --marketplace ymy88/claude-code-statusline
```

Answer `y` to add the marketplace, then pick a scope (user scope applies it to every project).
