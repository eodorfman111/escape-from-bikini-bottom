import { isAbsolute, relative, resolve, sep } from 'node:path'
import { fileURLToPath, URL } from 'node:url'

/** @param {unknown} value */
export function externalUrl(value) {
  if (typeof value !== 'string') return null
  try {
    const url = new URL(value)
    if (!['https:', 'http:'].includes(url.protocol) || url.username || url.password) return null
    return url.href
  } catch {
    return null
  }
}

/** @param {string} url @param {string} entryUrl */
export function isAppDocument(url, entryUrl) {
  try {
    const document = new URL(url)
    document.hash = ''
    return document.href === entryUrl
  } catch {
    return false
  }
}

/** @param {string} url @param {string} distDirectory */
export function isBundledResource(url, distDirectory) {
  try {
    const resource = new URL(url)
    if (resource.protocol !== 'file:' || resource.hostname) return false
    const path = relative(resolve(distDirectory), fileURLToPath(resource))
    return path !== '' && path !== '..' && !path.startsWith(`..${sep}`) && !isAbsolute(path)
  } catch {
    return false
  }
}

/**
 * @param {string} permission
 * @param {boolean} ownWindow
 * @param {{ isMainFrame: boolean, requestingUrl?: string }} details
 * @param {string} entryUrl
 */
export function allowPermission(permission, ownWindow, details, entryUrl) {
  return ownWindow && details.isMainFrame &&
    isAppDocument(details.requestingUrl ?? '', entryUrl) &&
    ['pointerLock', 'fullscreen'].includes(permission)
}
