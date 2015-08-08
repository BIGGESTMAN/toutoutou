function spawnDoll(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local tree_destruction_radius = 250

	local unit_name = "goliath_doll_" .. ability:GetLevel()
	if caster:HasScepter() then unit_name = "goliath_doll_aghs" end

	local doll = CreateUnitByName(unit_name, keys.target_points[1], true, caster, caster, caster:GetTeamNumber())
	if not caster.goliath_dolls then caster.goliath_dolls = {} end
	caster.goliath_dolls[doll] = true
	doll:SetControllableByPlayer(caster:GetMainControllingPlayer(), true)
	ability:ApplyDataDrivenModifier(caster, doll, keys.modifier, {})
	if caster:HasScepter() then
		ability:ApplyDataDrivenModifier(caster, doll, "modifier_goliath_doll_spell_immune", {})
		local particle = ParticleManager:CreateParticle("particles/alice/goliath_doll_spell_immunity.vpcf", PATTACH_POINT_FOLLOW, doll)
		ParticleManager:SetParticleControlEnt(particle, 0, doll, PATTACH_POINT_FOLLOW, "attach_hitloc", doll:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle, 1, doll, PATTACH_POINT_FOLLOW, "attach_hitloc", doll:GetAbsOrigin(), true)
	end

	local bash_ability = doll:FindAbilityByName(keys.bash_ability)
	bash_ability:SetLevel(ability_level + 1)

	local cleave_ability = doll:FindAbilityByName(keys.cleave_ability)
	cleave_ability:SetLevel(ability_level + 1)

	ability:ApplyDataDrivenModifier(caster, doll, "modifier_kill", {duration = ability:GetLevelSpecialValueFor("duration", ability_level)})

	GridNav:DestroyTreesAroundPoint(keys.target_points[1], tree_destruction_radius, false)
end

function killDoll(keys)
	keys.caster.goliath_dolls[keys.target] = nil
end

function onAttack(keys)
	local doll = keys.attacker
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target
	local bash_ability = doll:FindAbilityByName("goliath_doll_bash")
	local cleave_ability = doll:FindAbilityByName("goliath_doll_cleave")

	local bash_chance = bash_ability:GetLevelSpecialValueFor("bash_chance", ability_level)
	local bash_duration = bash_ability:GetLevelSpecialValueFor("bash_duration", ability_level)
	local bash_damage = bash_ability:GetLevelSpecialValueFor("bash_damage", ability_level)

	local cleave_radius = cleave_ability:GetLevelSpecialValueFor("cleave_radius", ability_level)
	local cleave_damage = cleave_ability:GetLevelSpecialValueFor("cleave_damage", ability_level)

	local bashed = RandomInt(1, 100) <= bash_chance

	local team = doll:GetTeamNumber()
	local origin = target:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iOrder = FIND_ANY_ORDER
	local radius = cleave_radius

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	local damage = doll:GetAverageTrueAttackDamage() * cleave_damage / 100

	for k,unit in pairs(targets) do
		if unit ~= target then
			ApplyDamage({victim = unit, attacker = doll, damage = damage, damage_type = DAMAGE_TYPE_PHYSICAL})
		end
		if bashed then
			ability:ApplyDataDrivenModifier(doll, unit, "modifier_goliath_doll_bashed", {duration = bash_duration})
		end
	end
end

function checkTripWireRegen(keys)
	local caster = keys.caster
	if caster.wires then
		local ability = keys.ability
		local doll = keys.target

		local wire_attached = false
		for wire_unit,wire in pairs(caster.wires) do
			if wire[2] == doll and wire[1] == caster then
				wire_attached = true
				break
			end
		end

		if wire_attached then
			ability:ApplyDataDrivenModifier(caster, doll, "modifier_goliath_doll_regen", {})
		else
			doll:RemoveModifierByName("modifier_goliath_doll_regen")
		end
	end
end

function tripWireAttached(keys)
	local caster = keys.caster
	local ability = keys.ability
	local doll = keys.target

	doll.tether_particle = ParticleManager:CreateParticle("particles/alice/goliath_doll_regen_tether.vpcf", PATTACH_POINT_FOLLOW, doll)
	ParticleManager:SetParticleControlEnt(doll.tether_particle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(doll.tether_particle, 1, doll, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", doll:GetAbsOrigin(), true)
end

function tripWireDetached(keys)
	ParticleManager:DestroyParticle(keys.target.tether_particle, false)
end