function update(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	local damage = ability:GetLevelSpecialValueFor("damage_per_second", ability_level) * 0.03
	local damage_type = ability:GetAbilityDamageType()

	local team = target:GetTeamNumber()
	local origin = target:GetAbsOrigin()
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iOrder = FIND_ANY_ORDER

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	if #targets < 1 then
		-- Apply stealth
		ability:ApplyDataDrivenModifier(caster, target, "modifier_northern_winner_invis", {})
	else
		-- Remove stealth
		target:RemoveModifierByName("modifier_northern_winner_invis")
	end

	-- Deal blizzard damage if in Lingering Cold
	local isInLingeringCold = false
	if caster.ice_fields then
		for ice_field,v in pairs(caster.ice_fields) do
			if (target:GetAbsOrigin() - ice_field:GetAbsOrigin()):Length2D() < ice_field.radius then
				isInLingeringCold = true
				break
			end
		end
	end
	if isInLingeringCold then
		for k,unit in pairs(targets) do
			ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
		end

		if not target.northern_winner_blizzard_particle then
			target.northern_winner_blizzard_particle = ParticleManager:CreateParticle("particles/letty/northern_winner_blizzard.vpcf", PATTACH_ABSORIGIN_FOLLOW, target.northern_winner_thinker)
		end
	else
		if target.northern_winner_blizzard_particle then
			ParticleManager:DestroyParticle(target.northern_winner_blizzard_particle, false)
			target.northern_winner_blizzard_particle = nil
		end
	end

	-- Move particle
	if target.northern_winner_thinker then target.northern_winner_thinker:SetAbsOrigin(target:GetAbsOrigin()) end
end

function addParticle(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	target.northern_winner_thinker = CreateModifierThinker(caster, ability, "modifier_northern_winner_thinker", {}, target:GetAbsOrigin(), target:GetTeamNumber(), false)

	local particle = ParticleManager:CreateParticle("particles/letty/northern_winner.vpcf", PATTACH_ABSORIGIN_FOLLOW, target.northern_winner_thinker)
	ParticleManager:SetParticleControlEnt(particle, 0, target.northern_winner_thinker, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius,0,0))
end

function removeThinker(keys)
	keys.target.northern_winner_thinker:RemoveSelf()
	keys.target.northern_winner_thinker = nil
end

function removeParticle(keys)
	local target = keys.target
	if target.northern_winner_blizzard_particle then
		ParticleManager:DestroyParticle(target.northern_winner_blizzard_particle, false)
		target.northern_winner_blizzard_particle = nil
	end
end