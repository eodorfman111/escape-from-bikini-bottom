import * as THREE from 'three'
import { describe, expect, it } from 'vitest'
import { avatars, createCharacter, createFirstPersonRig } from './characters'

function meshes(object: THREE.Object3D) {
  const result: THREE.Mesh[] = []
  object.traverse(child => {
    if (child instanceof THREE.Mesh) result.push(child)
  })
  return result
}

describe('character models', () => {
  it('defines a complete, distinct set of selectable avatars', () => {
    expect(avatars.map(avatar => avatar.id)).toEqual(['explorer', 'sponge', 'patrick', 'squid'])
    expect(new Set(avatars.map(avatar => avatar.color)).size).toBe(avatars.length)
    for (const avatar of avatars) {
      expect(avatar.name.length).toBeGreaterThan(3)
      expect(avatar.description.length).toBeGreaterThan(20)
      expect(avatar.eyeHeight).toBeGreaterThan(1.7)
      expect(avatar.eyeHeight).toBeLessThan(2.3)
    }
  })

  it.each(avatars.map(avatar => avatar.id))('%s is grounded, detailed, and within the actor mesh budget', kind => {
    const actor = createCharacter(kind)
    const actorMeshes = meshes(actor)
    const bounds = new THREE.Box3().setFromObject(actor)

    expect(actor.name).toBe(kind)
    expect(actor.userData.kind).toBe(kind)
    expect(actorMeshes.length).toBeGreaterThan(15)
    expect(actorMeshes.length).toBeLessThan(120)
    expect(bounds.min.y).toBeGreaterThanOrEqual(-0.02)
    expect(bounds.min.y).toBeLessThan(0.03)
    expect(bounds.max.y).toBeGreaterThan(2)
    expect(actorMeshes.every(mesh => mesh.geometry.attributes.position.count > 0)).toBe(true)
  })

  it('reuses cached geometry and materials without sharing transform state', () => {
    const first = createCharacter('sponge')
    const second = createCharacter('sponge')
    const firstBody = first.getObjectByName('body') as THREE.Mesh
    const secondBody = second.getObjectByName('body') as THREE.Mesh

    expect(first).not.toBe(second)
    expect(firstBody).not.toBe(secondBody)
    expect(firstBody.geometry).toBe(secondBody.geometry)
    expect(firstBody.material).toBe(secondBody.material)
    firstBody.position.x = 10
    expect(secondBody.position.x).not.toBe(10)
  })

  it('cycles through varied hostile fish silhouettes', () => {
    const actors = Array.from({ length: 4 }, () => createCharacter('fish'))
    expect(new Set(actors.map(actor => actor.userData.fishVariant)).size).toBe(4)
    for (const actor of actors) {
      expect(meshes(actor).length).toBeLessThan(120)
      expect(new THREE.Box3().setFromObject(actor).min.y).toBeGreaterThanOrEqual(-0.02)
    }
  })
})

describe('first-person rigs', () => {
  it.each(avatars.map(avatar => avatar.id))('%s has a neutral, hideable pistol rig with two hands', kind => {
    const rig = createFirstPersonRig(kind)
    const gun = rig.getObjectByName('pistol')
    const hands = rig.getObjectsByProperty('name', 'first-person-hand')
    const bounds = new THREE.Box3().setFromObject(rig)

    expect(rig.position.toArray()).toEqual([0, 0, 0])
    expect(rig.userData.attachOffset.toArray()).toEqual([0.3, -0.29, -0.62])
    expect(gun).toBeDefined()
    expect(gun!.userData.hideInExploration).toBe(true)
    expect(hands).toHaveLength(2)
    expect(bounds.min.z).toBeLessThan(-0.38)
    expect(bounds.max.z).toBeGreaterThan(0.3)
    expect(gun!.getObjectByName('muzzle')!.position.z)
      .toBeLessThan(gun!.getObjectByName('grip')!.position.z)
    expect(meshes(rig).length).toBeLessThan(80)
    expect(meshes(rig).every(mesh => !mesh.castShadow && !mesh.receiveShadow)).toBe(true)
  })
})
