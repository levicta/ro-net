// Type definitions for RoNet
// Project: https://github.com/levicta/ro-net
// Definitions by: RoNet Contributors

declare namespace RoNet {
	export type RemoteType = "Event" | "Function";
	export type Direction = "incoming" | "outgoing";

	export interface Context {
		readonly player: Player | undefined;
		readonly remote: string;
		readonly payload: Array<unknown>;
		readonly direction: Direction;
	}

	export type MiddlewareFn = (context: Context, next: () => unknown) => unknown;
	export type Middleware = MiddlewareFn | Array<MiddlewareFn>;

	export type SchemaEntry = string | { type: string; optional?: boolean };
	export type Schema = Array<SchemaEntry>;

	export interface Config {
		strictMode?: boolean;
		defaultTimeout?: number;
		logLevel?: "none" | "warn" | "all";
	}

	export interface Promise<T = unknown> {
		andThen<U>(onFulfilled: (value: T) => U, onRejected?: (reason: string) => U): Promise<U>;
		catch(onRejected: (reason: string) => T): Promise<T>;
		await(): LuaTuple<[boolean, T]>;
	}

	export namespace Middleware {
		function RateLimit(maxPerSecond: number, burstSize?: number): MiddlewareFn;
		function Logger(): MiddlewareFn;
		function Validate(schema: Schema): MiddlewareFn;
		function Auth(checkFn: (player: Player) => boolean): MiddlewareFn;
		function Debounce(cooldown: number): MiddlewareFn;
	}

	export namespace Validator {
		function validate(payload: Array<unknown>, schema: Schema): LuaTuple<[boolean, string | undefined]>;
	}

	export namespace Bindable {
		function on(name: string, handler: (...args: Array<unknown>) => void): void;
		function off(name: string, handler: (...args: Array<unknown>) => void): void;
		function fire(name: string, ...args: Array<unknown>): void;
		function onInvoke(name: string, handler: (...args: Array<unknown>) => unknown): void;
		function invoke<T>(name: string, ...args: Array<unknown>): T | undefined;
	}

	export namespace PromiseStatic {
		function new<T>(executor: (resolve: (value: T) => void, reject: (reason: string) => void) => void): Promise<T>;
		function resolve<T>(value: T): Promise<T>;
		function reject<T>(reason: string): Promise<T>;
	}
}

// Server API
interface RoNetServer {
	readonly Server: RoNetServer;
	readonly Client: never;
	readonly Middleware: typeof RoNet.Middleware;
	readonly Validator: typeof RoNet.Validator;
	readonly Types: typeof RoNet;
	readonly Promise: typeof RoNet.PromiseStatic;
	readonly Bindable: typeof RoNet.Bindable;

	configure(config: RoNet.Config): void;

	on(name: string, handler: (player: Player, ...args: Array<unknown>) => void, middleware?: RoNet.Middleware): RBXScriptConnection;
	off(name: string): void;
	fire(name: string, player: Player, ...args: Array<unknown>): void;
	fireAll(name: string, ...args: Array<unknown>): void;
	fireExcept(name: string, exceptPlayer: Player, ...args: Array<unknown>): void;
	onInvoke(name: string, handler: (player: Player, ...args: Array<unknown>) => unknown, middleware?: RoNet.Middleware): void;
	invoke<T>(name: string, player: Player, ...args: Array<unknown>): T | undefined;
	invokeAsync<T>(name: string, player: Player, timeout?: number, ...args: Array<unknown>): RoNet.Promise<T>;
	define(name: string, remoteType: RoNet.RemoteType): RemoteEvent | RemoteFunction;
	defineMany(definitions: Array<{ name: string; type: RoNet.RemoteType }>): void;
	isDefined(name: string): boolean;
}

// Client API
interface RoNetClient {
	readonly Server: never;
	readonly Client: RoNetClient;
	readonly Middleware: typeof RoNet.Middleware;
	readonly Validator: typeof RoNet.Validator;
	readonly Types: typeof RoNet;
	readonly Promise: typeof RoNet.PromiseStatic;
	readonly Bindable: typeof RoNet.Bindable;

	configure(config: RoNet.Config): void;

	on(name: string, handler: (...args: Array<unknown>) => void, middleware?: RoNet.Middleware): RBXScriptConnection | undefined;
	off(name: string): void;
	fire(name: string, ...args: Array<unknown>): void;
	invoke<T>(name: string, ...args: Array<unknown>): T | undefined;
	invokeAsync<T>(name: string, timeout?: number, ...args: Array<unknown>): RoNet.Promise<T>;
	onInvoke(name: string, handler: (...args: Array<unknown>) => unknown): void;
}

declare const RoNet: RoNetServer | RoNetClient;
export = RoNet;
