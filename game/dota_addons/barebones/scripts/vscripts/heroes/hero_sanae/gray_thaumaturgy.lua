LinkLuaModifier("modifier_gray_thaumaturgy_debuff", "heroes/hero_sanae/modifier_gray_thaumaturgy_debuff.lua", LUA_MODIFIER_MOTION_NONE )

function gainAgility(keys)
	local caster = keys.caster
	local target = keys.unit
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	if target:IsHero() then
		if caster.gray_thaumaturgy_agility == nil then caster.gray_thaumaturgy_agility = 0 end
		caster.gray_thaumaturgy_agility = caster.gray_thaumaturgy_agility + ability:GetLevelSpecialValueFor("agility_gain", ability_level)

		if not caster:FindModifierByName(keys.modifier) then
			ability:ApplyDataDrivenModifier(caster, caster, keys.modifier, {})
		end
		caster:FindModifierByName(keys.modifier):SetStackCount(caster.gray_thaumaturgy_agility)
	end
end

function agilityDecay(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	if caster.gray_thaumaturgy_agility ~= nil then
		caster.gray_thaumaturgy_agility = caster.gray_thaumaturgy_agility - (ability:GetLevelSpecialValueFor("agility_loss", ability_level) + caster.gray_thaumaturgy_agility * ability:GetLevelSpecialValueFor("agility_loss_scaling", ability_level))
		if caster.gray_thaumaturgy_agility <= 0 then
			caster.gray_thaumaturgy_agility = 0
			caster:RemoveModifierByName(keys.modifier)
		else
			caster:FindModifierByName(keys.modifier):SetStackCount(caster.gray_thaumaturgy_agility)
		end
	end
end

function updateParticle(keys)
	local caster = keys.caster

	if caster:IsAlive() and caster:HasModifier(keys.modifier) then
		if not caster.gray_thaumaturgy_particle then
			caster.gray_thaumaturgy_particle = ParticleManager:CreateParticle(keys.particle, PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(caster.gray_thaumaturgy_particle, 0, caster:GetAbsOrigin())
			-- ParticleManager:SetParticleControl(caster.gray_thaumaturgy_particle, 1, caster:GetAbsOrigin())
			-- ParticleManager:SetParticleControlEnt(explosion_particle, 0, dummy_unit, PATTACH_POINT_FOLLOW, "attach_hitloc", dummy_unit:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(caster.gray_thaumaturgy_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		end
		local alpha_factor = 15 -- Determines to what degree stacks increase visiblity of the particle
		local alpha = (1 - 1 / (math.pow(caster.gray_thaumaturgy_agility / alpha_factor, 2) + 1))
		ParticleManager:SetParticleControl(caster.gray_thaumaturgy_particle, 2, Vector(alpha,0,0))
	else
		if caster.gray_thaumaturgy_particle then
			ParticleManager:DestroyParticle(caster.gray_thaumaturgy_particle, false)
			caster.gray_thaumaturgy_particle = nil
		end
	end
end

function updateDebuff(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iOrder = FIND_ANY_ORDER
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		unit:AddNewModifier(caster, ability, "modifier_gray_thaumaturgy_debuff", {duration = ability:GetLevelSpecialValueFor("update_interval", ability_level)})
		unit:FindModifierByName("modifier_gray_thaumaturgy_debuff"):ForceRefresh()
	end
end