LinkLuaModifier("modifier_elixir", "heroes/hero_reisen/modifier_elixir.lua", LUA_MODIFIER_MOTION_NONE )

function giveElixir(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	target:AddNewModifier(caster, ability, "modifier_elixir", {})
	local modifier = target:FindModifierByName("modifier_elixir")
	modifier:SetStackCount(modifier:GetStackCount() + 1)
	local max_stacks = ability:GetLevelSpecialValueFor("max_stacks", ability_level)
	if modifier:GetStackCount() >= max_stacks then
		modifier:SetStackCount(max_stacks)

		local team = target:GetTeamNumber()
		local origin = target:GetAbsOrigin()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local radius = ability:GetLevelSpecialValueFor("radius", ability_level)

		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
		local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
		local damage_type = ability:GetAbilityDamageType()

		for k,unit in pairs(targets) do
			ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_stun", {})
		end

		ParticleManager:CreateParticle("particles/units/heroes/hero_alchemist/alchemist_unstable_concoction_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	end

	local particle = ParticleManager:CreateParticle("particles/patriots_elixir.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
end