--!strict
-- Tagged results for pure modules. Codes are stable strings, not player-facing copy.

export type Ok<T> = { ok: true, value: T }
export type Err = { ok: false, code: string }
export type Result<T> = Ok<T> | Err

local Result = {}

function Result.ok<T>(value: T): Ok<T>
	return { ok = true, value = value }
end

function Result.err(code: string): Err
	return { ok = false, code = code }
end

return Result
