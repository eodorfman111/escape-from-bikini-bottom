import * as T from 'three'
import { frameCorners } from 'three/addons/utils/CameraUtils.js'
import type { Point } from './rules'
import type { Location, Portal, World } from './world'
import { waterStrength } from './surfaces'

export type Threshold = Pick<Portal, 'at' | 'normal' | 'width'>

export function thresholdDistance(p: Point, portal: Threshold) {
  return (p.x - portal.at.x) * portal.normal.x + (p.z - portal.at.z) * portal.normal.z
}

export function crossesThreshold(before: Point, after: Point, portal: Threshold, radius = 0.38) {
  const a = thresholdDistance(before, portal), b = thresholdDistance(after, portal)
  if (a <= 0 || b > 0 || a === b) return false
  const t = a / (a - b)
  const x = before.x + (after.x - before.x) * t - portal.at.x
  const z = before.z + (after.z - before.z) * t - portal.at.z
  return Math.abs(x * portal.normal.z - z * portal.normal.x) < portal.width / 2 - radius
}

export function portalRotation(source: Threshold, destination: Threshold) {
  return Math.atan2(destination.normal.x, destination.normal.z) - Math.atan2(source.normal.x, source.normal.z) + Math.PI
}

export function throughPortal(position: Point, source: Threshold, destination: Threshold): Point {
  const angle = portalRotation(source, destination), x = position.x - source.at.x, z = position.z - source.at.z
  return {
    x: destination.at.x + x * Math.cos(angle) + z * Math.sin(angle),
    z: destination.at.z - x * Math.sin(angle) + z * Math.cos(angle),
  }
}

export class DoorwayViews {
  private scene = new T.Scene()
  private camera = new T.PerspectiveCamera(65, 1, 0.02, 230)
  private hemisphere = new T.HemisphereLight('#b9ece4', '#9b8656', 2.4)
  private sun = new T.DirectionalLight('#ffe1a3', 3.6)
  private targets = new Map<Portal, T.WebGLRenderTarget>()
  constructor() {
    this.sun.position.set(-25, 45, 30)
    this.scene.add(this.hemisphere, this.sun)
    this.scene.background = new T.Color('#65b3bc')
  }

  render(renderer: T.WebGLRenderer, eye: T.PerspectiveCamera, world: World, getWorld: (location: Location) => World, actors: { body: T.Group; location: Location }[]) {
    const previousStrength = waterStrength.value
    const previousTarget = renderer.getRenderTarget()
    const candidates = world.portals.filter(p => {
      const d = thresholdDistance(eye.position, p)
      return d > 0.003 && d < 26 && eye.position.distanceTo(p.screen.position) < 30
    }).sort((a, b) => eye.position.distanceToSquared(a.screen.position) - eye.position.distanceToSquared(b.screen.position)).slice(0, 2)
    for (const portal of candidates) {
      const destination = getWorld(portal.target)
      const exit = destination.portals.find(p => p.id === portal.exitId)
      if (!exit) continue
      const position = throughPortal(eye.position, portal, exit)
      this.camera.position.set(position.x, eye.position.y, position.z)
      this.camera.near = Math.max(0.003, thresholdDistance(eye.position, portal) + 0.002)
      const corner = (x: number, y: number) => {
        const p = throughPortal({ x: portal.at.x + portal.normal.z * x, z: portal.at.z - portal.normal.x * x }, portal, exit)
        return new T.Vector3(p.x, y, p.z)
      }
      frameCorners(this.camera, corner(-portal.width / 2, 0), corner(portal.width / 2, 0), corner(-portal.width / 2, portal.height))
      this.camera.updateMatrixWorld(true)
      let target = this.targets.get(portal)
      if (!target) {
        target = new T.WebGLRenderTarget(512, 640, { type: T.HalfFloatType })
        this.targets.set(portal, target)
        portal.screen.material.map = target.texture
        portal.screen.material.color.set('#ffffff')
        portal.screen.material.toneMapped = true
        portal.screen.material.needsUpdate = true
      }
      const outdoors = portal.target === 'street' || portal.target === 'roof'
      this.scene.fog = outdoors ? new T.FogExp2('#65b3bc', 0.0065) : null
      this.hemisphere.intensity = outdoors ? 2.4 : 3.3
      this.sun.intensity = outdoors ? 3.6 : 0.65
      waterStrength.value = outdoors ? 1 : 0.13
      this.scene.add(destination.root)
      const visible = exit.screen.visible
      exit.screen.visible = false
      const visitors = actors.filter(a => a.location === portal.target).map(a => ({ body: a.body, parent: a.body.parent, visible: a.body.visible }))
      for (const visitor of visitors) { this.scene.add(visitor.body); visitor.body.visible = true }
      renderer.setRenderTarget(target)
      renderer.render(this.scene, this.camera)
      destination.root.removeFromParent()
      exit.screen.visible = visible
      for (const visitor of visitors) {
        visitor.body.removeFromParent()
        visitor.parent?.add(visitor.body)
        visitor.body.visible = visitor.visible
      }
    }
    renderer.setRenderTarget(previousTarget)
    waterStrength.value = previousStrength
  }

  dispose() {
    for (const target of this.targets.values()) target.dispose()
    this.targets.clear()
  }
}
