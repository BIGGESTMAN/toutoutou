require "personas"

LinkLuaModifier("modifier_persona_range_bonus", "modifier_persona_range_bonus", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_persona_health_bonus", "modifier_persona_health_bonus", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_persona_speed_bonus", "modifier_persona_speed_bonus", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_persona_attackspeed_bonus", "modifier_persona_attackspeed_bonus", LUA_MODIFIER_MOTION_NONE )


function Spawn(keys)
	local caster = keys.caster
	local ability = keys.ability
	local arcana = keys.arcana
	caster.arcana = arcana
	local startingPersona = keys.persona

	local personaItem = CreateItem("item_"..startingPersona, caster, caster)
	caster:AddItem(personaItem)
	personaItem = InitializePersona(personaItem)

	caster:AddNewModifier(caster, ability, "modifier_persona_range_bonus", {})
	caster:AddNewModifier(caster, ability, "modifier_persona_health_bonus", {})
	caster:AddNewModifier(caster, ability, "modifier_persona_speed_bonus", {})
	caster:AddNewModifier(caster, ability, "modifier_persona_attackspeed_bonus", {})
	caster:CastAbilityImmediately(personaItem, caster:GetPlayerID())
	personaItem:EndCooldown()

	-- local personaItemAngelTest = CreateItem("item_angel", caster, caster)
	-- caster:AddItem(personaItemAngelTest)
	-- personaItemAngelTest = InitializePersona(personaItemAngelTest)

	Setup_Persona_Tooltip(caster)
end




-- Notify Panorama that the player spawned
function Setup_Persona_Tooltip(hero)
	local playerid = hero:GetPlayerOwnerID()

	-- get hero entindex and create hero panel
	local HeroIndex = hero:GetEntityIndex()

	-- update persona tooltip
	Timers:CreateTimer(function()
		local player = PlayerResource:GetPlayer(playerid)

		-- Build inventories for tooltip to reference
		local unitsWithInventories = {}
		local allEntities = Entities:FindAllInSphere(hero:GetAbsOrigin(), 20100)
		for k,v in pairs(allEntities) do
			if v.HasInventory and v:HasInventory() then
				local inventory = {}
				for i=0,5 do
					inventory[i] = v:GetItemInSlot(i)
				end
				unitsWithInventories[v:GetEntityIndex()] = inventory
			end
		end

		
		-- for k,v in pairs(personas_table["slime"]) do
		-- 	print(k,v)
		-- end

		-- for k,v in pairs(unitsWithInventories[HeroIndex]) do
		-- 	print(k,v)
		-- end
		-- print(player, playerid, HeroIndex, unitsWithInventories)
		CustomGameEventManager:Send_ServerToPlayer(player, "update_persona_tooltip", {playerid = playerid, hero=HeroIndex, unitInventories = unitsWithInventories})
		return 0.03
	end)
end