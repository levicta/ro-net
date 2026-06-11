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
