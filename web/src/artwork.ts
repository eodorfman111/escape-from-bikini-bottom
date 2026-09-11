import * as T from 'three'
import { box, group, cylinder } from './models'

export type Artwork = 'gary' | 'jellyfish' | 'tophat' | 'mosaic' | 'geometric' | 'portrait' | 'fullbody' | 'reclining' | 'bold'
const textures = new Map<string, T.Texture>()

function drawArt(kind: Artwork, variant: number) {
  const key = `${kind}:${variant}`
  const cached = textures.get(key)
  if (cached) return cached
  if (typeof window === 'undefined') return new T.DataTexture(new Uint8Array([180, 180, 180, 255]), 1, 1)
  const canvas = document.createElement('canvas')
  canvas.width = canvas.height = 512
  const ctx = canvas.getContext('2d')!
  const backgrounds = ['#2d284f', '#153b43', '#345a84', '#647177', '#80526d']
  ctx.fillStyle = kind === 'gary' ? '#51804c' : kind === 'jellyfish' ? '#323576' : kind === 'bold' ? '#dda34d' : kind === 'tophat' ? '#54848b' : backgrounds[variant % backgrounds.length]
  ctx.fillRect(0, 0, 512, 512)
  const path = (d: string, fill: string, stroke = '#234950', width = 5) => {
    const p = new Path2D(d)
    ctx.fillStyle = fill; ctx.strokeStyle = stroke; ctx.lineWidth = width
    ctx.fill(p); ctx.stroke(p)
  }
  const ellipse = (x: number, y: number, rx: number, ry: number, fill: string, stroke = '#294952') => {
    ctx.beginPath(); ctx.ellipse(x, y, rx, ry, 0, 0, Math.PI * 2)
    ctx.fillStyle = fill; ctx.fill(); ctx.strokeStyle = stroke; ctx.lineWidth = 4; ctx.stroke()
  }
  const line = (d: string, color = '#24434e', width = 5) => {
    ctx.strokeStyle = color; ctx.lineWidth = width; ctx.lineCap = 'round'
    ctx.stroke(new Path2D(d))
  }
  if (kind === 'gary') {
    path('M72 409Q55 374 146 373L334 365Q390 380 455 374Q477 408 416 428L128 436Z', '#96cacc')
    ellipse(219, 295, 114, 116, '#ed98ac', '#884677')
    line('M243 367C145 396 91 299 151 237C209 183 313 232 284 301C265 345 195 324 207 282Q212 260 242 271', '#b34762', 16)
    for (const [x, y] of [[165, 223], [134, 295], [236, 209], [290, 269]]) ellipse(x, y, 12, 16, '#756998', '#756998')
    path('M330 377L340 161L358 160L365 375Z', '#8fc8b1')
    path('M371 376L392 155L412 157L401 379Z', '#8fc8b1')
    ellipse(350, 145, 32, 37, '#dce187'); ellipse(406, 144, 32, 37, '#dce187')
    ellipse(357, 148, 11, 16, '#b74042'); ellipse(413, 148, 11, 16, '#b74042')
    ellipse(359, 148, 5, 10, '#222e31'); ellipse(415, 148, 5, 10, '#222e31')
  } else if (kind === 'jellyfish') {
    const glow = ctx.createRadialGradient(250, 220, 20, 250, 240, 250)
    glow.addColorStop(0, '#bb83bd'); glow.addColorStop(1, '#282a64')
    ctx.fillStyle = glow; ctx.fillRect(0, 0, 512, 512)
    path('M132 243C91 51 421 47 377 245Q352 279 329 254Q303 290 279 259Q248 289 224 259Q191 281 174 252Q148 271 132 243Z', '#ba79b7', '#df9eca')
    for (const [x, y, r] of [[210, 156, 27], [301, 171, 36], [260, 122, 17]]) ellipse(x, y, r, r * 0.72, '#7d4c9f', '#9762ad')
    for (let i = 0; i < 5; i++) {
      const x = 170 + i * 37
      line(`M${x} 264C${x - 44} 314 ${x + 38} 352 ${x - 7} 399Q${x - 20} 427 ${x + 11} 461`, '#e0abd8', 7)
    }
  } else if (kind === 'mosaic') {
    const colors = ['#c9b471', '#727a70', '#be8d64', '#6ba4a0', '#a5b488', '#d1b27d']
    for (let y = 0; y < 8; y++) for (let x = 0; x < 8; x++) {
      ctx.fillStyle = colors[(x * 3 + y * 7) % colors.length]
      ctx.fillRect(x * 64 + 3, y * 64 + 3, 58, 58)
    }
    path('M186 55L352 76L328 194L409 328L286 309L251 450L170 403L201 277L85 251L211 203Z', '#aa632f')
    path('M264 61L292 450L340 407L319 99Z', '#a33137')
    ellipse(243, 125, 54, 51, '#96b7a1'); ellipse(231, 125, 13, 18, '#f2d8a4')
    path('M250 132L326 158L249 171Z', '#94b9ae')
  } else if (kind === 'geometric' || kind === 'bold') {
    if (kind === 'geometric') {
      ctx.fillStyle = '#c6a680'; ctx.fillRect(0, 0, 512, 512)
      line('M70 400L152 96L420 75L321 219L401 381L238 299L164 439L70 400M152 96L321 219L238 299L152 96M321 219L120 218M238 299L284 99', '#715344', 10)
    } else {
      path('M166 85Q265 32 306 109L285 176L345 209Q386 268 322 274L282 247L273 330L370 412L337 460L235 386L136 452L105 412L205 319L204 220L145 257L90 234L98 203L175 174Q115 142 166 85Z', '#4eaa9c', '#4a897e', 4)
      ellipse(222, 120, 25, 35, '#6db8a6', '#438e83')
      line('M246 126L274 196L219 184', '#287966', 8)
    }
  } else {
    if (kind === 'reclining') { ctx.translate(0, 485); ctx.rotate(-Math.PI / 2) }
    if (kind === 'fullbody' || kind === 'reclining') {
      ctx.save(); ctx.translate(113, 10); ctx.scale(0.58, 0.58)
      path('M194 501L171 650L83 724L128 747L238 671L266 567L307 677L371 750L414 722L347 646L321 501Z', '#92bec3')
      path('M161 397L349 397L334 557L279 527L222 552L177 518Z', '#b9903f')
      line('M162 439Q49 455 38 611M347 438Q441 426 457 316', '#91bfc4', 24)
    }
    const head = variant % 3 === 1 ? '#8fc6c8' : '#99c8c6'
    path('M162 438L178 295L166 235Q64 252 78 133Q86 46 250 47Q425 38 433 142Q444 236 326 237L330 318L353 439Z', head)
    line('M170 100Q249 80 333 107M182 121Q246 104 324 126M202 143Q256 127 307 144', '#5e979e', 5)
    const lid = kind === 'tophat' ? '#d9cc6b' : '#efd9d0'
    ellipse(205, 235, 39, 68, lid); ellipse(290, 235, 39, 68, lid)
    ellipse(212, 249, 9, 30, '#893b4a'); ellipse(282, 249, 9, 30, '#893b4a')
    if (variant % 2 === 0) {
      path('M167 218Q204 195 244 218L242 187Q203 163 168 195Z', head)
      path('M251 219Q290 194 328 218L327 194Q291 161 251 190Z', head)
    }
    if (variant % 3 === 2 && kind !== 'tophat') {
      ellipse(256, 386, 79, 63, '#273244')
      ellipse(256, 407, 57, 28, '#984059')
    } else {
      path('M138 339Q218 367 347 334Q389 359 340 389Q231 401 135 370Z', '#a3d0cc')
      line('M159 357Q254 377 345 352')
    }
    path('M252 230Q267 238 269 302Q306 354 271 378Q221 402 201 371Q175 336 218 305Q224 262 252 230Z', '#91c2c0')
    if (kind === 'tophat') {
      path('M159 78L160 31L229 19L242 67L268 77L258 91L143 102L132 85Z', '#222b32')
      path('M192 447L240 458L283 444L286 475L242 468L196 479Z', '#a73542', '#763342')
    }
    if (kind === 'fullbody' || kind === 'reclining') ctx.restore()
  }
  ctx.globalAlpha = 0.08
  for (let i = 0; i < 10000; i++) {
    ctx.fillStyle = i % 2 ? '#ffffff' : '#111b29'
    ctx.fillRect((i * 197) % 512, (i * 83 + Math.floor(i / 512) * 31) % 512, 2, 2)
  }
  const result = new T.CanvasTexture(canvas)
  result.colorSpace = T.SRGBColorSpace
  result.anisotropy = 4
  textures.set(key, result)
  return result
}

export function painting(parent: T.Object3D, x: number, y: number, z: number, width: number, height: number, kind: Artwork, rotation = 0, variant = 0) {
  const root = group(parent, x, y, z)
  root.name = `${kind} — redrawn episode reference`
  root.rotation.y = rotation
  box(root, 0, 0, 0, width + 0.19, height + 0.19, 0.1, '#514a35')
  const picture = new T.Mesh(new T.PlaneGeometry(width, height), new T.MeshStandardMaterial({ map: drawArt(kind, variant), roughness: 0.95 }))
  picture.position.z = 0.066
  root.add(picture)
  const color = kind === 'gary' ? '#a3a352' : '#d4b363'
  for (const side of [-1, 1]) {
    cylinder(root, side * (width / 2 + 0.07), 0, 0.09, 0.07, height + 0.3, color)
    const rail = cylinder(root, 0, side * (height / 2 + 0.07), 0.09, 0.07, width + 0.3, color)
    rail.rotation.z = Math.PI / 2
  }
  return root
}
