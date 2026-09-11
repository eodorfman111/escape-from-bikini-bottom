import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest'
import { buildWorld } from './world'
import type { Location } from './world'
import { collides, findPath, moveWithCollision } from './rules'
import { crossesThreshold, throughPortal } from './portals'

beforeAll(() => {
  vi.stubGlobal('document', {
    createElement: () => ({
      width: 0, height: 0,
      getContext: () => ({ fillRect: vi.fn(), fillText: vi.fn(), font: '', textAlign: '', fillStyle: '' }),
    }),
  })
})
afterAll(() => vi.unstubAllGlobals())

describe('modeled doorway connections', () => {
  it('pairs every doorway with a clear, reachable crossing and arrival', () => {
    const locations: Location[] = ['street', 'sponge0', 'sponge1', 'sponge2', 'roof', 'squid0', 'squid1', 'patrick0']
    const worlds = new Map(locations.map(location => [location, buildWorld(location)]))
    for (const [location, world] of worlds) {
      for (const portal of world.portals) {
        const destination = worlds.get(portal.target)!
        const exit = destination.portals.find(candidate => candidate.id === portal.exitId)!
        const context = `${location}/${portal.id} → ${portal.target}/${portal.exitId}`
        expect(exit, context).toBeDefined()
        expect(exit.target, context).toBe(location)
        expect(exit.exitId, context).toBe(portal.id)
        expect(exit.width, context).toBe(portal.width)
        expect(exit.height, context).toBe(portal.height)
        const before = { x: portal.at.x + portal.normal.x * 0.6, z: portal.at.z + portal.normal.z * 0.6 }
        expect(findPath(world.spawn, before, world.walls, location === 'street' ? 84 : 12).length, context).toBeGreaterThan(0)
        const after = moveWithCollision(before, -portal.normal.x * 0.68, -portal.normal.z * 0.68, world.walls)
        expect(crossesThreshold(before, after, portal), context).toBe(true)
        const arrival = throughPortal(after, portal, exit)
        expect(destination.walls.some(wall => collides(arrival, wall)), context).toBe(false)
      }
    }
  })
})
