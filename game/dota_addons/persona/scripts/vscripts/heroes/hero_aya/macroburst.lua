previous_location_table = {}
distance_remaining_table = {}

function fireGust( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local team = caster:GetTeamNumber()
	local radius = ability:GetLevelSpecialValueFor("range", ability_level)
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NO_INVIS
	local iOrder = FIND_CLOSEST

	local units = FindUnitsInRadius(team, caster:GetAbsOrigin(), nil, radius, iTeam, iType, iFlag, iOrder, false)
	if #units > 0 then
		local projectile_info = {
	        Target = units[RandomInt(1, #units)],
	        Source = caster,
	        EffectName = "particles/aya/macroburst_wrapper.vpcf",
	        Ability = ability,
	        bDodgeable = false,
	        bProvidesVision = true,
	        iMoveSpeed = ability:GetLevelSpecialValueFor("projectile_speed", ability_level),
	        iVisionRadius = 0,
	        iVisionTeamNumber = caster:GetTeamNumber(),
	        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
	    }

	    ProjectileManager:CreateTrackingProjectile( projectile_info )
	    distance_remaining_table[caster] = ability:GetLevelSpecialValueFor("distance_to_ready", ability_level)
	end
end

function macroburstUpdateCooldown( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	currentLocation = caster:GetAbsOrigin()
	if previous_location_table[caster] == nil then
		previous_location_table[caster] = currentLocation
	end
	distance_traveled = (previous_location_table[caster] - currentLocation):Length2D()
	previous_location_table[caster] = currentLocation

	if caster:IsAlive() then
		if distance_remaining_table[caster] == nil then
			distance_remaining_table[caster] = ability:GetLevelSpecialValueFor("distance_to_ready", (ability:GetLevel() - 1))
		end
		distance_remaining_table[caster] = distance_remaining_table[caster] - distance_traveled

		if distance_remaining_table[caster] <= 0 then
			ability:EndCooldown()
			if not caster.macroburst_particle then caster.macroburst_particle = ParticleManager:CreateParticle("particles/aya/wisp_overcharge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster) end
			ParticleManager:SetParticleControlEnt(caster.macroburst_particle, 1, caster, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", caster:GetAbsOrigin(), true)
		else
			if caster.macroburst_particle then ParticleManager:DestroyParticle(caster.macroburst_particle, false) end
			caster.macroburst_particle = nil
			ability:EndCooldown()
			ability:StartCooldown(distance_remaining_table[caster])
		end
	else
		distance_remaining_table[caster] = nil
		previous_location_table[caster] = nil
	end

	local team = caster:GetTeamNumber()
	local radius = ability:GetLevelSpecialValueFor("range", ability_level)
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NO_INVIS
	local iOrder = FIND_CLOSEST

	local units = FindUnitsInRadius(team, caster:GetAbsOrigin(), nil, radius, iTeam, iType, iFlag, iOrder, false)

	if #units > 0 then
		keys.ability:SetActivated(true)
	else
		keys.ability:SetActivated(false)
	end
end

function onUpgrade(keys)
	local caster = keys.caster
	local ability = keys.ability
	if distance_remaining_table[caster] and distance_remaining_table[caster] > ability:GetLevelSpecialValueFor("distance_to_ready", (ability:GetLevel() - 1)) then
		distance_remaining_table[caster] = ability:GetLevelSpecialValueFor("distance_to_ready", (ability:GetLevel() - 1))
	end
end