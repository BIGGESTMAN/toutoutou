LinkLuaModifier("modifier_flash_flood_debuff", "heroes/hero_nitori/modifier_flash_flood_debuff.lua", LUA_MODIFIER_MOTION_NONE )

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]

	local delay = ability:GetSpecialValueFor("delay")
	local duration = ability:GetSpecialValueFor("duration")
	local radius = ability:GetSpecialValueFor("radius")
	local damage = ability:GetSpecialValueFor("damage")
	local damage_type = ability:GetAbilityDamageType()
	local damage_interval = ability:GetSpecialValueFor("damage_interval")
	local debuff_duration = ability:GetSpecialValueFor("debuff_duration")
	local update_interval = ability:GetSpecialValueFor("update_interval")

	local dummy = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	ability:ApplyDataDrivenModifier(caster, dummy, "modifier_flash_flood_dummy", {})

	dummy.elapsed_duration = 0

	local rain_particle = ParticleManager:CreateParticle("particles/nitori/flash_flood.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(rain_particle, 0, target_point)
	ParticleManager:SetParticleControl(rain_particle, 4, Vector(radius,0,0)) -- Set particle radius
	ParticleManager:SetParticleControl(rain_particle, 5, Vector(math.pow(radius, 2) * math.pi / 40,0,0)) -- Set particle density -- note that this doesn't really work because of particle limits (i think?)

	local particle_vertical_offset = Vector(0,0,500)
	local drone_particle = ParticleManager:CreateParticle("particles/nitori/flash_flood_drone.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(drone_particle, 0, target_point + particle_vertical_offset)

	-- Deal damage
	Timers:CreateTimer(delay, function()
		if dummy.elapsed_duration < duration then
			dummy.elapsed_duration = dummy.elapsed_duration + damage_interval

			local team = caster:GetTeamNumber()
			local origin = target_point
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
			local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
			local iOrder = FIND_ANY_ORDER

			local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

			for k,unit in pairs(targets) do
				ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
			end

			return damage_interval
		else
			ParticleManager:DestroyParticle(rain_particle, false)
			ParticleManager:DestroyParticle(drone_particle, false)
			Timers:CreateTimer(1, function() -- Give debuffs a second to fall off before killing dummy
				dummy:RemoveSelf()
			end)
		end
	end)

	-- Add/refresh debuff
	Timers:CreateTimer(update_interval, function()
		if dummy.elapsed_duration < duration then
			local team = caster:GetTeamNumber()
			local origin = target_point
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
			local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
			local iOrder = FIND_ANY_ORDER
			DebugDrawCircle(origin, Vector(40,40,180), 1, radius, true, 0.5)

			local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

			for k,unit in pairs(targets) do
				unit:RemoveModifierByName("modifier_flash_flood_debuff") -- Remove old debuff so new flash flood doesn't refresh old debuff with a now nonexistent caster (the old dummy)
				unit:AddNewModifier(dummy, ability, "modifier_flash_flood_debuff", {duration = debuff_duration})
			end

			return update_interval
		end
	end)
end