function virudhakasSwordCast(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Spend a charge, unless charges modifier has expired during cast animation
	if caster:HasModifier("modifier_vajrapanis_charges") then
		local charge_modifier = caster:FindModifierByName("modifier_vajrapanis_charges")
		if charge_modifier:GetStackCount() > 1 then
			charge_modifier:DecrementStackCount()
		else
			charge_modifier:Destroy()
		end
	end

	--------------------------------------------- Dummy projectile ----------------------------------
	
	local speed = ability:GetLevelSpecialValueFor("speed", ability_level)

	local dummy_projectile = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, dummy_projectile, keys.projectile_modifier, {})
	dummy_projectile.units_hit = {}

	local target_location = target:GetAbsOrigin()
	local dummy_location = dummy_projectile:GetAbsOrigin()
	local direction = (target_location - dummy_location):Normalized()

	local dummy_speed = speed * 0.03
	local arrival_distance = 40
	local drag_distance = 50
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)

	local particle = ParticleManager:CreateParticle("particles/byakuren/virudhakas_sword.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy_projectile)
	ParticleManager:SetParticleControl(particle, 5, dummy_location + direction) -- Spear facing
	ParticleManager:SetParticleControl(particle, 1, dummy_location + direction * 60) -- Spear glow endpoints
	ParticleManager:SetParticleControl(particle, 2, dummy_location + direction * -90)

	Timers:CreateTimer(0, function()
		if not target:IsNull() then target_location = target:GetAbsOrigin() end
		dummy_location = dummy_projectile:GetAbsOrigin()
		local distance = (target_location - dummy_location):Length2D()
		direction = (target_location - dummy_location):Normalized()
		ParticleManager:SetParticleControl(particle, 5, dummy_location + direction) -- Spear facing
		ParticleManager:SetParticleControl(particle, 1, dummy_location + direction * 60) -- Spear glow endpoints
		ParticleManager:SetParticleControl(particle, 2, dummy_location + direction * -90)
		-- ParticleManager:SetParticleControl(particle, 2, dummy_location + direction * -90) -- Spear endcap flash endpoints
		-- ParticleManager:SetParticleControl(particle, 2, dummy_location + direction * -90)

		local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
		local damage_type = ability:GetAbilityDamageType()

		if distance > arrival_distance then
			-- Move projectile
			dummy_projectile:SetAbsOrigin(dummy_location + direction * dummy_speed)

			-- Check for units hit
			local team = caster:GetTeamNumber()
			local origin = dummy_location
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
			local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
			local iOrder = FIND_ANY_ORDER
			local radius = radius
			-- DebugDrawCircle(origin, Vector(180,40,40), 1, radius, true, 0.5)

			local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
			local damage = ability:GetLevelSpecialValueFor("damage", ability_level)

			for k,unit in pairs(targets) do
				if not dummy_projectile.units_hit[unit] and unit ~= target then
					ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
					dummy_projectile.units_hit[unit] = true
					ability:ApplyDataDrivenModifier(dummy_projectile, unit, "modifier_pulled", {})
					ability:ApplyDataDrivenModifier(caster, unit, "modifier_light_fragment", {})
				end
			end

			for unit,v in pairs(dummy_projectile.units_hit) do
				local direction_towards_spear = (origin - unit:GetAbsOrigin()):Normalized()
				local angle = direction:Dot(direction_towards_spear)

				local target_distance = (unit:GetAbsOrigin() - origin):Length2D()

				if target_distance > drag_distance and angle > 0 then
					local target_direction = (unit:GetAbsOrigin() - origin):Normalized()
					unit:SetAbsOrigin(origin + drag_distance * target_direction)
				end
			end
			return 0.03
		else
			-- Impale target and delete spear dummy
			if not target:IsNull() then
				ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})
				ability:ApplyDataDrivenModifier(caster, target, "modifier_impaled", {})
				ability:ApplyDataDrivenModifier(caster, target, "modifier_light_fragment", {})
			end
			dummy_projectile:RemoveSelf()

			-- Release dragged units
			for unit,v in pairs(dummy_projectile.units_hit) do
				unit:RemoveModifierByName("modifier_pulled")
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
			end
		end
	end)
end

function updateAbilityActivated(keys)
	if keys.caster:HasModifier("modifier_vajrapanis_charges") then
		keys.ability:SetActivated(true)
	else
		keys.ability:SetActivated(false)
	end
end