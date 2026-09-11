import { packager } from '@electron/packager'
import { cp, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { join } from 'node:path'
import process from 'node:process'
import { fileURLToPath, URL } from 'node:url'
import { log } from 'node:console'

const root = fileURLToPath(new URL('..', import.meta.url))
const [platform = process.platform, arch = process.arch] = process.argv.slice(2)
if ((platform !== 'win32' && platform !== 'darwin' && platform !== 'linux') ||
  (arch !== 'x64' && arch !== 'arm64') || (platform !== 'darwin' && arch !== 'x64')) {
  throw new Error(`Unsupported target ${platform}-${arch}. Choose win32-x64, darwin-arm64, darwin-x64 or linux-x64.`)
}

const manifest = JSON.parse(await readFile(join(root, 'package.json'), 'utf8'))
const index = await readFile(join(root, 'dist', 'index.html'), 'utf8')
if (!index.includes('Content-Security-Policy')) {
  throw new Error('Run npm run desktop:build before packaging.')
}

const buildDirectory = join(root, '.desktop-build')
await mkdir(buildDirectory, { recursive: true })
const staging = await mkdtemp(join(buildDirectory, 'app-'))
try {
  await mkdir(join(staging, 'desktop'))
  await cp(join(root, 'dist'), join(staging, 'dist'), { recursive: true, dereference: true })
  for (const file of ['main.mjs', 'external-links.mjs', 'policy.mjs']) {
    await cp(join(root, 'desktop', file), join(staging, 'desktop', file))
  }
  await writeFile(join(staging, 'package.json'), JSON.stringify({
    name: manifest.name,
    version: manifest.version,
    private: true,
    main: 'desktop/main.mjs',
    description: 'Conch Street — Trouble in Bikini Bottom',
  }, null, 2))
  const outputs = await packager({
    dir: staging,
    out: join(root, 'release'),
    name: 'ConchStreet',
    executableName: 'conch-street',
    appBundleId: 'io.github.eodorfman111.conchstreet',
    appCategoryType: 'public.app-category.games',
    appVersion: manifest.version,
    electronVersion: manifest.devDependencies.electron,
    platform,
    arch,
    asar: true,
    prune: false,
    overwrite: true,
    tmpdir: buildDirectory,
    win32metadata: {
      ProductName: 'Conch Street',
      FileDescription: 'Conch Street — Trouble in Bikini Bottom',
      InternalName: 'conch-street',
    },
  })
  for (const output of outputs) log(`Standalone application: ${output}`)
} finally {
  await rm(staging, { recursive: true, force: true })
}
