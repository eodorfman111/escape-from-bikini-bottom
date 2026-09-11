import './style.css'
import { Game } from './game'
import type { GameView } from './game'
import type { Mode } from './rules'
import { researchMarkup } from './research'

const icons: Record<string, string> = {
  flower: '<path d="M12 8C3-4-3 10 7 12c-13 5 1 15 4 4 5 13 15 0 5-4 13-4 0-15-4-4Z"/><circle cx="12" cy="12" r="2"/>',
  arrow: '<path d="M4 12h15m-6-6 6 6-6 6"/>',
  compass: '<circle cx="12" cy="12" r="9"/><path d="m16 8-3 5-5 3 3-5Z"/>',
  book: '<path d="M12 5v15M3 4c4-1 6 0 9 2 3-2 5-3 9-2v14c-4-1-6 0-9 2-3-2-5-3-9-2Z"/>',
  volume: '<path d="m11 4-6 5H2v6h3l6 5Zm4 4c3 2 3 6 0 8m3-11c5 4 5 10 0 14"/>',
  mute: '<path d="m11 4-6 5H2v6h3l6 5Zm5 5 6 6m0-6-6 6"/>',
  heart: '<path d="M12 20 3 11C-2 3 8-1 12 6c4-7 14-3 9 5Z"/>',
  shield: '<path d="m12 2 8 4v7c0 4-5 7-8 9-3-2-8-5-8-9V6Z"/><path d="m8 12 3 3 5-6"/>',
  pause: '<path d="M8 5v14m8-14v14"/>',
  close: '<path d="m5 5 14 14M19 5 5 19"/>',
  target: '<circle cx="12" cy="12" r="7"/><path d="M12 1v6m0 10v6M1 12h6m10 0h6"/>',
  check: '<path d="m5 12 4 4 10-10"/>',
}
const icon = (name: string) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${icons[name] ?? icons.compass}</svg>`
const app = document.querySelector<HTMLDivElement>('#app')!
app.innerHTML = `
  <canvas id="world" aria-label="First-person Bikini Bottom game"></canvas>
  <div class="water-grain" aria-hidden="true"></div>
  <div id="landing">
    <div class="landing-shade"></div>
    <header class="site-header">
      <a href="#" class="brand" aria-label="Conch Street home"><span class="brand-mark">${icon('flower')}</span><span>CONCH STREET<small>AN UNDERSEA ADVENTURE</small></span></a>
      <nav><button class="text-button guide-button">${icon('book')} Field guide</button><span class="nav-divider"></span><button class="icon-button sound-button" aria-label="Mute sound">${icon('volume')}</button></nav>
    </header>
    <main class="hero">
      <div class="hero-kicker"><span class="live-dot"></span> SOMEWHERE, UNDER THE SEA</div>
      <h1>Trouble in<br><em>Bikini Bottom.</em></h1>
      <p class="hero-description">Something’s fishy in the neighborhood.<br>Grab your pistol. Find your friends.<br>Make yourself at home. Then defend it.</p>
      <div class="hero-actions">
        <button id="start-survival" class="primary-button"><span>Let’s do this</span>${icon('arrow')}</button>
        <button id="start-explore" class="explore-button">${icon('compass')} Just explore</button>
      </div>
      <div class="game-meta"><span>FIRST-PERSON SURVIVAL</span><i></i><span>5 WAVES. 3 HOMES. YOUR NEIGHBORHOOD.</span></div>
    </main>
    <aside class="postcard"><span class="postcard-line"></span><span>WELCOME TO<br><b>Conch Street</b><small>BIKINI BOTTOM · EST. 1999</small></span></aside>
    <footer class="landing-footer"><span>YOU DON’T HAVE TO FACE THE TIDE ALONE.</span><label class="crew-switch"><span class="crew-faces"><i class="sponge-face"></i><i class="patrick-face"></i></span><span>Bring SpongeBob & Patrick</span><input id="crew" type="checkbox" checked /><span class="switch-track"></span></label><button class="guide-button footer-link">Built from the show. See our notes ↗</button></footer>
  </div>
  <div id="hud" hidden>
    <div class="hud-top">
      <div class="location-block"><span class="eyebrow" id="location-name">CONCH STREET</span><h2 id="room-name">Bikini Bottom</h2><span id="shelter" class="shelter-status">OPEN WATER</span></div>
      <div class="wave-block"><span id="wave-label">THE TIDE IS TURNING</span><strong id="wave-number">00 <i>/ 05</i></strong><small id="wave-detail">First wave in 9s</small></div>
      <div class="hud-buttons"><button class="icon-button guide-button" aria-label="Open field guide">${icon('book')}</button><button id="pause-button" class="icon-button" aria-label="Pause game">${icon('pause')}</button></div>
    </div>
    <div class="compass-strip"><span>W</span><i></i><i></i><b>N</b><i></i><i></i><span>E</span></div>
    <div id="crosshair"><span></span><i></i></div>
    <div id="hit-marker">×</div>
    <div id="interaction" hidden><kbd>E</kbd><span></span></div>
    <div id="toast" role="status" aria-live="polite"></div>
    <div class="hud-bottom">
      <div class="player-status"><div class="health-row">${icon('heart')}<strong id="health-number">100</strong><span>HEALTH</span></div><div class="health-track"><i id="health-fill"></i></div><div id="crew-status" class="crew-status"><span class="crew-faces"><i class="sponge-face"></i><i class="patrick-face"></i></span><span>THE GANG’S ALL HERE<small>Bubble support + rock toss</small></span></div></div>
      <div class="control-hints"><span><kbd>W A S D</kbd> Move</span><span><kbd>SHIFT</kbd> Sprint</span><span><kbd>R</kbd> Reload</span><span><kbd>E</kbd> Interact</span><span><kbd>B</kbd> Barricade</span></div>
      <div class="ammo-block"><span id="weapon-name">REEF PISTOL</span><strong><b id="ammo-number">12</b><i>/ <span id="reserve-number">84</span></i></strong><small id="reload-state">SEMI-AUTO · CLICK TO FIRE</small></div>
    </div>
    <div class="mini-map"><canvas id="map" width="180" height="180" aria-label="Map of nearby walls, friends and fish"></canvas><span>CONCH NAVIGATION <b>●</b></span></div>
    <div id="touch-controls"><div id="joystick" aria-label="Movement joystick"><i></i></div><div class="touch-actions"><button id="touch-interact" aria-label="Interact">E</button><button id="touch-reload" aria-label="Reload">R</button><button id="touch-barricade" aria-label="Barricade">B</button><button id="touch-fire" aria-label="Fire pistol">${icon('target')}</button></div><span class="touch-look-hint">DRAG THE VIEW TO LOOK</span></div>
    <div class="damage-vignette"></div>
  </div>
  <dialog id="pause-dialog" class="small-dialog">
    <span class="eyebrow">TAKE A BREATHER</span><h2>A moment<br><em>above the tide.</em></h2>
    <p>The neighborhood can wait. Your game is paused.</p>
    <button id="resume" class="primary-button">Back to it ${icon('arrow')}</button>
    <div class="settings-row"><label for="sensitivity">Look sensitivity</label><input id="sensitivity" type="range" min="0.3" max="2" step="0.1" value="1" /></div>
    <div class="pause-controls"><span><kbd>WASD</kbd> Move · <kbd>SHIFT</kbd> Sprint</span><span><kbd>MOUSE</kbd> Look · <kbd>CLICK</kbd> Fire</span><span><kbd>E</kbd> Doors, stairs & supplies</span><span><kbd>R</kbd> Reload · <kbd>B</kbd> Rebuild front door</span><span><kbd>ESC / P</kbd> Pause · Drag to look if capture is unavailable</span></div>
    <p class="tip">Closed doors buy time. Supply crates refill every 30 seconds. Upstairs won’t keep the fish out forever.</p>
    <div class="dialog-secondary"><button id="restart">Start over</button><button id="menu">Main menu</button></div>
  </dialog>
  <dialog id="guide-dialog" class="guide-dialog"><button id="close-guide" class="icon-button" aria-label="Close field guide">${icon('close')}</button>${researchMarkup()}</dialog>
  <dialog id="end-dialog" class="small-dialog"><span id="end-eyebrow" class="eyebrow"></span><h2 id="end-title"></h2><p id="end-description"></p><div id="end-stats"></div><button id="play-again" class="primary-button">One more tide ${icon('arrow')}</button><button id="end-menu" class="text-button">Back to the neighborhood</button></dialog>
  <div id="error" hidden role="alert"><h2>We couldn’t reach Bikini Bottom.</h2><p>This game needs WebGL. Try enabling hardware acceleration or using a recent browser.</p><button onclick="location.reload()">Try again</button></div>
`

function element<T extends HTMLElement = HTMLElement>(id: string) { return document.getElementById(id) as T }
const landing = element('landing')
const hud = element('hud')
const pauseDialog = element<HTMLDialogElement>('pause-dialog')
const guideDialog = element<HTMLDialogElement>('guide-dialog')
const endDialog = element<HTMLDialogElement>('end-dialog')
let mode: Mode = 'survival'
let game: Game
let toastTimeout: ReturnType<typeof setTimeout>
let hitTimeout: ReturnType<typeof setTimeout>
let pausedForGuide = false

function toast(text: string) {
  const target = element('toast')
  target.textContent = text
  target.classList.add('visible')
  clearTimeout(toastTimeout)
  toastTimeout = setTimeout(() => target.classList.remove('visible'), 4200)
}

function drawMap() {
  const info = game.getMapInfo()
  const headings = ['N', 'E', 'S', 'W']
  const heading = ((Math.round(-info.yaw / (Math.PI / 2)) % 4) + 4) % 4
  const compass = document.querySelector('.compass-strip')!
  compass.querySelector('b')!.textContent = headings[heading]
  compass.querySelector('span:first-child')!.textContent = headings[(heading + 3) % 4]
  compass.querySelector('span:last-child')!.textContent = headings[(heading + 1) % 4]
  const ctx = element<HTMLCanvasElement>('map').getContext('2d')!
  ctx.clearRect(0, 0, 180, 180)
  const outdoor = info.location === 'street'
  const scale = outdoor ? 1.45 : 6.5
  const center = outdoor ? { x: info.player.x, z: info.player.z } : { x: 0, z: 0 }
  const point = (p: { x: number; z: number }) => ({ x: 90 + (p.x - center.x) * scale, y: 90 + (p.z - center.z) * scale })
  ctx.strokeStyle = '#afc7b918'
  for (let i = 0; i <= 180; i += 30) {
    ctx.beginPath(); ctx.moveTo(i, 0); ctx.lineTo(i, 180); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(0, i); ctx.lineTo(180, i); ctx.stroke()
  }
  if (outdoor) {
    const p = point({ x: 0, z: 15 })
    ctx.fillStyle = '#97b9ae30'
    ctx.fillRect(0, p.y - 5, 180, 10)
  }
  ctx.fillStyle = '#8caf9b70'
  for (const w of info.walls) {
    const p = point(w)
    ctx.fillRect(p.x - w.w * scale / 2, p.y - w.d * scale / 2, w.w * scale, w.d * scale)
  }
  for (const i of info.interactions) {
    const p = point(i.at)
    ctx.fillStyle = i.kind === 'supply' ? '#f1c67b' : '#d9e9bf'
    ctx.fillRect(p.x - 2, p.y - 2, 4, 4)
  }
  for (const [items, color] of [[info.enemies, '#ee917b'], [info.companions, '#bddd96']] as const) {
    ctx.fillStyle = color
    for (const item of items) {
      const p = point(item)
      ctx.beginPath(); ctx.arc(p.x, p.y, 2.5, 0, Math.PI * 2); ctx.fill()
    }
  }
  const player = point(info.player)
  ctx.save(); ctx.translate(player.x, player.y); ctx.rotate(-info.yaw)
  ctx.fillStyle = '#fff6d6'
  ctx.beginPath(); ctx.moveTo(0, -6); ctx.lineTo(-4, 5); ctx.lineTo(0, 3); ctx.lineTo(4, 5); ctx.closePath(); ctx.fill()
  ctx.restore()
}

function update(view: GameView) {
  const state = view.state
  element('location-name').textContent = view.world.name
  element('room-name').textContent = view.room
  const shelter = element('shelter')
  shelter.classList.toggle('safe', view.sheltered)
  shelter.textContent = state.mode === 'explore' ? 'EXPLORATION · NO ENEMIES' : view.world.home ? view.door > 0 ? `DOOR BARRICADE ${Math.ceil(view.door)}%${view.sheltered ? ' · SHELTERED' : ' · FISH INSIDE'}` : 'DOOR BREACHED · STAY ALERT' : 'OPEN WATER · STAY SHARP'
  element('wave-label').textContent = state.mode === 'explore' ? 'NO RUSH. LOOK AROUND.' : state.phase === 'wave' ? 'HOLD THE NEIGHBORHOOD' : state.phase === 'rest' ? 'A LITTLE BREATHING ROOM' : 'THE TIDE IS TURNING'
  element('wave-number').innerHTML = state.mode === 'explore' ? `${icon('compass')}` : `${String(state.wave).padStart(2, '0')} <i>/ 05</i>`
  element('wave-detail').textContent = state.mode === 'explore' ? 'Visit all three homes' : state.phase === 'wave' ? `${state.remaining} fish remaining` : `Next wave in ${Math.max(0, Math.ceil(state.timer))}s`
  element('health-number').textContent = String(Math.ceil(state.health))
  element('health-fill').style.width = `${state.health}%`
  element('health-fill').classList.toggle('low', state.health < 30)
  element('ammo-number').textContent = state.mode === 'explore' ? '∞' : String(state.clip).padStart(2, '0')
  element('reserve-number').textContent = String(state.reserve)
  element('weapon-name').textContent = state.mode === 'explore' ? 'EXPLORER MODE' : 'REEF PISTOL'
  element('reload-state').textContent = state.mode === 'explore' ? 'THE NEIGHBORHOOD IS YOURS' : state.reloadLeft > 0 ? 'RELOADING…' : state.clip === 0 ? 'PRESS R TO RELOAD' : 'SEMI-AUTO · CLICK TO FIRE'
  element('crew-status').hidden = !view.companions
  const interact = element('interaction')
  interact.hidden = !view.interaction
  interact.querySelector('span')!.textContent = view.interaction
  drawMap()
}

function end(won: boolean) {
  element('end-eyebrow').textContent = won ? 'CONCH STREET IS SAFE' : 'THE TIDE GOT THE BEST OF YOU'
  element('end-title').innerHTML = won ? 'Good neighbors.<br><em>Great survivors.</em>' : 'A little<br><em>out of your depth.</em>'
  element('end-description').textContent = won ? 'Five waves down. The pineapple is still standing. Not bad for a day under the sea.' : 'Every good story deserves another try. Use the houses, restock, and stay close to your friends.'
  element('end-stats').innerHTML = `<div><b>${game.state.wave}</b><span>WAVE REACHED</span></div><div><b>${game.state.kills}</b><span>FISH DEFEATED</span></div><div><b>${Math.floor(game.state.elapsed / 60)}:${String(Math.floor(game.state.elapsed % 60)).padStart(2, '0')}</b><span>TIME SURVIVED</span></div>`
  endDialog.showModal()
}

try {
  game = new Game(element<HTMLCanvasElement>('world'), {
    update,
    pause: () => { if (!guideDialog.open && !endDialog.open && !pauseDialog.open) pauseDialog.showModal() },
    end, toast,
    hit: () => {
      element('hit-marker').classList.add('visible')
      clearTimeout(hitTimeout)
      hitTimeout = setTimeout(() => element('hit-marker').classList.remove('visible'), 150)
    },
  })
} catch (error) {
  console.error('Unable to initialize game renderer', error)
  element('error').hidden = false
}

function start(selectedMode: Mode) {
  mode = selectedMode
  pauseDialog.close()
  endDialog.close()
  landing.hidden = true
  hud.hidden = false
  game.start(mode, element<HTMLInputElement>('crew').checked)
}
element('start-survival').addEventListener('click', () => start('survival'))
element('start-explore').addEventListener('click', () => start('explore'))
element('pause-button').addEventListener('click', () => game.pause())
element('resume').addEventListener('click', () => { pauseDialog.close(); game.resume() })
pauseDialog.addEventListener('cancel', e => { e.preventDefault(); pauseDialog.close(); game.resume() })
element('restart').addEventListener('click', () => start(mode))
element('play-again').addEventListener('click', () => start(mode))
function mainMenu() {
  pauseDialog.close(); endDialog.close(); guideDialog.close()
  landing.hidden = false; hud.hidden = true
  game.mainMenu()
}
element('menu').addEventListener('click', mainMenu)
element('end-menu').addEventListener('click', mainMenu)
endDialog.addEventListener('cancel', e => { e.preventDefault(); mainMenu() })
document.querySelectorAll<HTMLButtonElement>('.guide-button').forEach(button => {
  button.addEventListener('click', () => {
    pausedForGuide = game.playing && !game.paused
    guideDialog.showModal()
    if (pausedForGuide) game.pause()
  })
})
function closeGuide() {
  guideDialog.close()
  if (pausedForGuide) { pausedForGuide = false; game.resume() }
}
element('close-guide').addEventListener('click', closeGuide)
guideDialog.addEventListener('cancel', e => { e.preventDefault(); closeGuide() })
document.querySelectorAll<HTMLButtonElement>('.sound-button').forEach(button => {
  button.addEventListener('click', () => {
    game.muted = !game.muted
    button.innerHTML = icon(game.muted ? 'mute' : 'volume')
    button.setAttribute('aria-label', game.muted ? 'Enable sound' : 'Mute sound')
  })
})
element<HTMLInputElement>('sensitivity').addEventListener('input', e => { game.sensitivity = Number((e.target as HTMLInputElement).value) })
element('touch-fire').addEventListener('pointerdown', e => { e.preventDefault(); game.shoot() })
element('touch-reload').addEventListener('pointerdown', e => { e.preventDefault(); game.reload() })
element('touch-interact').addEventListener('pointerdown', e => { e.preventDefault(); game.interact() })
element('touch-barricade').addEventListener('pointerdown', e => { e.preventDefault(); game.repairDoor() })
const joystick = element('joystick')
let joystickId: number | null = null
function moveJoystick(e: PointerEvent) {
  const bounds = joystick.getBoundingClientRect()
  let x = (e.clientX - bounds.left - bounds.width / 2) / 34
  let z = (e.clientY - bounds.top - bounds.height / 2) / 34
  const length = Math.hypot(x, z)
  if (length > 1) { x /= length; z /= length }
  game.setTouchMove(x, z)
  joystick.querySelector('i')!.style.transform = `translate(${x * 30}px, ${z * 30}px)`
}
joystick.addEventListener('pointerdown', e => { e.preventDefault(); joystickId = e.pointerId; joystick.setPointerCapture(e.pointerId); moveJoystick(e) })
joystick.addEventListener('pointermove', e => { if (e.pointerId === joystickId) moveJoystick(e) })
function releaseJoystick() { joystickId = null; game.setTouchMove(0, 0); joystick.querySelector('i')!.style.transform = '' }
joystick.addEventListener('pointerup', releaseJoystick)
joystick.addEventListener('pointercancel', releaseJoystick)
