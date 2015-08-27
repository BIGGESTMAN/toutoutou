-- str = damage, mag = intelligence, end = health/hregen, swft = movespeed, agi = range
-- resists: physical, fire, ice, wind, thunder, light, dark
-- resist values: 0 = normal, -1 = weak, 1 = resist, 2 = block, 3 = absorb

MOVE_SPEED_MODIFIER = "modifier_persona_speed_bonus"

CHARIOT = 3
JUSTICE = 4
TEMPERANCE = 5

personas_table = {
	slime = {
		name = "slime",
		arcana = CHARIOT,
		str = 3,
		mag = 2,
		endr = 3,
		swft = 5,
		agi = 0,
		abilities = {"bash", "tarunda", "resist_physical"},
		level = 2,
		resists = {1,-1,0,0,0,0,0},

		attackProjectile = "",
		particle = "",
	},
	angel = {
		name = "angel",
		arcana = JUSTICE,
		str = 4,
		mag = 5,
		endr = 2,
		swft = 7,
		agi = 5,
		abilities = {"garu", "regenerate_1"},
		level = 4,
		resists = {0,0,0,1,0,1,-1},

		attackProjectile = "",
		particle = "",
	},
	apsaras = {
		name = "apsaras",
		arcana = TEMPERANCE,
		str = 3,
		mag = 5,
		endr = 3,
		swft = 5,
		agi = 5,
		abilities = {"dia", "bufu", "rakunda"},
		level = 4,
		resists = {0,-1,0,0,0,0,0},

		attackProjectile = "",
		particle = "",
	},
}

ability_levels_table = {
	tarunda = 1,
	rakunda = 1,
	bash = 2,
	garu = 4,
	bufu = 4,
	dia = 4,
	regenerate_1 = 3,
	resist_physical = 5,
}

function InitializePersona(persona)
	local personaName = string.gsub(persona:GetAbilityName(), "item_", "")
	persona.attributes = personas_table[personaName]
	return persona
end

function Activate(keys)
	local caster = keys.caster
	local item = keys.ability

	caster:SetBaseDamageMin(item.attributes["str"] * 10)
	caster:SetBaseDamageMax(item.attributes["str"] * 10)
	caster:SetBaseIntellect(10 + item.attributes["mag"] * 3)
	caster:FindModifierByName("modifier_persona_health_bonus").health_bonus = item.attributes["endr"] * 60
	caster:FindModifierByName("modifier_persona_range_bonus").range_bonus = item.attributes["agi"] * 50
	-- caster:FindModifierByName("modifier_persona_speed_bonus").speed_bonus = item.attributes["swft"] * 10
	-- print(caster:FindModifierByName("modifier_persona_speed_bonus").speed_bonus)
	caster:RemoveModifierByName("modifier_persona_speed_bonus")
	if item.attributes["swft"] > 0 then -- This is insanely buggy in an insane way, fix this at some point
		-- print(caster:HasModifier("modifier_persona_user_chie"))
		-- caster:FindAbilityByName("persona_user_chie"):ApplyDataDrivenModifier(caster, caster, MOVE_SPEED_MODIFIER, {}) -- change this to be dynamic, or give all characters a base persona_user ability -- latter probably better
		-- caster:SetModifierStackCount("modifier_persona_speed_bonus", caster, item.attributes["swft"] * 10)
		-- print(caster:HasModifier(MOVE_SPEED_MODIFIER))
		-- print(caster:FindModifierByName("modifier_persona_speed_bonus"))
	end

	for i=0,5 do
		local ability = caster:GetAbilityByIndex(i)
		if ability then
			if ability.passiveModifier then caster:RemoveModifierByName(ability.passiveModifier) end
			caster:RemoveAbility(ability:GetAbilityName())
		end
	end
	for k,ability in ipairs(item.attributes["abilities"]) do
		caster:AddAbility(ability)
		if caster:HasAbility(ability) then caster:FindAbilityByName(ability):SetLevel(1) end -- can remove this check once you actually implement all abilities personas have (tarunda, resist phys, and so on)
	end

	if caster.activePersona and not caster.activePersona:IsNull() then caster.activePersona:SetActivated(true) end
	caster.activePersona = item
	item:SetActivated(false)

	-- TODO: fire particle
	-- TODO: start global persona-switch cooldown

	Setup_Persona_Tooltip(caster)
end

function SetPassiveModifier(keys)
	keys.ability.passiveModifier = keys.modifier
end

function SetLevel(keys)
	keys.ability.level = keys.level
end

function DoubleFusion(keys)
	local caster = keys.caster

	local persona1 = caster:GetItemInSlot(0)
	local persona2 = caster:GetItemInSlot(1)

	if persona1 and persona2 then
		PersonaResult(caster, caster.arcana, persona1, persona2)
	end
end

function PersonaResult(caster, casterArcana, persona1, persona2)
	local newPersonaArcana = GetResultingArcana(persona1, persona2)
	local averageLevel = persona1.attributes["level"] + persona2.attributes["level"] / 2

	local possiblePersonas = {}
	for personaName,persona in pairs(personas_table) do
		if persona["arcana"] == newPersonaArcana then
			local possiblePersona = {}
			table.insert(possiblePersonas, {persona, math.abs(persona["level"] - averageLevel), personaName})
		end
	end

	local newPersona = nil
	local newPersonaName = nil
	if #possiblePersonas > 0 then
		table.sort(possiblePersonas, function(a,b) return a[2] < b[2] end)
		newPersona = possiblePersonas[1][1]
		newPersonaName = possiblePersonas[1][3]
	end

	if newPersona then
		if casterArcana == newPersona["arcana"] then
			-- TODO: give bonus xp
		end

		local newPersonaAbilities = newPersona["abilities"]
		local sortedPersona1Abilities = table.sort(persona1.attributes["abilities"], function(a,b) return ability_levels_table[a] > ability_levels_table[b] end)
		local sortedPersona2Abilities = table.sort(persona2.attributes["abilities"], function(a,b) return ability_levels_table[a] > ability_levels_table[b] end)
		local persona1Inheritance = persona1.attributes["abilities"][1]
		local persona2Inheritance = persona2.attributes["abilities"][1]
		table.insert(newPersonaAbilities, persona1Inheritance)
		table.insert(newPersonaAbilities, persona2Inheritance)
		for k,v in pairs(newPersonaAbilities) do
			print(k,v)
		end
		
		local newPersonaItem = CreateItem("item_"..newPersonaName, caster, caster)
		-- print(newPersonaItem)
		newPersonaItem = InitializePersona(newPersonaItem)
		newPersonaItem.attributes["abilities"] = newPersonaAbilities

		caster:RemoveItem(persona1)
		caster:RemoveItem(persona2)
		caster:AddItem(newPersonaItem)
		if caster.activePersona == persona1 or caster.activePersona == persona2 then
			caster:CastAbilityImmediately(newPersonaItem, caster:GetPlayerID())
		end
	end
end

function GetResultingArcana(persona1, persona2)
	local persona1Arcana = persona1.attributes["arcana"]
	local persona2Arcana = persona2.attributes["arcana"]
	local resultingArcana = nil

	if persona1Arcana == CHARIOT then
		if persona2Arcana == JUSTICE then
			resultingArcana = TEMPERANCE
		end
	end

	return resultingArcana
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
		
		CustomGameEventManager:Send_ServerToPlayer(player, "update_persona", {playerid = playerid, heroname=heroname, hero=HeroIndex, damaged=damagedbool, unspent_points=unspentpoints, attributes = hero.activePersona.attributes})
		return 0.1
	end)
end

function Create_Persona_Tooltip(playerid, heroID, heroname, imagestyle, HeroIndex, activePersona)
	local player = PlayerResource:GetPlayer(playerid)

	CustomGameEventManager:Send_ServerToPlayer(player, "create_persona", {heroid=heroID, heroname=heroname, imagestyle=imagestyle, playerid = playerid, hero=HeroIndex, personaName=activePersona.attributes["name"]})
end