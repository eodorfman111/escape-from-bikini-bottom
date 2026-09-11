import * as T from 'three'
import { createCharacter } from './characters'
import type { Avatar } from './characters'

export class AvatarPicker {
  private renderer: T.WebGLRenderer
  private scene = new T.Scene()
  private camera = new T.PerspectiveCamera(32, 1, 0.1, 50)
  private model: T.Group | null = null
  private running = true
  private time = 0
  constructor(private canvas: HTMLCanvasElement) {
    this.renderer = new T.WebGLRenderer({ canvas, alpha: true, antialias: true, powerPreference: 'high-performance' })
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 1.7))
    this.renderer.toneMapping = T.ACESFilmicToneMapping
    this.renderer.toneMappingExposure = 1.25
    this.camera.position.set(0, 2, 8)
    this.camera.lookAt(0, 1.4, 0)
    this.scene.add(new T.HemisphereLight('#d6fff5', '#49382a', 3))
    const key = new T.DirectionalLight('#ffdca3', 4)
    key.position.set(-4, 8, 6)
    this.scene.add(key)
    const rim = new T.PointLight('#67d8ea', 14, 12)
    rim.position.set(4, 3, -3)
    this.scene.add(rim)
    const floor = new T.Mesh(new T.CircleGeometry(2.5, 64), new T.MeshStandardMaterial({ color: '#9fc5a4', roughness: 0.85 }))
    floor.rotation.x = -Math.PI / 2
    floor.position.y = -0.03
    this.scene.add(floor)
    this.select('explorer')
    this.animate()
  }

  select(avatar: Avatar) {
    this.model?.removeFromParent()
    this.model = createCharacter(avatar)
    this.model.position.y = 0
    const scale = avatar === 'patrick' ? 0.84 : avatar === 'squid' ? 0.8 : 1
    this.model.scale.setScalar(scale)
    this.scene.add(this.model)
  }

  setVisible(visible: boolean) {
    this.running = visible
    if (visible) this.animate()
  }

  private animate = () => {
    if (!this.running) return
    requestAnimationFrame(this.animate)
    this.time += 0.012
    if (this.model) {
      this.model.rotation.y = this.time
      this.model.position.y = Math.sin(this.time * 2) * 0.035
    }
    const width = Math.max(1, this.canvas.clientWidth), height = Math.max(1, this.canvas.clientHeight)
    if (this.canvas.width !== Math.round(width * this.renderer.getPixelRatio()) || this.canvas.height !== Math.round(height * this.renderer.getPixelRatio())) {
      this.renderer.setSize(width, height, false)
      this.camera.aspect = width / height
      this.camera.updateProjectionMatrix()
    }
    this.renderer.render(this.scene, this.camera)
  }
}
