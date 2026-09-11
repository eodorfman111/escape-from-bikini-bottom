import { app, BrowserWindow, dialog, Menu, session, shell } from 'electron'
import { dirname, join } from 'node:path'
import process from 'node:process'
import { fileURLToPath, pathToFileURL } from 'node:url'
import { installExternalLinks } from './external-links.mjs'
import { allowPermission, isAppDocument, isBundledResource } from './policy.mjs'

const appId = 'io.github.eodorfman111.conchstreet'
const distDirectory = join(dirname(fileURLToPath(import.meta.url)), '..', 'dist')
const entryFile = join(distDirectory, 'index.html')
const entryUrl = pathToFileURL(entryFile).href
/** @type {BrowserWindow | null} */
let gameWindow = null

app.setName('Conch Street')
app.setAppUserModelId(appId)
app.enableSandbox()

async function createWindow() {
  const gameSession = session.fromPartition('conch-street')
  const window = new BrowserWindow({
    title: 'Conch Street — Trouble in Bikini Bottom',
    width: 1440,
    height: 900,
    minWidth: 800,
    minHeight: 600,
    backgroundColor: '#073d46',
    show: false,
    webPreferences: {
      session: gameSession,
      sandbox: true,
      contextIsolation: true,
      nodeIntegration: false,
      nodeIntegrationInWorker: false,
      nodeIntegrationInSubFrames: false,
      webSecurity: true,
      allowRunningInsecureContent: false,
      webviewTag: false,
      navigateOnDragDrop: false,
      spellcheck: false,
      devTools: !app.isPackaged,
    },
  })
  gameWindow = window
  const contents = window.webContents
  const isOwnWindow = (/** @type {import('electron').WebContents | null} */ requester) =>
    requester === contents && !contents.isDestroyed() && isAppDocument(contents.getURL(), entryUrl)

  gameSession.setPermissionCheckHandler((requester, permission, _origin, details) =>
    allowPermission(permission, isOwnWindow(requester), details, entryUrl))
  gameSession.setPermissionRequestHandler((requester, permission, callback, details) =>
    callback(allowPermission(permission, isOwnWindow(requester), details, entryUrl)))
  gameSession.setDevicePermissionHandler(() => false)
  gameSession.on('will-download', event => event.preventDefault())
  gameSession.webRequest.onBeforeRequest((details, callback) => {
    callback({ cancel: !isBundledResource(details.url, distDirectory) })
  })

  contents.setWindowOpenHandler(() => ({ action: 'deny' }))
  contents.on('will-navigate', event => event.preventDefault())
  contents.on('will-frame-navigate', event => event.preventDefault())
  contents.on('will-redirect', event => event.preventDefault())
  contents.on('will-attach-webview', event => event.preventDefault())
  contents.setZoomFactor(1)
  await contents.setVisualZoomLevelLimits(1, 1)
  installExternalLinks(contents, entryUrl, url => shell.openExternal(url))

  window.once('ready-to-show', () => window.show())
  window.on('closed', () => { gameWindow = null })
  try {
    await window.loadFile(entryFile)
  } catch {
    dialog.showErrorBox('Unable to load Conch Street', 'The bundled game is missing or could not load. Rebuild or reinstall the complete application.')
    app.quit()
  }
}

app.whenReady().then(async () => {
  Menu.setApplicationMenu(Menu.buildFromTemplate([
    ...(process.platform === 'darwin' ? [{ role: /** @type {const} */ ('appMenu') }] : []),
    { label: 'Game', submenu: [{ role: 'togglefullscreen' }, { role: 'quit' }] },
  ]))
  await createWindow()
  app.on('activate', () => {
    if (!gameWindow) void createWindow()
  })
}).catch(() => {
  dialog.showErrorBox('Unable to start Conch Street', 'The desktop application could not initialize.')
  app.quit()
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})
