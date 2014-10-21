--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

local entityMeta = FindMetaTable("Entity")
local playerMeta = FindMetaTable("Player")

nut.net = nut.net or {}
nut.net.globals = nut.net.globals or {}

function setNetVar(key, value, receiver)
	if (getNetVar(key) == value) then return end

	nut.net.globals[key] = value
	netstream.Start(receiver, "gVar", key, value)
end

function playerMeta:syncVars()
	for entity, data in pairs(nut.net) do
		if (entity == "globals") then
			for k, v in pairs(data) do
				netstream.Start(self, "gVar", k, v)
			end
		elseif (IsValid(entity)) then
			for k, v in pairs(data) do
				netstream.Start(self, "nVar", entity:EntIndex(), k, v)
			end
		end
	end
end

function entityMeta:sendNetVar(key, receiver)
	netstream.Start(receiver, "nVar", self:EntIndex(), key, nut.net[self] and nut.net[self][key])
end

function entityMeta:clearNetVars(receiver)
	nut.net[self] = nil
	netstream.Start(receiver, "nDel", self:EntIndex())
end

function entityMeta:setNetVar(key, value, receiver)
	nut.net[self] = nut.net[self] or {}

	if (nut.net[self][key] != value) then
		nut.net[self][key] = value
	end

	self:sendNetVar(key, receiver)
end

function entityMeta:getNetVar(key, default)
	if (nut.net[self] and nut.net[self][key] != nil) then
		return nut.net[self][key]
	end

	return default
end

function playerMeta:setLocalVar(key, value)
	nut.net[self] = nut.net[self] or {}
	nut.net[self][key] = value

	netstream.Start(self, "nLcl", key, value)
end

playerMeta.getLocalVar = entityMeta.getNetVar

function getNetVar(key, default)
	local value = nut.net.globals[key]

	return value != nil and value or default
end

hook.Add("EntityRemoved", "nCleanUp", function(entity)
	entity:clearNetVars()
end)

hook.Add("PlayerInitialSpawn", "nSync", function(client)
	client:syncVars()
end)