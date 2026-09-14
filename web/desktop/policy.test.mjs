import { describe, expect, it } from 'vitest'
import { join, resolve } from 'node:path'
import { pathToFileURL } from 'node:url'
import { allowPermission, externalUrl, isAppDocument, isBundledResource } from './policy.mjs'

const dist = resolve('example game', 'dist')
const entry = pathToFileURL(join(dist, 'index.html')).href
const frame = { isMainFrame: true, requestingUrl: entry }

describe('desktop security policy', () => {
  it('only permits HTTP(S) external URLs without credentials', () => {
    expect(externalUrl('https://spongebob.fandom.com/wiki/Patrick_Star%27s_house')).toBeTruthy()
    expect(externalUrl('http://en.spongepedia.org/index.php?title=House')).toBeTruthy()
    for (const value of ['file:///etc/passwd', 'javascript:alert(1)', 'data:text/html,test',
      'ftp://example.org', 'https://user:password@example.org', '//example.org', '', null, {}]) {
      expect(externalUrl(value)).toBeNull()
    }
  })

  it('restricts documents to the packaged entry, allowing only hash navigation', () => {
    expect(isAppDocument(entry, entry)).toBe(true)
    expect(isAppDocument(`${entry}#guide`, entry)).toBe(true)
    expect(isAppDocument(`${entry}?remote=true`, entry)).toBe(false)
    expect(isAppDocument(pathToFileURL(join(dist, 'other.html')).href, entry)).toBe(false)
    expect(isAppDocument('https://example.org', entry)).toBe(false)
  })

  it('blocks remote requests, sibling files, traversal and malformed file URLs', () => {
    expect(isBundledResource(entry, dist)).toBe(true)
    expect(isBundledResource(pathToFileURL(join(dist, 'assets', 'game.js')).href, dist)).toBe(true)
    for (const url of ['https://fonts.googleapis.com/css2', 'http://localhost:3000',
      'ws://localhost:3000', 'file://server/share/asset.png', 'file:///etc/passwd',
      pathToFileURL(join(dist, '..', 'dist-secret', 'key')).href,
      `${pathToFileURL(dist).href}/%2e%2e/secret`, `${entry}/%2fsecret`, 'not a URL']) {
      expect(isBundledResource(url, dist)).toBe(false)
    }
  })

  it('grants only pointer lock/fullscreen to the local main frame in our window', () => {
    for (const permission of ['pointerLock', 'fullscreen']) {
      expect(allowPermission(permission, true, frame, entry)).toBe(true)
      expect(allowPermission(permission, false, frame, entry)).toBe(false)
      expect(allowPermission(permission, true, { ...frame, isMainFrame: false }, entry)).toBe(false)
      expect(allowPermission(permission, true, { ...frame, requestingUrl: 'https://example.org' }, entry)).toBe(false)
      expect(allowPermission(permission, true, { isMainFrame: true }, entry)).toBe(false)
    }
    for (const permission of ['media', 'geolocation', 'notifications', 'clipboard-read',
      'openExternal', 'automatic-fullscreen', 'usb', 'hid', 'serial', 'unknown']) {
      expect(allowPermission(permission, true, frame, entry)).toBe(false)
    }
  })
})
