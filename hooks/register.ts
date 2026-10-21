import type { Register } from 'claude-code'

// Supplies statusLine to the merged settings, pointing at the bundled script.
// A statusLine the person set in their own settings wins.
export const register: Register = on => {
  on('settings.read', async ($, e, next) => {
    const read = await next(e)
    if (e.source || read.deny !== undefined || read.value.statusLine) return read
    return {
      value: {
        ...read.value,
        statusLine: { type: 'command', command: `bash "${$.plugin.root}/statusline.sh"` },
      },
    }
  }).catch(($, e, next) => next(e))
}
