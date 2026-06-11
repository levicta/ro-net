--!strict
-- RoNet Types
-- Centralized type definitions for the entire framework.

export type RemoteType = "Event" | "Function"

export type Direction = "incoming" | "outgoing"

export type Context = {
	player: Player?,
	remote: string,
	payload: {any},
	direction: Direction,
}

export type MiddlewareFn = (context: Context, next: () -> any) -> any
export type Middleware = MiddlewareFn | {MiddlewareFn}

export type SchemaEntry = string | { type: string, optional: boolean? }
export type Schema = {SchemaEntry}

export type HandlerEntry = {
	handler: (...any) -> any,
	middleware: {MiddlewareFn},
	connection: RBXScriptConnection?,
}

export type Zone = {
	origin: Vector3,
	radius: number,
}

export type Observable<T> = {
	name: string,
	initialValue: T,
	value: T,
	onChangeCallbacks: {(...any) -> ()},
	connection: RBXScriptConnection?,
	playerAddedConnection: RBXScriptConnection?,
}

export type PlayerObservable<T> = {
	name: string,
	initialValue: T,
	onChangeCallbacks: {(...any) -> ()},
	connection: RBXScriptConnection?,
	playerAddedConnection: RBXScriptConnection?,
	playerRemovingConnection: RBXScriptConnection?,
	_cache: {[number]: any}?,
}

export type TeamObservable<T> = {
	name: string,
	initialValue: T,
	onChangeCallbacks: {(...any) -> ()},
	connection: RBXScriptConnection?,
	teamAddedConnection: RBXScriptConnection?,
	teamRemovedConnection: RBXScriptConnection?,
	playerAddedConnection: RBXScriptConnection?,
	playerRemovingConnection: RBXScriptConnection?,
	_teamValues: {[string]: any}?,
	_teamMembers: {[string]: {Player}}?,
	_playerTeams: {[Player]: Team}?,
	_teamConnections: {[Player]: RBXScriptConnection}?,
}

export type Computed<T> = {
	name: string,
	fn: (...any) -> any,
	dependencies: {any},
	value: T?,
	onChangeCallbacks: {(...any) -> ()},
	connections: {RBXScriptConnection},
	connection: RBXScriptConnection?,
}

export type Channel = {
	name: string,
	members: {[Player]: boolean},
	memberCount: number,
}

export type BatchEvent = {
	name: string,
	args: {any},
}

export type Config = {
	strictMode: boolean?,
	defaultTimeout: number?,
	logLevel: "none" | "warn" | "all"?,
	autoSerialize: boolean?,
}

export type FireOptions = {
	buffer: boolean?,
	maxAge: number?,
	throttle: number?,
}

return nil
