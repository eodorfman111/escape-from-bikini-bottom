import { beforeEach, describe, expect, it, vi } from 'vitest'
import { EventEmitter } from 'node:events'
import { setImmediate } from 'node:timers/promises'
import { error } from 'node:console'

const electron = vi.hoisted(() => ({
  app: {
    setName: vi.fn(),
    setAppUserModelId: vi.fn(),
    enableSandbox: vi.fn(),
    whenReady: vi.fn(),
    on: vi.fn(),
    quit: vi.fn(),
    exit: vi.fn(),
    isPackaged: true,
  },
  BrowserWindow: vi.fn(),
  dialog: { showErrorBox: vi.fn() },
  Menu: { setApplicationMenu: vi.fn(), buildFromTemplate: vi.fn() },
  session: { fromPartition: vi.fn() },
  shell: { openExternal: vi.fn() },
}))

vi.mock('electron', () => electron)
vi.mock('node:console', () => ({ error: vi.fn() }))

function setup() {
  const contents = new EventEmitter()
  contents.setWindowOpenHandler = vi.fn()
  contents.setZoomFactor = vi.fn()
  let rendererReady = false
  contents.setVisualZoomLevelLimits = vi.fn(() => rendererReady
    ? Promise.resolve()
    : new Promise(() => {}))
  const window = new EventEmitter()
  window.webContents = contents
  window.loadFile = vi.fn(async () => { rendererReady = true })
  electron.BrowserWindow.mockImplementation(function () { return window })
  electron.app.whenReady.mockResolvedValue()
  electron.session.fromPartition.mockReturnValue({
    setPermissionCheckHandler: vi.fn(),
    setPermissionRequestHandler: vi.fn(),
    setDevicePermissionHandler: vi.fn(),
    on: vi.fn(),
    webRequest: { onBeforeRequest: vi.fn() },
  })
  return { window, contents }
}

beforeEach(() => {
  vi.resetModules()
  vi.resetAllMocks()
})

describe('native desktop startup', () => {
  it('loads a renderer before awaiting renderer IPC and creates a visible sandboxed window', async () => {
    const { window, contents } = setup()
    await import('./main.mjs')
    await setImmediate()
    expect(window.loadFile).toHaveBeenCalledOnce()
    expect(contents.setVisualZoomLevelLimits).toHaveBeenCalledExactlyOnceWith(1, 1)
    expect(electron.BrowserWindow.mock.calls[0][0]).toMatchObject({
      show: true,
      webPreferences: { sandbox: true, contextIsolation: true, nodeIntegration: false, webSecurity: true },
    })
    expect(electron.app.enableSandbox).toHaveBeenCalledOnce()
    expect(electron.app.on).toHaveBeenCalledWith('activate', expect.any(Function))
    expect(electron.dialog.showErrorBox).not.toHaveBeenCalled()
  })

  it('displays the load failure and exits with an error code', async () => {
    const { window } = setup()
    window.loadFile.mockRejectedValue(new Error('ERR_FILE_NOT_FOUND'))
    await import('./main.mjs')
    await setImmediate()
    expect(electron.dialog.showErrorBox).toHaveBeenCalledWith(
      'Unable to start Conch Street', expect.stringContaining('ERR_FILE_NOT_FOUND'))
    expect(error).toHaveBeenCalled()
    expect(electron.app.exit).toHaveBeenCalledExactlyOnceWith(1)
  })

  it('reports a renderer crash but ignores clean renderer shutdown', async () => {
    const { contents } = setup()
    await import('./main.mjs')
    await setImmediate()
    contents.emit('render-process-gone', {}, { reason: 'clean-exit', exitCode: 0 })
    expect(electron.dialog.showErrorBox).not.toHaveBeenCalled()
    contents.emit('render-process-gone', {}, { reason: 'crashed', exitCode: 139 })
    expect(electron.dialog.showErrorBox).toHaveBeenCalledWith(
      'Unable to start Conch Street', expect.stringContaining('Renderer crashed (exit code 139)'))
    expect(electron.app.exit).toHaveBeenCalledExactlyOnceWith(1)
  })
})
