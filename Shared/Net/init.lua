local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ### Packages
local Promise = require(ReplicatedStorage.Source.Packages.promise)

-- ### Modules

local cache = {}

local NetShared = {}
function NetShared.Get(namespace: string) : {
	rf: {[string]: RemoteFunction},
	re: {[string]: RemoteEvent},
	ure: {[string]: UnreliableRemoteEvent},
}
	if cache[namespace] ~= nil then return cache[namespace] end
	local namespaceFolder = ReplicatedStorage.Core.Net:WaitForChild(namespace, 2)
	local events = {
		rf = {},
		re = {},
		ure = {},
	}
	for _, child in namespaceFolder:GetChildren() do
		if child:IsA("RemoteEvent") then
			events.re[child.Name] = child
		elseif child:IsA("UnreliableRemoteEvent") then
			events.ure[child.Name] = child
		else
			events.rf[child.Name] = child
		end
	end
	cache[namespace] = events
	return events
end

function NetShared.FireToServer(context: string, ...)
	local splitContext = string.split(context, '.')
	if #splitContext ~= 2 then return warn('Failed to Fire with NET: ', context) end
	local namespace = splitContext[1]
	local re = splitContext[2]
	local net = NetShared.Get(namespace)
	if net == nil then return warn('Failed to get namespace: ', namespace) end

	if net.re[re] == nil then return warn('Failed to get re: ', re) end
	net.re[re]:FireServer(...)
end

function NetShared.InvokeServer(context: string, ...)
	local splitContext = string.split(context, '.')
	if #splitContext ~= 2 then return warn('Failed to Fire with NET: ', context) end
	local namespace = splitContext[1]
	local rf = splitContext[2]
	local net = NetShared.Get(namespace)
	if net == nil then return warn('Failed to get namespace: ', namespace) end

	if net.rf[rf] == nil then return warn('Failed to get rf: ', rf) end
	return net.rf[rf]:InvokeServer(...)
end

function NetShared.InvokeServerP(context: string, ...)
	local args = ...
	return Promise.new(function(resolve, reject, cancel)
		local splitContext = string.split(context, '.')
		if #splitContext ~= 2 then cancel('Failed to Fire with NET: ', context) end
		local namespace = splitContext[1]
		local rf = splitContext[2]
		local net = NetShared.Get(namespace)
		if net == nil then cancel('Failed to get namespace: ', namespace) end
		if net.rf[rf] == nil then cancel('Failed to get rf: ', rf) end

		local success, result = pcall(function()
			return net.rf[rf]:InvokeServer(args)
		end)
		if not success then
			reject(result)
		end
		resolve(result)
	end)
end

function NetShared.FireREToAllClientsExept(re: RemoteEvent, playerBlocked, checkFunc ,...)
	for _, player in Players:GetPlayers() do
		if player == playerBlocked then continue end
		if checkFunc ~= nil then
			if checkFunc(player) ~= true then return end
		end
		re:FireClient(player, ...)
	end
end

return NetShared