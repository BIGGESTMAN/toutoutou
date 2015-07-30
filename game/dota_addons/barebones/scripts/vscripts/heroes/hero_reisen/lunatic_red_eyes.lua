function lunaticEyesCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_lunatic_red_eyes", {})
	local modifier = caster:FindModifierByName("modifier_lunatic_red_eyes")

	modifier.scepter = caster:HasScepter()
	local base_pulses = ability:GetLevelSpecialValueFor("base_pulses", ability_level)
	local bonus_pulses = math.floor(caster:GetAgility() / ability:GetLevelSpecialValueFor("agility_per_pulse", ability_level))
	if caster:HasScepter() then
		bonus_pulses = math.floor(caster:GetAgility() / ability:GetLevelSpecialValueFor("scepter_agility_per_pulse", ability_level))
	end
	modifier.total_pulses = base_pulses + bonus_pulses
	modifier.pulses_fired = 0
end

function firePulse(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier = caster:FindModifierByName("modifier_lunatic_red_eyes")

	modifier.pulses_fired = modifier.pulses_fired + 1

	local silence = false
	local slow = false
	if modifier.pulses_fired == 1 or modifier.pulses_fired == modifier.total_pulses then
		silence = true
		slow = true
	else
		if modifier.pulses_fired % ability:GetLevelSpecialValueFor("silence_pulse_interval", ability_level) == 0 then
			silence = true
		end
		if modifier.pulses_fired % ability:GetLevelSpecialValueFor("slow_pulse_interval", ability_level) == 0 then
			slow = true
		end
	end

	if modifier.pulses_fired == modifier.total_pulses then
		caster:RemoveModifierByName("modifier_lunatic_red_eyes")
	end

	firePulseFromUnit(caster, silence, slow, ability, 1)

	if modifier.scepter then
		local team = caster:GetTeamNumber()
		local origin = caster:GetAbsOrigin()
		local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
		local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local radius = 20100
		local allied_units = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

		for k,unit in pairs(allied_units) do
			if unit:GetPlayerOwnerID() == caster:GetPlayerID() and unit:IsIllusion() then
				firePulseFromUnit(unit, silence, slow, ability, ability:GetLevelSpecialValueFor("scepter_illusion_damage", ability_level))
			end
		end
	end
end

function firePulseFromUnit(unit, silence, slow, ability, damage_multiplier)
	local ability_level = ability:GetLevel() - 1

	local team = unit:GetTeamNumber()
	local origin = unit:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iOrder = FIND_ANY_ORDER
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level) * damage_multiplier
	local damage_type = ability:GetAbilityDamageType()

	for k,target in pairs(targets) do
		ApplyDamage({victim = target, attacker = unit, damage = damage, damage_type = damage_type})
		if silence then ability:ApplyDataDrivenModifier(unit, target, "modifier_silence", {}) end
		if slow then ability:ApplyDataDrivenModifier(unit, target, "modifier_slow", {}) end
	end

	local particle = ParticleManager:CreateParticle("particles/lunatic_red_eyes.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius,0,0))

	unit:EmitSound("Touhou.Lunatic_Eyes")
end