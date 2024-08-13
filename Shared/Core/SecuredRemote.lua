local ReplicatedStorage = game:GetService("ReplicatedStorage")
export type ServerMiddlewareArray<T> = { (player: Player, args: T) -> boolean }

export type ServerChecks<T> = {
	middlewares: ServerMiddlewareArray<T>,
	typeCheck: (args: T) -> boolean
}

export type SecuredRemote<T, R> = {
	new: (remote: RemoteEvent | RemoteFunction) -> SecuredRemote<T, R>,
	Connect: (self: SecuredRemote<T, R>, (player: Player, args: T) -> R) -> RBXScriptConnection,
	AddMiddlewares: (self: SecuredRemote<T, R>, middlewares: ServerMiddlewareArray<T>) -> SecuredRemote<T, R>,
	SetTypeCheck: (self: SecuredRemote<T, R>, typeCheck: (args: any) -> boolean) -> SecuredRemote<T, R>,
	remote: RemoteEvent | RemoteFunction,
	checks: ServerChecks<T>
}

--- ### Classes
local SecuredRemote: SecuredRemote<nil, nil> = {}
SecuredRemote.__index = SecuredRemote

function runChecks(player: Player, checks: ServerChecks<any>, args): boolean
	if not checks.typeCheck(args) then return false end

	for _, fn in checks.middlewares do
		if not fn(player, args) then return false end
	end

	return true
end

function SecuredRemote.new(name, namespace)
	local remote = Instance.new("RemoteEvent")
	local self = setmetatable({
		remote = remote,
		checks = {
			middlewares = {},
			typeCheck = function()
				return true
			end
		}
	}, SecuredRemote)

	if name ~= nil and namespace ~= nil then
		require(ReplicatedStorage.Source.Modules.Core).HandleSecuredRemote(self, namespace, name)
	end

	return self
end

function SecuredRemote:Connect(callback): RBXScriptConnection
	if self.remote:IsA("RemoteEvent") then
		return self.remote.OnServerEvent:Connect(function(player, args)
			if not runChecks(player, self.checks, args) then return end

			callback(player, args)
		end)
	else
		return self.remote:OnServerInvoke(function(player, args)
			if not runChecks(player, self.checks, args) then return end

			return callback(player, args)
		end)
	end
end

function SecuredRemote:AddMiddlewares<T>(middlewares: ServerMiddlewareArray<T>)
	if typeof(middlewares) == "function" then
		middlewares = {middlewares}
	end
	for _, fn in middlewares do
		table.insert(self.checks.middlewares, fn)
	end

	return self
end

function SecuredRemote:SetTypeCheck<T>(typeCheck: (args: T) -> boolean)
	self.checks.typeCheck = typeCheck

	return self
end

return SecuredRemote