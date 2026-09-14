import { describe, expect, it, vi } from 'vitest'
import { EventEmitter } from 'node:events'
import { setImmediate } from 'node:timers/promises'
import { installExternalLinks } from './external-links.mjs'

const entry = 'file:///game/dist/index.html'
const link = 'https://spongebob.fandom.com/wiki/Patrick_Star%27s_house'

function setup() {
  const contents = new EventEmitter()
  contents.isDestroyed = vi.fn(() => false)
  contents.isFocused = vi.fn(() => true)
  contents.getURL = vi.fn(() => entry)
  contents.executeJavaScriptInIsolatedWorld = vi.fn(async () => link)
  const open = vi.fn(async () => {})
  installExternalLinks(contents, entry, open)
  const mouse = (type, button = 'left') => contents.emit('before-mouse-event', {}, {
    type, button, x: 20, y: 30,
  })
  const enter = (isAutoRepeat = false) => contents.emit('before-input-event', {}, {
    type: 'keyDown', key: 'Enter', isAutoRepeat,
  })
  return { contents, open, mouse, enter }
}

describe('external link native input gate', () => {
  it('does not open anything for renderer navigation, synthetic clicks, or key repeats', async () => {
    const { contents, open, enter } = setup()
    contents.emit('will-navigate', {}, link)
    contents.emit('click', { isTrusted: false, href: link })
    enter(true)
    await setImmediate()
    expect(open).not.toHaveBeenCalled()
  })

  it('opens matching left/middle native link clicks and Enter via isolated DOM reads', async () => {
    for (const button of ['left', 'middle']) {
      const { contents, open, mouse, enter } = setup()
      mouse('mouseDown', button)
      mouse('mouseUp', button)
      await setImmediate()
      expect(open).toHaveBeenCalledExactlyOnceWith(link)
      expect(contents.executeJavaScriptInIsolatedWorld.mock.calls[0][0]).toBe(999)
      enter()
      await setImmediate()
      expect(open).toHaveBeenCalledTimes(2)
    }
  })

  it('ignores right clicks, unmatched releases, changed targets and lost focus', async () => {
    const { contents, open, mouse } = setup()
    mouse('mouseUp')
    mouse('mouseDown', 'right')
    mouse('mouseUp', 'right')
    contents.executeJavaScriptInIsolatedWorld.mockResolvedValueOnce(link).mockResolvedValueOnce(null)
    mouse('mouseDown')
    mouse('mouseUp')
    await setImmediate()
    mouse('mouseDown')
    contents.emit('blur')
    mouse('mouseUp')
    await setImmediate()
    expect(open).not.toHaveBeenCalled()
  })

  it('revalidates URLs, local document and focus after the async DOM query', async () => {
    for (const blocked of ['file:///etc/passwd', 'javascript:alert(1)', 'https://user:pass@example.org']) {
      const { contents, open, enter } = setup()
      contents.executeJavaScriptInIsolatedWorld.mockResolvedValue(blocked)
      enter()
      await setImmediate()
      expect(open).not.toHaveBeenCalled()
    }
    const { contents, open, enter } = setup()
    enter()
    contents.getURL.mockReturnValue('https://example.org')
    await setImmediate()
    expect(open).not.toHaveBeenCalled()
    contents.getURL.mockReturnValue(entry)
    enter()
    contents.isFocused.mockReturnValue(false)
    await setImmediate()
    expect(open).not.toHaveBeenCalled()
  })

  it('handles closed windows, failed DOM queries and OS opener rejection', async () => {
    const { contents, open, enter } = setup()
    contents.executeJavaScriptInIsolatedWorld.mockRejectedValueOnce(new Error('closed frame'))
    enter()
    await setImmediate()
    expect(open).not.toHaveBeenCalled()
    open.mockRejectedValueOnce(new Error('no browser'))
    enter()
    await setImmediate()
    expect(open).toHaveBeenCalledOnce()
    contents.isDestroyed.mockReturnValue(true)
    enter()
    await setImmediate()
    expect(open).toHaveBeenCalledOnce()
  })
})
