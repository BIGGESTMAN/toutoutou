sealTable = sealTable or {}

function FantasySealCast( keys )
	local caster = keys.caster
	sealTable[caster] = sealTable[caster] or {}
	sealTable[caster].location = caster:GetAbsOrigin()
end

function FantasySealHit( keys )
	local caster = keys.caster
	local target = keys.target
	local target_location = target:GetAbsOrigin()
	local ability = keys.ability

	-- Initializing the damage table
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.victim = target
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.ability = ability	

	local max_damage = ability:GetLevelSpecialValueFor("max_damage", (ability:GetLevel() - 1))
	local min_damage = ability:GetLevelSpecialValueFor("min_damage", (ability:GetLevel() - 1))
	local max_damage_distance = ability:GetLevelSpecialValueFor("max_damage_distance", (ability:GetLevel() - 1))
	local min_damage_distance = ability:GetLevelSpecialValueFor("min_damage_distance", (ability:GetLevel() - 1))

	local seal_damage = max_damage
	local distance = (target_location - sealTable[caster].location):Length2D()

	if ((distance > max_damage_distance) and (distance < min_damage_distance)) then
		seal_damage = seal_damage - ((max_damage - min_damage) * ((distance - max_damage_distance) / (min_damage_distance - max_damage_distance)))
	elseif (distance > min_damage_distance) then
		seal_damage = min_damage
	end

	damage_table.damage = seal_damage
	ApplyDamage(damage_table)
end