# claude-code-statusline

A Claude Code plugin that sets the status line to:

```
ctx 42% | Opus 5.5 | Claude Plan | 5h 75% · 7d 12% | ~/path/to/project | main
```

- context window usage, model, provider (Claude Plan / Vertex AI / Bedrock / Custom API)
- 5-hour and 7-day quota (subscription plans only)
- current directory and git branch (yellow when the working tree has changes)

Percentages are green below 70, yellow from 70, red from 90.

The plugin only fills in `statusLine` when your own settings have none, so a `statusLine` in `~/.claude/settings.json` still wins. Remove it there to use this one.

Requires `jq`.

## Install

At the prompt of a Claude Code terminal session:

```
/plugin install statusline --marketplace ymy88/claude-code-statusline
```

Answer `y` to add the marketplace, then pick a scope (user scope applies it to every project).
