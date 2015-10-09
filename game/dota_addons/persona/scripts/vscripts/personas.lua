require "libraries/damage_system"

-- str = damage, mag = intelligence, end = health/hregen, swft = movespeed, dex = attackspeed, range = range
-- resists: physical, fire, ice, wind, thunder, light, dark
-- resist values: 0 = normal, -1 = weak, 1 = resist, 2 = block, 3 = absorb

-- MOVE_SPEED_MODIFIER = "modifier_persona_speed_bonus"

FUSION_MAX_AVERAGE_LEVEL_DISTANCE = 10

CHARIOT = 3
JUSTICE = 4
TEMPERANCE = 5

damage_types_table = damage_types_table or {}
personas_table = personas_table or {}
ability_levels_table = ability_levels_table or {}

function InitializePersonaData()
	damage_types_table = {
		"physical",
		"fire",
		"ice",
		"wind",
		"thunder",
		"light",
		"dark",
	}

	personas_table = {}
	personas_table["slime"] = {
		name = "slime",
		arcana = CHARIOT,
		str = 3,
		mag = 2,
		endr = 3,
		swft = 5,
		dex = 3,
		range = 128,
		abilities = {"bash", "tarunda", "longshot"},
		level = 2,
		learned_abilities = {},
		resists = {1,-1,0,0,0,0,0},
	}
	-- personas_table["slime"]["attackProjectile"] = "wtf"
	-- personas_table["slime"]["particle"] = ""
	personas_table["slime"]["learned_abilities"][3] = "resist_physical"

	personas_table["angel"] = {
		name = "angel",
		arcana = JUSTICE,
		str = 4,
		mag = 5,
		endr = 2,
		swft = 7,
		dex = 2,
		range = 375,
		abilities = {"garu", "regenerate_1"},
		level = 4,

		particle = "",
		learned_abilities = {},
		attackProjectile = "",
		resists = {0,0,0,1,0,1,-1},
	}

	personas_table["apsaras"] = {
		name = "apsaras",
		arcana = TEMPERANCE,
		str = 3,
		mag = 5,
		endr = 3,
		swft = 5,
		dex = 3,
		range = 375,
		abilities = {"dia", "bufu", "rakunda"},
		level = 4,

		learned_abilities = {},
		resists = {0,-1,0,0,0,0,0},
	}

	personas_table["centaur"] = {
		name = "centaur",
		arcana = CHARIOT,
		str = 3,
		mag = 2,
		endr = 3,
		swft = 5,
		dex = 3,
		range = 128,
		abilities = {"cold_feet"},
		level = 1,

		learned_abilities = {},
		resists = {0,0,2,0,-1,0,0},
	}
	personas_table["centaur"]["learned_abilities"][2] = "longshot"

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
end

function InitializePersona(persona)
	local personaName = string.gsub(persona:GetAbilityName(), "item_", "")
	persona.attributes = {
		name = personas_table[personaName]["name"],
		arcana = personas_table[personaName]["arcana"],
		str = personas_table[personaName]["str"],
		mag = personas_table[personaName]["mag"],
		endr = personas_table[personaName]["endr"],
		swft = personas_table[personaName]["swft"],
		dex = personas_table[personaName]["dex"],
		range = personas_table[personaName]["range"],
		abilities = {},
		level = personas_table[personaName]["level"],
		resists = personas_table[personaName]["resists"],

		attackProjectile = personas_table[personaName]["attackProjectile"],
		particle = personas_table[personaName]["particle"],
		learned_abilities = personas_table[personaName]["learned_abilities"],
	}

	for k,v in ipairs(personas_table[personaName]["abilities"]) do
		persona.attributes["abilities"][k] = v
	end
	persona.attributes["exp"] = 0

	-- Set charges to level
	persona:SetCurrentCharges(persona.attributes["level"])

	return persona
end

function Activate(keys)
	local caster = keys.caster
	local item = keys.ability

	-- Update hero stats
	local effectiveStr = math.floor(item.attributes["str"])
	local effectiveMag = math.floor(item.attributes["mag"])
	local effectiveEndr = math.floor(item.attributes["endr"])
	caster:SetBaseDamageMin(effectiveStr * 10)
	caster:SetBaseDamageMax(effectiveStr * 10)
	caster:SetBaseIntellect(10 + effectiveMag * 3)
	caster:FindModifierByName("modifier_persona_health_bonus").health_bonus = effectiveEndr * 60
	caster:FindModifierByName("modifier_persona_range_bonus").range_bonus = item.attributes["range"] - 128
	caster:FindModifierByName("modifier_persona_speed_bonus").speed_bonus = item.attributes["swft"] * 10
	caster:FindModifierByName("modifier_persona_attackspeed_bonus").attackspeed_bonus = 20 + item.attributes["dex"] * 5
	-- print(caster:FindModifierByName("modifier_persona_speed_bonus").speed_bonus)
	-- caster:RemoveModifierByName("modifier_persona_speed_bonus")
	if item.attributes["swft"] > 0 then -- This is insanely buggy in an insane way, fix this at some point
		-- print(caster:HasModifier("modifier_persona_user_chie"))
		-- caster:FindAbilityByName("persona_user_chie"):ApplyDataDrivenModifier(caster, caster, MOVE_SPEED_MODIFIER, {}) -- change this to be dynamic, or give all characters a base persona_user ability -- latter probably better
		-- caster:SetModifierStackCount("modifier_persona_speed_bonus", caster, item.attributes["swft"] * 10)
		-- print(caster:HasModifier(MOVE_SPEED_MODIFIER))
		-- print(caster:FindModifierByName("modifier_persona_speed_bonus"))
	end

	-- Set new resistances
	for i=1,#damage_types_table do
		caster:SetResistance(damage_types_table[i], resistanceNumberFromType(item.attributes["resists"][i]))
	end

	-- Switch out abilities
	for i=0,5 do
		local ability = caster:GetAbilityByIndex(i)
		if ability then
			if ability.passiveModifier then caster:RemoveModifierByName(ability.passiveModifier) end
			caster:RemoveAbility(ability:GetAbilityName())
		end
	end
	for k,ability in ipairs(item.attributes["abilities"]) do
		caster:AddAbility(ability)
		if caster:HasAbility(ability) then caster:FindAbilityByName(ability):SetLevel(1) else print("can't add ability, not found in kv file") end -- can remove this check once you actually implement all abilities personas are listed as having
	end

	-- Set charges to level
	item:SetCurrentCharges(item.attributes["level"])

	if caster.activePersona and not caster.activePersona:IsNull() then caster.activePersona:SetActivated(true) end
	caster.activePersona = item
	item:SetActivated(false)

	-- TODO: fire particle
	-- TODO: start global persona-switch cooldown
end

function SetPassiveModifier(keys)
	keys.ability.passiveModifier = keys.modifier
end

function AbilitySetResistance(keys)
	print("SETTING RESISTANCE", keys.damageType, keys.resistanceLevel)
	local caster = keys.caster
	local damageType = keys.damageType
	local resistType = keys.resistanceLevel
	if resistanceNumberFromType(resistType) > caster:GetResistance(damageType) then
		caster:SetResistance(damageType, resistanceNumberFromType(resistType))
	end
end

function DoubleFusion(keys)
	local caster = keys.caster

	local persona1 = caster:GetItemInSlot(0)
	local persona2 = caster:GetItemInSlot(1)

	if persona1 and persona2 and persona1.attributes and persona2.attributes then
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

function resistanceNumberFromType(resistType)
	if resistType == -1 then
		return -50 -- weak = 1.5x damage
	elseif resistType == 1 then
		return 50 -- resist = 0.5x damage
	elseif resistType == 2 then
		return 100 -- block = 0x damage
	elseif resistType == 3 then
		return 200 -- absorb = -1x damage
	else
		return 0 -- normal
	end
end