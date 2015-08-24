-- str = damage, mag = intelligence, end = strength, swft = movespeed, agi = range
-- resists: physical, fire, ice, wind, thunder, light, dark
-- resist values: 0 = normal, -1 = weak, 1 = resist, 2 = block, 3 = absorb

CHARIOT = 3

personas_table = {
	slime = {
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
	}
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
	caster:SetBaseIntellect(item.attributes["mag"] * 3)
	caster:SetBaseStrength(item.attributes["endr"] * 3)
	caster:FindModifierByName("modifier_persona_range_bonus").range_bonus = item.attributes["agi"] * 50
	caster:SetBaseMoveSpeed(280 + item.attributes["swft"] * 10)
	for i=0,5 do
		local ability = caster:GetAbilityByIndex(i)
		if ability then caster:RemoveAbility(ability:GetAbilityName()) end
	end
	for k,ability in ipairs(item.attributes["abilities"]) do
		caster:AddAbility(ability)
		if caster:HasAbility(ability) then caster:FindAbilityByName(ability):SetLevel(1) end -- can remove this check once you actually implement all abilities personas have (tarunda, resist phys, and so on)
	end

	if caster.activePersona then caster.activePersona:SetActivated(true) end
	caster.activePersona = item
	item:SetActivated(false)

	-- TODO: fire particle
	-- TODO: start global persona-switch cooldown
end