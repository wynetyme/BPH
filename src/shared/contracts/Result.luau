--!strict

local Result = {}

export type Ok<T> = { ok: true, value: T }
export type Err = { ok: false, code: string }
export type Result<T> = Ok<T> | Err

function Result.ok<T>(value: T): Ok<T>
	return { ok = true, value = value }
end

function Result.err(code: string): Err
	return { ok = false, code = code }
end

return Result
