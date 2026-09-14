import { describe, expect, it } from 'vitest'
import { CLIP, RELOAD_SECONDS, SurvivalState, collides, findPath, lineClear, moveWithCollision, waveCount } from './rules'

describe('survival progression', () => {
  it('requires every fish in all five waves before victory', () => {
    const state = new SurvivalState('survival')
    let total = 0
    for (let wave = 1; wave <= 5; wave++) {
      state.tick(13)
      expect(state.wave).toBe(wave)
      expect(state.phase).toBe('wave')
      const count = waveCount(wave)
      total += count
      for (let i = 0; i < count - 1; i++) state.defeat()
      expect(state.phase).toBe('wave')
      expect(state.remaining).toBe(1)
      state.defeat()
      expect(state.phase).toBe(wave === 5 ? 'won' : 'rest')
    }
    expect(state.kills).toBe(total)
    state.tick(999)
    expect(state.wave).toBe(5)
    expect(state.phase).toBe('won')
  })

  it('ends at zero health and cannot award progress after death', () => {
    const state = new SurvivalState('survival')
    state.tick(10)
    state.damage(1000)
    state.defeat()
    expect(state.phase).toBe('lost')
    expect(state.health).toBe(0)
    expect(state.kills).toBe(0)
    expect(state.shoot()).toBe(false)
  })

  it('keeps exploration free of damage and waves', () => {
    const state = new SurvivalState('explore')
    state.tick(10000)
    state.damage(1000)
    expect(state.health).toBe(100)
    expect(state.wave).toBe(0)
    expect(state.phase).toBe('ready')
  })
})

describe('pistol and supplies', () => {
  it('enforces cooldown, blocks shots during reload, and conserves ammunition', () => {
    const state = new SurvivalState('survival')
    expect(state.shoot()).toBe(true)
    expect(state.shoot()).toBe(false)
    state.tick(0.24)
    expect(state.shoot()).toBe(true)
    expect(state.reload()).toBe(true)
    expect(state.reload()).toBe(false)
    state.tick(RELOAD_SECONDS / 2)
    expect(state.shoot()).toBe(false)
    state.tick(RELOAD_SECONDS / 2)
    expect(state.clip).toBe(CLIP)
    expect(state.reserve).toBe(82)
    expect(state.reload()).toBe(false)
  })

  it('handles partial reloads with an almost-empty reserve', () => {
    const state = new SurvivalState('survival')
    state.clip = 0
    state.reserve = 3
    expect(state.reload()).toBe(true)
    state.tick(RELOAD_SECONDS)
    expect(state.clip).toBe(3)
    expect(state.reserve).toBe(0)
    expect(state.reload()).toBe(false)
    state.supply()
    expect(state.reserve).toBe(36)
    expect(state.health).toBe(100)
  })
})

describe('movement and navigation', () => {
  const walls = [{ x: 0, z: 0, w: 1, d: 8 }]

  it('prevents tunneling through walls even on a long frame', () => {
    const next = moveWithCollision({ x: -3, z: 0 }, 20, 0, walls)
    expect(next.x).toBeLessThan(-0.8)
    expect(collides(next, walls[0])).toBe(false)
  })

  it('slides along a wall rather than stopping both axes', () => {
    const next = moveWithCollision({ x: -1, z: 0 }, 2, 2, walls)
    expect(next.x).toBeLessThan(-0.8)
    expect(next.z).toBeCloseTo(2)
  })

  it('routes around obstacles, and blocks damage through walls', () => {
    const start = { x: -3, z: 0 }
    const goal = { x: 3, z: 0 }
    expect(lineClear(start, goal, walls)).toBe(false)
    const path = findPath(start, goal, walls, 10)
    expect(path.length).toBeGreaterThan(4)
    expect(path.some(p => Math.abs(p.z) >= 5)).toBe(true)
    expect(path.every(p => !collides(p, walls[0], 0.32))).toBe(true)
    expect(path.at(-1)).toEqual(goal)
  })

  it('returns no path when the target is enclosed', () => {
    const enclosure = [
      { x: 0, z: 0, w: 1, d: 10 },
      { x: -5, z: -5, w: 10, d: 1 },
      { x: -5, z: 5, w: 10, d: 1 },
    ]
    expect(findPath({ x: -3, z: 0 }, { x: 3, z: 0 }, enclosure, 4)).toEqual([])
  })
})
