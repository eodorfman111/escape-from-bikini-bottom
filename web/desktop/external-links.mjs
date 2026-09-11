import { externalUrl, isAppDocument } from './policy.mjs'

/**
 * @param {import('electron').WebContents} contents
 * @param {string} entryUrl
 * @param {(url: string) => Promise<void>} openExternal
 */
export function installExternalLinks(contents, entryUrl, openExternal) {
  const isLocal = () => !contents.isDestroyed() && contents.isFocused() &&
    isAppDocument(contents.getURL(), entryUrl)

  /** @param {string} elementExpression */
  async function readLink(elementExpression) {
    if (!isLocal()) return null
    try {
      // Read DOM in an isolated world; the page cannot replace these JS APIs.
      const href = await contents.executeJavaScriptInIsolatedWorld(999, [{
        code: `(() => {
          if (document.pointerLockElement) return null
          const anchor = (${elementExpression})?.closest('a[href]')
          return anchor?.href ?? null
        })()`,
      }])
      return isLocal() ? externalUrl(href) : null
    } catch {
      return null
    }
  }

  /** @param {string | null} url */
  async function openLink(url) {
    if (url && isLocal()) await openExternal(url).catch(() => {})
  }

  /** @type {{ button: string, link: Promise<string | null> } | null} */
  let pressed = null
  contents.on('before-mouse-event', (_event, mouse) => {
    if (mouse.button !== 'left' && mouse.button !== 'middle') return
    const point = `document.elementFromPoint(${JSON.stringify(mouse.x)}, ${JSON.stringify(mouse.y)})`
    if (mouse.type === 'mouseDown') {
      pressed = { button: mouse.button, link: readLink(point) }
    } else if (mouse.type === 'mouseUp') {
      const start = pressed
      pressed = null
      if (start?.button === mouse.button) {
        void Promise.all([start.link, readLink(point)]).then(([down, up]) => {
          if (down === up) return openLink(up)
        })
      }
    }
  })
  contents.on('before-input-event', (_event, input) => {
    if (input.type === 'keyDown' && input.key === 'Enter' && !input.isAutoRepeat) {
      void readLink('document.activeElement').then(openLink)
    }
  })
  contents.on('blur', () => { pressed = null })
}
