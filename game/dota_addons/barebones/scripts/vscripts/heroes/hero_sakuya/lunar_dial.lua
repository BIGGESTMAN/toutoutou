require "projectile_list"

function spellCast(keys)
	local caster = keys.caster
	local caster_location = caster:GetAbsOrigin()
	local ability = keys.ability

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local radius = 20100
	local iTeam = DOTA_UNIT_TARGET_TEAM_BOTH
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL + DOTA_UNIT_TARGET_BUILDING
	local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		if unit ~= caster then
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_lunar_dial_frozen", {})
		end
	end
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_lunar_dial_tracker", {})

	ProjectileList:FreezeProjectiles()
end

function updateTick(keys)
	local caster = keys.caster
	local caster_location = caster:GetAbsOrigin()
	local ability = keys.ability

	local duration_remaining = caster:FindModifierByName("modifier_lunar_dial_tracker"):GetRemainingTime()

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local radius = 20100
	local iTeam = DOTA_UNIT_TARGET_TEAM_BOTH
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL + DOTA_UNIT_TARGET_BUILDING
	local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		if unit ~= caster and not unit:HasModifier("modifier_lunar_dial_frozen") then
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_lunar_dial_frozen", {})
			unit:FindModifierByName("modifier_lunar_dial_frozen"):SetDuration(duration_remaining, true)
		end
	end

	ProjectileList:FreezeProjectiles()
end

function trackerDurationEnded(keys)
	ProjectileList:UnfreezeProjectiles()
end

function frozenDurationEnded(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	if target:IsHero() and caster:GetTeamNumber() ~= target:GetTeamNumber() then
		local damage = ability:GetSpecialValueFor("damage")
		local damage_type = ability:GetAbilityDamageType()
		ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})
	end
end