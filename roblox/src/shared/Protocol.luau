--!strict
export type Snapshot = {
	coins: number,
	health: number,
	ammo: number,
	capacity: number,
	reloading: boolean,
	weapon: string,
	weapons: { [string]: boolean },
	helpers: { string },
	discoveries: { [string]: boolean },
	discoveryCount: number,
	discoveryTotal: number,
	zone: string,
	wave: number,
	enemies: number,
	phase: string,
	countdown: number,
	ready: boolean,
	survival: boolean,
	message: string,
}
return {}
