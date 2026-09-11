import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { Soundtrack } from './music'

class FakeAudioParam {
  value = 0
  readonly targets: number[] = []
  readonly ramps: number[] = []
  cancelScheduledValues() {}
  cancelAndHoldAtTime() {}
  setValueAtTime(value: number) {
    this.value = value
    return this
  }
  setTargetAtTime(value: number) {
    this.value = value
    this.targets.push(value)
    return this
  }
  linearRampToValueAtTime(value: number) {
    this.value = value
    this.ramps.push(value)
    return this
  }
  exponentialRampToValueAtTime(value: number) {
    this.value = value
    this.ramps.push(value)
    return this
  }
}

class FakeAudioNode {
  disconnected = false
  connect() {
    return this
  }
  disconnect() {
    this.disconnected = true
  }
}

class FakeGainNode extends FakeAudioNode {
  readonly gain = new FakeAudioParam()
}

class FakeBiquadNode extends FakeAudioNode {
  type = 'lowpass'
  readonly frequency = new FakeAudioParam()
  readonly Q = new FakeAudioParam()
}

class FakeCompressorNode extends FakeAudioNode {
  readonly threshold = new FakeAudioParam()
  readonly knee = new FakeAudioParam()
  readonly ratio = new FakeAudioParam()
  readonly attack = new FakeAudioParam()
  readonly release = new FakeAudioParam()
}

class FakeConvolverNode extends FakeAudioNode {
  buffer: FakeAudioBuffer | null = null
}

class FakeStereoPannerNode extends FakeAudioNode {
  readonly pan = new FakeAudioParam()
}

class FakeSourceNode extends FakeAudioNode {
  starts = 0
  stops = 0
  start() {
    this.starts++
  }
  stop() {
    this.stops++
  }
  addEventListener() {}
}

class FakeOscillatorNode extends FakeSourceNode {
  type = 'sine'
  readonly frequency = new FakeAudioParam()
  readonly detune = new FakeAudioParam()
  setPeriodicWave() {}
}

class FakeBufferSourceNode extends FakeSourceNode {
  buffer: FakeAudioBuffer | null = null
}

class FakeAudioBuffer {
  readonly channels: Float32Array[]
  constructor(readonly numberOfChannels: number, length: number) {
    this.channels = Array.from({ length: numberOfChannels }, () => new Float32Array(length))
  }
  getChannelData(channel: number) {
    return this.channels[channel]
  }
}

class FakeAudioContext {
  static instances: FakeAudioContext[] = []
  static failConstruction = false
  readonly sampleRate = 48000
  readonly destination = new FakeAudioNode()
  readonly gains: FakeGainNode[] = []
  readonly sources: FakeSourceNode[] = []
  currentTime = 1
  state: 'suspended' | 'running' | 'closed' = 'suspended'
  resumeCalls = 0
  suspendCalls = 0
  closeCalls = 0

  constructor() {
    if (FakeAudioContext.failConstruction) throw new Error('Audio is disabled')
    FakeAudioContext.instances.push(this)
  }

  createGain() {
    const gain = new FakeGainNode()
    this.gains.push(gain)
    return gain
  }
  createDynamicsCompressor() {
    return new FakeCompressorNode()
  }
  createBuffer(numberOfChannels: number, length: number) {
    return new FakeAudioBuffer(numberOfChannels, length)
  }
  createPeriodicWave() {
    return {}
  }
  createConvolver() {
    return new FakeConvolverNode()
  }
  createBiquadFilter() {
    return new FakeBiquadNode()
  }
  createStereoPanner() {
    return new FakeStereoPannerNode()
  }
  createOscillator() {
    const source = new FakeOscillatorNode()
    this.sources.push(source)
    return source
  }
  createBufferSource() {
    const source = new FakeBufferSourceNode()
    this.sources.push(source)
    return source
  }
  async resume() {
    this.resumeCalls++
    this.state = 'running'
  }
  async suspend() {
    this.suspendCalls++
    this.state = 'suspended'
  }
  async close() {
    this.closeCalls++
    this.state = 'closed'
  }
}

describe('Soundtrack', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    FakeAudioContext.instances = []
    FakeAudioContext.failConstruction = false
    vi.stubGlobal('AudioContext', FakeAudioContext)
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
    vi.useRealTimers()
  })

  it('starts once and schedules a layered menu arrangement', async () => {
    const soundtrack = new Soundtrack()

    await soundtrack.start()
    await soundtrack.start()

    const context = FakeAudioContext.instances[0]
    expect(FakeAudioContext.instances).toHaveLength(1)
    expect(context.resumeCalls).toBe(1)
    expect(context.sources.length).toBeGreaterThan(3)
    expect(context.sources.every(source => source.starts === 1 && source.stops === 1)).toBe(true)
    expect(vi.getTimerCount()).toBe(1)
    soundtrack.dispose()
  })

  it('crossfades only when the requested mood changes', async () => {
    const soundtrack = new Soundtrack()
    await soundtrack.start()
    const context = FakeAudioContext.instances[0]
    const gainCount = context.gains.length

    soundtrack.setMood('menu')
    expect(context.gains).toHaveLength(gainCount)

    soundtrack.setMood('combat')
    expect(context.gains.length).toBeGreaterThan(gainCount)
    expect(context.gains.some(gain => gain.gain.ramps.includes(0.0001))).toBe(true)
    expect(context.sources.length).toBeGreaterThan(6)
    soundtrack.dispose()
  })

  it('clamps volume, mutes without stopping, and restores the chosen level', async () => {
    const soundtrack = new Soundtrack()
    await soundtrack.start()
    const master = FakeAudioContext.instances[0].gains[0]

    soundtrack.setVolume(2)
    soundtrack.setVolume(0.4)
    soundtrack.setMuted(true)
    soundtrack.setMuted(false)

    expect(master.gain.targets).toEqual([1, 0.4, 0, 0.4])
    expect(vi.getTimerCount()).toBe(1)
    soundtrack.dispose()
  })

  it('suspends scheduling, resumes it, and closes every resource on disposal', async () => {
    const soundtrack = new Soundtrack()
    await soundtrack.start()
    const context = FakeAudioContext.instances[0]

    soundtrack.pause()
    await Promise.resolve()
    expect(context.suspendCalls).toBe(1)
    expect(vi.getTimerCount()).toBe(0)

    await soundtrack.resume()
    expect(context.resumeCalls).toBe(2)
    expect(vi.getTimerCount()).toBe(1)

    soundtrack.dispose()
    await Promise.resolve()
    expect(vi.getTimerCount()).toBe(0)
    expect(context.closeCalls).toBe(1)
    expect(context.sources.every(source => source.stops > 0 && source.disconnected)).toBe(true)
  })

  it('stops its clock after a one-shot ending theme is fully scheduled', async () => {
    const soundtrack = new Soundtrack()
    soundtrack.setMood('won')
    await soundtrack.start()
    const context = FakeAudioContext.instances[0]

    context.currentTime = 20
    vi.advanceTimersByTime(31)

    expect(vi.getTimerCount()).toBe(0)
    soundtrack.dispose()
  })

  it('reports unavailable audio once without rejecting or starting timers', async () => {
    FakeAudioContext.failConstruction = true
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    const soundtrack = new Soundtrack()

    await expect(soundtrack.start()).resolves.toBeUndefined()
    await expect(soundtrack.resume()).resolves.toBeUndefined()

    expect(warning).toHaveBeenCalledOnce()
    expect(vi.getTimerCount()).toBe(0)
    soundtrack.dispose()
  })
})
