import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest'
import { buildWorld } from './world'
import type { Location } from './world'
import { collides, findPath } from './rules'

beforeAll(() => {
  vi.stubGlobal('document', {
    createElement: () => ({
      width: 0, height: 0,
      getContext: () => ({ fillRect: vi.fn(), fillText: vi.fn(), font: '', textAlign: '', fillStyle: '' }),
    }),
  })
})
afterAll(() => vi.unstubAllGlobals())

describe('walkable house reconstruction', () => {
  const locations: Location[] = ['street', 'sponge0', 'sponge1', 'sponge2', 'roof', 'squid0', 'squid1', 'patrick0']

  for (const location of locations) {
    it(`${location} has a clear spawn and reachable exits, stairs, and supplies`, () => {
      const world = buildWorld(location)
      expect(world.walls.some(w => collides(world.spawn, w))).toBe(false)
      expect(world.interactions.length).toBeGreaterThan(0)
      for (const interaction of world.interactions) {
        expect(world.walls.some(w => collides(interaction.at, w, 0.32)), interaction.text).toBe(false)
        expect(findPath(world.spawn, interaction.at, world.walls, location === 'street' ? 84 : 10).length, interaction.text).toBeGreaterThan(0)
      }
    })
  }

  it('connects every modeled floor to the street without a dead end', () => {
    const worlds = new Map(locations.map(l => [l, buildWorld(l)]))
    for (const start of locations) {
      const seen = new Set<Location>()
      const pending = [start]
      while (pending.length) {
        const current = pending.shift()!
        if (seen.has(current)) continue
        seen.add(current)
        for (const interaction of worlds.get(current)!.interactions) {
          if (interaction.target) pending.push(interaction.target)
        }
      }
      expect(seen.has('street')).toBe(true)
      expect(seen.size).toBe(locations.length)
    }
  })
})
