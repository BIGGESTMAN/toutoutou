require "libraries/damage_system"

-- str = damage, mag = intelligence, end = health/hregen, swft = movespeed, agi = range
-- resists: physical, fire, ice, wind, thunder, light, dark
-- resist values: 0 = normal, -1 = weak, 1 = resist, 2 = block, 3 = absorb

MOVE_SPEED_MODIFIER = "modifier_persona_speed_bonus"

BASE_EXP_REQUIRED = 300
EXP_REQUIRED_INCREASE_PER_LEVEL = 100

CHARIOT = 3
JUSTICE = 4
TEMPERANCE = 5

damage_types_table = {
	"physical",
	"fire",
	"ice",
	"wind",
	"thunder",
	"light",
	"dark",
}

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
		learned_abilities = {},
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
		learned_abilities = {},
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
		learned_abilities = {},
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
	persona.attributes["exp"] = 0
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
	caster:FindModifierByName("modifier_persona_speed_bonus").speed_bonus = item.attributes["swft"] * 10
	-- print(caster:FindModifierByName("modifier_persona_speed_bonus").speed_bonus)
	-- caster:RemoveModifierByName("modifier_persona_speed_bonus")
	if item.attributes["swft"] > 0 then -- This is insanely buggy in an insane way, fix this at some point
		-- print(caster:HasModifier("modifier_persona_user_chie"))
		-- caster:FindAbilityByName("persona_user_chie"):ApplyDataDrivenModifier(caster, caster, MOVE_SPEED_MODIFIER, {}) -- change this to be dynamic, or give all characters a base persona_user ability -- latter probably better
		-- caster:SetModifierStackCount("modifier_persona_speed_bonus", caster, item.attributes["swft"] * 10)
		-- print(caster:HasModifier(MOVE_SPEED_MODIFIER))
		-- print(caster:FindModifierByName("modifier_persona_speed_bonus"))
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

	-- Set new resistances
	for i=1,7 do
		caster:SetResistance(damage_types_table[i], resistanceNumberFromType(item.attributes["resists"][i]))
	end

	if caster.activePersona and not caster.activePersona:IsNull() then caster.activePersona:SetActivated(true) end
	caster.activePersona = item
	item:SetActivated(false)

	-- TODO: fire particle
	-- TODO: start global persona-switch cooldown
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