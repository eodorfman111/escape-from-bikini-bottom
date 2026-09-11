export type MusicMood = 'menu' | 'explore' | 'home' | 'combat' | 'danger' | 'won' | 'lost'

type Harmony = readonly [number, number, number, number]

interface Arrangement {
  readonly bpm: number
  readonly progression: readonly Harmony[]
  readonly bars: number
  readonly oneShot?: boolean
}

interface Layer {
  readonly mood: MusicMood
  readonly input: GainNode
  readonly output: GainNode
  readonly nodes: AudioNode[]
  readonly sources: Set<AudioScheduledSourceNode>
  step: number
  nextTime: number
  retiringAt: number | null
}

const LOOKAHEAD_SECONDS = 0.18
const TICK_MILLISECONDS = 30
const CROSSFADE_SECONDS = 0.7

const arrangements: Record<MusicMood, Arrangement> = {
  menu: {
    bpm: 94,
    progression: [[62, 66, 69, 73], [59, 62, 66, 69], [55, 59, 62, 66], [57, 61, 64, 67]],
    bars: 4,
  },
  explore: {
    bpm: 106,
    progression: [
      [62, 66, 69, 71], [59, 62, 66, 69], [55, 59, 62, 66], [57, 61, 64, 66],
      [62, 66, 69, 71], [64, 67, 71, 74], [55, 59, 62, 66], [57, 61, 64, 67],
    ],
    bars: 8,
  },
  home: {
    bpm: 88,
    progression: [[55, 59, 62, 66], [54, 57, 62, 66], [52, 55, 59, 62], [48, 52, 55, 59]],
    bars: 4,
  },
  combat: {
    bpm: 122,
    progression: [[59, 62, 66, 71], [55, 59, 62, 67], [50, 54, 57, 62], [57, 61, 64, 69]],
    bars: 4,
  },
  danger: {
    bpm: 136,
    progression: [[59, 62, 66, 71], [60, 64, 67, 72], [55, 59, 62, 67], [54, 58, 61, 66]],
    bars: 4,
  },
  won: {
    bpm: 116,
    progression: [[62, 66, 69, 74], [55, 59, 62, 67], [62, 66, 69, 74]],
    bars: 3,
    oneShot: true,
  },
  lost: {
    bpm: 76,
    progression: [[59, 62, 66, 71], [55, 58, 62, 67], [54, 58, 61, 66]],
    bars: 3,
    oneShot: true,
  },
}

const melodies: Record<'menu' | 'explore' | 'home', readonly (number | null)[]> = {
  menu: [74, null, 78, null, 76, null, 73, null, 71, null, 73, null, 69, null, 73, null],
  explore: [
    74, null, 78, 76, null, 73, 71, null, 69, 71, 73, null, 74, null, 69, null,
    71, null, 74, 78, null, 76, 73, null, 71, 73, 69, null, 66, null, 69, null,
    74, null, 78, 81, null, 78, 76, null, 74, 76, 73, null, 71, null, 69, null,
    71, null, 73, 74, null, 78, 76, null, 73, 71, 69, null, 66, null, 69, null,
  ],
  home: [71, null, null, 74, null, null, 71, null, 69, null, null, 66, null, null, 69, null],
}

const midiFrequency = (note: number) => 440 * 2 ** ((note - 69) / 12)

export class Soundtrack {
  private context: AudioContext | null = null
  private master: GainNode | null = null
  private compressor: DynamicsCompressorNode | null = null
  private noise: AudioBuffer | null = null
  private impulse: AudioBuffer | null = null
  private pluckWave: PeriodicWave | null = null
  private layers: Layer[] = []
  private activeLayer: Layer | null = null
  private timer: ReturnType<typeof setInterval> | null = null
  private mood: MusicMood = 'menu'
  private volume = 0.65
  private muted = false
  private paused = false
  private disposed = false
  private unavailable = false
  private failureReported = false
  private pendingSuspend: Promise<void> | null = null

  async start(): Promise<void> {
    if (this.disposed || this.unavailable) return
    this.paused = false

    try {
      if (!this.context) this.createAudioGraph()
      const context = this.context
      if (!context) return
      if (this.pendingSuspend) await this.pendingSuspend
      if (this.disposed || context.state === 'closed') return
      if (context.state !== 'running') await context.resume()
      if (this.disposed) return
      if (this.paused) {
        await context.suspend()
        return
      }
      if (!this.activeLayer) this.changeArrangement(this.mood)
      this.startScheduler()
    } catch (error) {
      this.reportFailure(error)
    }
  }

  setMood(mood: MusicMood): void {
    if (this.disposed || this.mood === mood) return
    this.mood = mood
    if (this.context && this.master && !this.unavailable) {
      try {
        this.changeArrangement(mood)
        if (!this.paused) this.startScheduler()
      } catch (error) {
        this.reportFailure(error)
      }
    }
  }

  setVolume(value: number): void {
    this.volume = Number.isFinite(value) ? Math.min(1, Math.max(0, value)) : 0
    this.updateMasterGain()
  }

  setMuted(muted: boolean): void {
    this.muted = muted
    this.updateMasterGain()
  }

  pause(): void {
    if (this.disposed || this.paused) return
    this.paused = true
    this.stopScheduler()
    if (this.context?.state === 'running') {
      const pending = this.context.suspend().catch(error => {
        if (!this.disposed) this.reportFailure(error)
      })
      this.pendingSuspend = pending
      void pending.then(() => {
        if (this.pendingSuspend === pending) this.pendingSuspend = null
      })
    }
  }

  async resume(): Promise<void> {
    if (this.disposed || this.unavailable) return
    this.paused = false
    if (!this.context) {
      await this.start()
      return
    }

    try {
      if (this.pendingSuspend) await this.pendingSuspend
      const context = this.context
      if (this.disposed || !context || context.state === 'closed') return
      if (context.state !== 'running') await context.resume()
      if (this.disposed) return
      if (this.paused) {
        await context.suspend()
        return
      }
      if (!this.activeLayer) this.changeArrangement(this.mood)
      if (this.activeLayer) {
        this.activeLayer.nextTime = Math.max(this.activeLayer.nextTime, context.currentTime + 0.04)
      }
      this.startScheduler()
    } catch (error) {
      this.reportFailure(error)
    }
  }

  dispose(): void {
    if (this.disposed) return
    this.disposed = true
    this.stopScheduler()
    for (const layer of this.layers) this.destroyLayer(layer)
    this.layers = []
    this.activeLayer = null
    this.master?.disconnect()
    this.compressor?.disconnect()
    const context = this.context
    this.context = null
    this.master = null
    this.compressor = null
    this.noise = null
    this.impulse = null
    this.pluckWave = null
    this.pendingSuspend = null
    if (context && context.state !== 'closed') {
      void context.close().catch(() => undefined)
    }
  }

  private createAudioGraph(): void {
    const context = new AudioContext({ latencyHint: 'interactive' })
    this.context = context
    const master = context.createGain()
    const compressor = context.createDynamicsCompressor()
    compressor.threshold.value = -18
    compressor.knee.value = 16
    compressor.ratio.value = 5
    compressor.attack.value = 0.008
    compressor.release.value = 0.22
    master.gain.value = this.muted ? 0 : this.volume
    master.connect(compressor)
    compressor.connect(context.destination)

    const noise = context.createBuffer(1, Math.ceil(context.sampleRate * 0.45), context.sampleRate)
    const channel = noise.getChannelData(0)
    for (let i = 0; i < channel.length; i++) {
      channel[i] = Math.random() * 2 - 1
    }

    this.master = master
    this.compressor = compressor
    this.noise = noise
    this.pluckWave = context.createPeriodicWave(
      new Float32Array([0, 0, 0, 0, 0, 0]),
      new Float32Array([0, 1, 0.44, 0.21, 0.1, 0.045]),
    )
  }

  private updateMasterGain(): void {
    if (!this.context || !this.master || this.context.state === 'closed') return
    const now = this.context.currentTime
    const gain = this.master.gain
    gain.cancelScheduledValues(now)
    gain.setTargetAtTime(this.muted ? 0 : this.volume, now, 0.025)
  }

  private createLayer(mood: MusicMood, startTime: number): Layer {
    const context = this.context
    const master = this.master
    if (!context || !master) throw new Error('Audio graph has not been initialized')

    const input = context.createGain()
    const dry = context.createGain()
    const send = context.createGain()
    const reverb = context.createConvolver()
    const reverbTone = context.createBiquadFilter()
    const output = context.createGain()

    dry.gain.value = mood === 'combat' || mood === 'danger' ? 0.88 : 0.78
    send.gain.value = mood === 'home' ? 0.31 : mood === 'won' || mood === 'lost' ? 0.27 : 0.2
    reverb.buffer = this.createImpulse()
    reverbTone.type = 'lowpass'
    reverbTone.frequency.value = mood === 'danger' ? 3200 : 4100
    output.gain.setValueAtTime(0, startTime)
    output.gain.linearRampToValueAtTime(1, startTime + CROSSFADE_SECONDS)

    input.connect(dry)
    dry.connect(output)
    input.connect(send)
    send.connect(reverb)
    reverb.connect(reverbTone)
    reverbTone.connect(output)
    output.connect(master)

    return {
      mood,
      input,
      output,
      nodes: [input, dry, send, reverb, reverbTone, output],
      sources: new Set(),
      step: 0,
      nextTime: startTime,
      retiringAt: null,
    }
  }

  private createImpulse(): AudioBuffer {
    if (this.impulse) return this.impulse
    const context = this.context
    if (!context) throw new Error('Audio context is unavailable')
    const length = Math.ceil(context.sampleRate * 1.25)
    const impulse = context.createBuffer(2, length, context.sampleRate)
    for (let channel = 0; channel < impulse.numberOfChannels; channel++) {
      const data = impulse.getChannelData(channel)
      for (let i = 0; i < length; i++) {
        const decay = (1 - i / length) ** 2.6
        data[i] = (Math.random() * 2 - 1) * decay
      }
    }
    this.impulse = impulse
    return impulse
  }

  private changeArrangement(mood: MusicMood): void {
    const context = this.context
    if (!context) return
    const now = context.currentTime
    const startTime = now + 0.035
    if (this.activeLayer) {
      const oldLayer = this.activeLayer
      const gain = oldLayer.output.gain
      gain.cancelAndHoldAtTime(now)
      gain.linearRampToValueAtTime(0, now + CROSSFADE_SECONDS)
      oldLayer.retiringAt = now + CROSSFADE_SECONDS + 1.3
    }

    const layer = this.createLayer(mood, startTime)
    this.layers.push(layer)
    this.activeLayer = layer
    this.schedulerTick()
  }

  private startScheduler(): void {
    if (this.timer || this.paused || this.disposed || !this.context) return
    this.schedulerTick()
    if (this.unavailable || !this.context || this.activeThemeComplete()) return
    this.timer = setInterval(() => this.schedulerTick(), TICK_MILLISECONDS)
  }

  private stopScheduler(): void {
    if (!this.timer) return
    clearInterval(this.timer)
    this.timer = null
  }

  private schedulerTick(): void {
    const context = this.context
    if (!context || this.disposed || this.paused || context.state === 'closed') return

    try {
      const now = context.currentTime
      for (const layer of [...this.layers]) {
        if (layer.retiringAt !== null) {
          if (now >= layer.retiringAt) this.removeLayer(layer)
          continue
        }

        const arrangement = arrangements[layer.mood]
        const stepDuration = 60 / arrangement.bpm / 4
        const lastStep = arrangement.bars * 16
        if (layer.nextTime < now - stepDuration) {
          const skippedSteps = Math.ceil((now - layer.nextTime) / stepDuration)
          layer.step += skippedSteps
          layer.nextTime += skippedSteps * stepDuration
        }
        while (layer.nextTime < now + LOOKAHEAD_SECONDS) {
          if (!arrangement.oneShot || layer.step < lastStep) {
            this.scheduleStep(layer, arrangement, layer.step, layer.nextTime, stepDuration)
          }
          layer.step++
          layer.nextTime += stepDuration
          if (arrangement.oneShot && layer.step >= lastStep) break
        }
      }
      if (this.activeThemeComplete()) this.stopScheduler()
    } catch (error) {
      this.reportFailure(error)
      this.stopScheduler()
    }
  }

  private activeThemeComplete(): boolean {
    const layer = this.activeLayer
    if (!layer || this.layers.some(candidate => candidate.retiringAt !== null)) return false
    const arrangement = arrangements[layer.mood]
    return arrangement.oneShot === true && layer.step >= arrangement.bars * 16
  }

  private scheduleStep(
    layer: Layer,
    arrangement: Arrangement,
    absoluteStep: number,
    time: number,
    stepDuration: number,
  ): void {
    const loopStep = absoluteStep % (arrangement.bars * 16)
    const bar = Math.floor(loopStep / 16)
    const step = loopStep % 16
    const harmony = arrangement.progression[bar % arrangement.progression.length]
    const root = harmony[0]

    switch (layer.mood) {
      case 'menu':
        if (step % 4 === 0) this.pluck(layer, harmony[(step / 4) % 4] + 12, time, stepDuration * 2.7, 0.07)
        if (step === 0 || step === 8) this.bass(layer, root - 12, time, stepDuration * 3, 0.065)
        if (step % 2 === 0) this.shaker(layer, time, 0.016, step === 6 || step === 14)
        this.scheduleMelody(layer, melodies.menu, loopStep, time, stepDuration, 0.045)
        break
      case 'explore':
        if (step % 2 === 0) {
          const arpeggio = [0, 1, 2, 1, 3, 2, 1, 2]
          this.marimba(layer, harmony[arpeggio[step / 2]], time, stepDuration * 1.45, step % 4 === 0 ? 0.105 : 0.078)
        }
        if (step === 0 || step === 6 || step === 10 || step === 14) {
          this.bass(layer, step === 6 || step === 14 ? harmony[2] - 24 : root - 12, time, stepDuration * 1.8, 0.085)
        }
        if (step === 0 || step === 8) this.kick(layer, time, step === 0 ? 0.13 : 0.09)
        if (step === 4 || step === 12) this.woodblock(layer, time, step === 12 ? 0.055 : 0.045)
        if (step % 2 === 0) this.shaker(layer, time, step % 4 === 0 ? 0.018 : 0.026, step === 6 || step === 14)
        this.scheduleMelody(layer, melodies.explore, loopStep, time, stepDuration, 0.072)
        break
      case 'home':
        if (step % 4 === 0) this.pluck(layer, harmony[(step / 4 + bar) % 4] + 12, time, stepDuration * 3.4, 0.052)
        if (step === 0 || step === 10) this.bass(layer, root - 12, time, stepDuration * 3.7, 0.045)
        if (step === 0) this.marimba(layer, harmony[2], time, stepDuration * 3, 0.04)
        if (step === 6 || step === 14) this.shaker(layer, time, 0.012, true)
        this.scheduleMelody(layer, melodies.home, loopStep, time, stepDuration, 0.038)
        break
      case 'combat':
        this.scheduleCombat(layer, harmony, step, time, stepDuration, false)
        break
      case 'danger':
        this.scheduleCombat(layer, harmony, step, time, stepDuration, true)
        break
      case 'won':
        this.scheduleWon(layer, harmony, bar, step, time, stepDuration)
        break
      case 'lost':
        this.scheduleLost(layer, harmony, bar, step, time, stepDuration)
        break
    }
  }

  private scheduleMelody(
    layer: Layer,
    melody: readonly (number | null)[],
    step: number,
    time: number,
    stepDuration: number,
    level: number,
  ): void {
    const note = melody[step % melody.length]
    if (note !== null) this.flute(layer, note, time, stepDuration * 2.5, level)
  }

  private scheduleCombat(
    layer: Layer,
    harmony: Harmony,
    step: number,
    time: number,
    stepDuration: number,
    danger: boolean,
  ): void {
    const pattern = danger ? [0, 2, 1, 3, 0, 2, 3, 1] : [0, 1, 2, 1, 0, 3, 2, 1]
    this.pluck(layer, harmony[pattern[step % 8]] + (danger && step % 4 === 3 ? 12 : 0), time, stepDuration * 0.72, danger ? 0.082 : 0.067)
    if (step === 0 || step === 8 || (danger && step === 11)) this.kick(layer, time, danger ? 0.19 : 0.15)
    if (step === 4 || step === 12) this.snare(layer, time, danger ? 0.095 : 0.07)
    if (step % 2 === 0 || danger) this.shaker(layer, time, danger ? 0.035 : 0.025, step % 4 === 2)
    if (step === 0 || step === 6 || step === 8 || step === 14) {
      const bassNote = step === 6 || step === 14 ? harmony[2] - 24 : harmony[0] - 12
      this.bass(layer, bassNote, time, stepDuration * 1.55, danger ? 0.12 : 0.1)
    }
    if (danger && (step === 3 || step === 7 || step === 15)) {
      this.woodblock(layer, time, 0.075)
    }
  }

  private scheduleWon(
    layer: Layer,
    harmony: Harmony,
    bar: number,
    step: number,
    time: number,
    stepDuration: number,
  ): void {
    const fanfare = [74, 78, 81, 86, 83, 81, 78, 86]
    if (bar < 2 && step % 4 === 0) {
      const note = fanfare[bar * 4 + step / 4]
      this.flute(layer, note, time, stepDuration * 2.2, 0.09)
      this.marimba(layer, harmony[(step / 4) % 4], time, stepDuration * 2.8, 0.08)
    }
    if (bar === 2 && step === 0) {
      for (const note of harmony) this.pluck(layer, note + 12, time, stepDuration * 12, 0.055)
      this.flute(layer, 86, time, stepDuration * 10, 0.1)
    }
    if (step === 0 || step === 8) this.kick(layer, time, 0.11)
    if (step === 4 || step === 12) this.woodblock(layer, time, 0.045)
  }

  private scheduleLost(
    layer: Layer,
    harmony: Harmony,
    bar: number,
    step: number,
    time: number,
    stepDuration: number,
  ): void {
    const phrase = [71, 69, 66, 62, 59, 57, 55, 54]
    if (step % 4 === 0 && bar < 2) {
      const note = phrase[bar * 4 + step / 4]
      this.flute(layer, note, time, stepDuration * 3.6, 0.047)
      this.pluck(layer, harmony[(step / 4) % 4] + 12, time, stepDuration * 3.3, 0.038)
    }
    if (bar === 2 && step === 0) {
      this.bass(layer, harmony[0] - 12, time, stepDuration * 11, 0.055)
      for (const note of harmony) this.pluck(layer, note + 12, time, stepDuration * 10, 0.025)
    }
  }

  private pluck(layer: Layer, note: number, time: number, duration: number, level: number): void {
    const context = this.context
    if (!context || !this.pluckWave) return
    const oscillator = context.createOscillator()
    const filter = context.createBiquadFilter()
    const envelope = context.createGain()
    const pan = context.createStereoPanner()
    oscillator.setPeriodicWave(this.pluckWave)
    oscillator.frequency.setValueAtTime(midiFrequency(note), time)
    filter.type = 'lowpass'
    filter.Q.value = 2.4
    filter.frequency.setValueAtTime(3400, time)
    filter.frequency.exponentialRampToValueAtTime(720, time + duration)
    envelope.gain.setValueAtTime(0.0001, time)
    envelope.gain.exponentialRampToValueAtTime(level, time + 0.012)
    envelope.gain.exponentialRampToValueAtTime(0.0001, time + duration)
    pan.pan.value = ((note % 5) - 2) * 0.08
    oscillator.connect(filter)
    filter.connect(envelope)
    envelope.connect(pan)
    pan.connect(layer.input)
    this.runVoice(layer, [oscillator], [filter, envelope, pan], time, duration + 0.03)
  }

  private marimba(layer: Layer, note: number, time: number, duration: number, level: number): void {
    const context = this.context
    if (!context) return
    const fundamental = context.createOscillator()
    const overtone = context.createOscillator()
    const fundamentalGain = context.createGain()
    const overtoneGain = context.createGain()
    const envelope = context.createGain()
    const pan = context.createStereoPanner()
    const frequency = midiFrequency(note)
    fundamental.type = 'sine'
    overtone.type = 'sine'
    fundamental.frequency.setValueAtTime(frequency, time)
    overtone.frequency.setValueAtTime(frequency * 3.98, time)
    fundamentalGain.gain.value = 0.85
    overtoneGain.gain.value = 0.18
    envelope.gain.setValueAtTime(0.0001, time)
    envelope.gain.exponentialRampToValueAtTime(level, time + 0.008)
    envelope.gain.exponentialRampToValueAtTime(0.0001, time + duration)
    pan.pan.value = ((note % 7) - 3) * 0.055
    fundamental.connect(fundamentalGain)
    overtone.connect(overtoneGain)
    fundamentalGain.connect(envelope)
    overtoneGain.connect(envelope)
    envelope.connect(pan)
    pan.connect(layer.input)
    this.runVoice(layer, [fundamental, overtone], [fundamentalGain, overtoneGain, envelope, pan], time, duration + 0.02)
  }

  private flute(layer: Layer, note: number, time: number, duration: number, level: number): void {
    const context = this.context
    if (!context) return
    const oscillator = context.createOscillator()
    const vibrato = context.createOscillator()
    const vibratoDepth = context.createGain()
    const filter = context.createBiquadFilter()
    const envelope = context.createGain()
    oscillator.type = 'triangle'
    oscillator.frequency.setValueAtTime(midiFrequency(note), time)
    vibrato.type = 'sine'
    vibrato.frequency.value = 5.2
    vibratoDepth.gain.setValueAtTime(0, time)
    vibratoDepth.gain.linearRampToValueAtTime(3.2, time + Math.min(0.22, duration * 0.4))
    filter.type = 'lowpass'
    filter.frequency.value = 3600
    filter.Q.value = 0.5
    envelope.gain.setValueAtTime(0.0001, time)
    envelope.gain.linearRampToValueAtTime(level, time + Math.min(0.055, duration * 0.2))
    envelope.gain.setValueAtTime(level * 0.82, Math.max(time + 0.06, time + duration * 0.62))
    envelope.gain.exponentialRampToValueAtTime(0.0001, time + duration)
    vibrato.connect(vibratoDepth)
    vibratoDepth.connect(oscillator.detune)
    oscillator.connect(filter)
    filter.connect(envelope)
    envelope.connect(layer.input)
    this.runVoice(layer, [oscillator, vibrato], [vibratoDepth, filter, envelope], time, duration + 0.03)
  }

  private bass(layer: Layer, note: number, time: number, duration: number, level: number): void {
    const context = this.context
    if (!context) return
    const oscillator = context.createOscillator()
    const filter = context.createBiquadFilter()
    const envelope = context.createGain()
    oscillator.type = 'triangle'
    oscillator.frequency.setValueAtTime(midiFrequency(note), time)
    filter.type = 'lowpass'
    filter.frequency.value = 520
    filter.Q.value = 1.1
    envelope.gain.setValueAtTime(0.0001, time)
    envelope.gain.exponentialRampToValueAtTime(level, time + 0.018)
    envelope.gain.setValueAtTime(level * 0.72, time + duration * 0.48)
    envelope.gain.exponentialRampToValueAtTime(0.0001, time + duration)
    oscillator.connect(filter)
    filter.connect(envelope)
    envelope.connect(layer.input)
    this.runVoice(layer, [oscillator], [filter, envelope], time, duration + 0.025)
  }

  private kick(layer: Layer, time: number, level: number): void {
    const context = this.context
    if (!context) return
    const oscillator = context.createOscillator()
    const envelope = context.createGain()
    oscillator.type = 'sine'
    oscillator.frequency.setValueAtTime(118, time)
    oscillator.frequency.exponentialRampToValueAtTime(48, time + 0.16)
    envelope.gain.setValueAtTime(level, time)
    envelope.gain.exponentialRampToValueAtTime(0.0001, time + 0.2)
    oscillator.connect(envelope)
    envelope.connect(layer.input)
    this.runVoice(layer, [oscillator], [envelope], time, 0.21)
  }

  private woodblock(layer: Layer, time: number, level: number): void {
    const context = this.context
    if (!context) return
    const oscillator = context.createOscillator()
    const filter = context.createBiquadFilter()
    const envelope = context.createGain()
    oscillator.type = 'sine'
    oscillator.frequency.value = 710
    filter.type = 'bandpass'
    filter.frequency.value = 780
    filter.Q.value = 5
    envelope.gain.setValueAtTime(level, time)
    envelope.gain.exponentialRampToValueAtTime(0.0001, time + 0.065)
    oscillator.connect(filter)
    filter.connect(envelope)
    envelope.connect(layer.input)
    this.runVoice(layer, [oscillator], [filter, envelope], time, 0.07)
  }

  private shaker(layer: Layer, time: number, level: number, accent: boolean): void {
    const context = this.context
    if (!context || !this.noise) return
    const source = context.createBufferSource()
    const filter = context.createBiquadFilter()
    const envelope = context.createGain()
    source.buffer = this.noise
    filter.type = 'highpass'
    filter.frequency.value = accent ? 5200 : 6500
    envelope.gain.setValueAtTime(accent ? level * 1.25 : level, time)
    envelope.gain.exponentialRampToValueAtTime(0.0001, time + (accent ? 0.085 : 0.045))
    source.connect(filter)
    filter.connect(envelope)
    envelope.connect(layer.input)
    this.runVoice(layer, [source], [filter, envelope], time, accent ? 0.09 : 0.05)
  }

  private snare(layer: Layer, time: number, level: number): void {
    const context = this.context
    if (!context || !this.noise) return
    const source = context.createBufferSource()
    const filter = context.createBiquadFilter()
    const envelope = context.createGain()
    source.buffer = this.noise
    filter.type = 'bandpass'
    filter.frequency.value = 1800
    filter.Q.value = 0.7
    envelope.gain.setValueAtTime(level, time)
    envelope.gain.exponentialRampToValueAtTime(0.0001, time + 0.13)
    source.connect(filter)
    filter.connect(envelope)
    envelope.connect(layer.input)
    this.runVoice(layer, [source], [filter, envelope], time, 0.14)
  }

  private runVoice(
    layer: Layer,
    sources: AudioScheduledSourceNode[],
    nodes: AudioNode[],
    startTime: number,
    duration: number,
  ): void {
    for (const source of sources) {
      layer.sources.add(source)
      source.start(startTime)
      source.stop(startTime + duration)
    }
    const cleanup = () => {
      for (const source of sources) {
        layer.sources.delete(source)
        source.disconnect()
      }
      for (const node of nodes) node.disconnect()
    }
    sources[0].addEventListener('ended', cleanup, { once: true })
  }

  private removeLayer(layer: Layer): void {
    this.destroyLayer(layer)
    this.layers = this.layers.filter(candidate => candidate !== layer)
  }

  private destroyLayer(layer: Layer): void {
    for (const source of layer.sources) {
      try {
        source.stop()
      } catch {
        layer.sources.delete(source)
      }
      source.disconnect()
    }
    layer.sources.clear()
    for (const node of layer.nodes) node.disconnect()
  }

  private reportFailure(error: unknown): void {
    if (!this.failureReported) {
      this.failureReported = true
      console.warn('Soundtrack is unavailable; continuing without music.', error)
    }
    this.unavailable = true
    this.stopScheduler()
    for (const layer of this.layers) this.destroyLayer(layer)
    this.layers = []
    this.activeLayer = null
    this.master?.disconnect()
    this.compressor?.disconnect()
    const context = this.context
    this.context = null
    this.master = null
    this.compressor = null
    this.noise = null
    this.impulse = null
    this.pluckWave = null
    this.pendingSuspend = null
    if (context && context.state !== 'closed') void context.close().catch(() => undefined)
  }
}
