require "personas"

LinkLuaModifier("modifier_persona_range_bonus", "modifier_persona_range_bonus", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_persona_health_bonus", "modifier_persona_health_bonus", LUA_MODIFIER_MOTION_NONE )
-- LinkLuaModifier("modifier_persona_speed_bonus", "modifier_persona_speed_bonus", LUA_MODIFIER_MOTION_NONE )


function Spawn(keys)
	local caster = keys.caster
	local ability = keys.ability
	local arcana = keys.arcana
	caster.arcana = arcana

	local startingPersona = nil
	for personaName,persona in pairs(personas_table) do
		if persona["arcana"] == arcana then
			startingPersona = personaName
			break
		end
	end

	local personaItem = CreateItem("item_"..startingPersona, caster, caster)
	caster:AddItem(personaItem)
	personaItem = InitializePersona(personaItem)

	caster:AddNewModifier(caster, ability, "modifier_persona_range_bonus", {})
	caster:AddNewModifier(caster, ability, "modifier_persona_health_bonus", {})
	-- caster:AddNewModifier(caster, ability, "modifier_persona_speed_bonus", {})
	caster:CastAbilityImmediately(personaItem, caster:GetPlayerID())

	local personaItemAngelTest = CreateItem("item_angel", caster, caster)
	caster:AddItem(personaItemAngelTest)
	personaItemAngelTest = InitializePersona(personaItemAngelTest)

	Setup_Persona_Tooltip(caster)
end




-- Notify Panorama that the player spawned
function Setup_Persona_Tooltip(hero)
	local playerid = hero:GetPlayerOwnerID()
	local heroid = PlayerResource:GetSelectedHeroID(playerid)
	local heroname = hero:GetUnitName()

	-- get hero entindex and create hero panel
	local HeroIndex = hero:GetEntityIndex()
	Create_Persona_Tooltip(playerid, heroid, heroname, "landscape", HeroIndex, hero.activePersona)

	local hero_health = hero:GetHealth()
	local damagedbool = false
	local grace_peroid = false
	-- update hero panel
	Timers:CreateTimer(function()
		local player = PlayerResource:GetPlayer(playerid)
		local unspentpoints = hero:GetAbilityPoints()
		local current_hero_health = hero:GetHealth()
		
		-- if not grace peroid, check for health difference
		if not grace_peroid then
			if current_hero_health < hero_health and damagedbool == false then
				damagedbool = true
				
				-- set delay for the red to stay
				Timers:CreateTimer(1, function()
					hero_health = current_hero_health
					damagedbool = false
					grace_peroid = true
					-- set grace peroid
					Timers:CreateTimer(1, function() grace_peroid = false end)
				end)
			else
				hero_health = current_hero_health
			end
		end

		-- Build inventories for tooltip to reference
		local unitsWithInventories = {}
		local allEntities = Entities:FindAllInSphere(hero:GetAbsOrigin(), 20100)
		-- print(allEntities)
		for k,v in pairs(allEntities) do
			if v.HasInventory and v:HasInventory() then
				-- print("inventory unit:", k, v)
				-- print("entityindex:", v:GetEntityIndex())
				local inventory = {}
				for i=0,5 do
					inventory[i] = v:GetItemInSlot(i)
				end
				unitsWithInventories[v:GetEntityIndex()] = inventory
			end
		end
		-- for k,v in pairs(unitsWithInventories) do
		-- 	print("unitWithInventory:", k,v)
		-- -- 	for _,item in pairs(v) do
		-- -- 		-- print(item)
		-- -- 		print("attributes:", item.attributes)
		-- -- 		if item.attributes then
		-- -- 			print(item.attributes["str"])
		-- -- 		end
		-- -- 	end
		-- end
		CustomGameEventManager:Send_ServerToPlayer(player, "update_persona_tooltip", {playerid = playerid, heroname=heroname, hero=HeroIndex, damaged=damagedbool, unspent_points=unspentpoints, attributes = hero.activePersona.attributes, unitInventories = unitsWithInventories})
		return 0.03
	end)
end

function Create_Persona_Tooltip(playerid, heroID, heroname, imagestyle, HeroIndex, activePersona)
	local player = PlayerResource:GetPlayer(playerid)

	CustomGameEventManager:Send_ServerToPlayer(player, "create_persona_tooltip", {heroid=heroID, heroname=heroname, imagestyle=imagestyle, playerid = playerid, hero=HeroIndex, personaName=activePersona.attributes["name"]})
end