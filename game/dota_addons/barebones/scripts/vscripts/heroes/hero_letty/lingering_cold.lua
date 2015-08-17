require "libraries/util"

function lingeringColdCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target_point = keys.target_points[1]

	-- Spend a charge
	caster.lingering_cold_charges = caster.lingering_cold_charges - 1

	local initial_radius = ability:GetLevelSpecialValueFor("initial_radius", ability_level)
	local end_radius = ability:GetLevelSpecialValueFor("end_radius", ability_level)
	local expansion_duration = ability:GetLevelSpecialValueFor("expansion_duration", ability_level)
	local update_interval = ability:GetLevelSpecialValueFor("update_interval", ability_level)
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)

	if not caster.ice_fields then caster.ice_fields = {} end
	local thinker = CreateModifierThinker(caster, ability, "modifier_lingering_cold_thinker", {}, target_point, caster:GetTeamNumber(), false)
	caster.ice_fields[thinker] = true

	local connected_ice_fields = {}
	thinker.radius = initial_radius

	local particle = ParticleManager:CreateParticle("particles/letty/lingering_cold.vpcf", PATTACH_ABSORIGIN_FOLLOW, thinker)
	ParticleManager:SetParticleControl(particle, 1, Vector(thinker.radius,0,0))
	ParticleManager:SetParticleControl(particle, 2, Vector(1,end_radius,1))
	ParticleManager:SetParticleControl(particle, 3, Vector(duration,1,1))
	ParticleManager:SetParticleControl(particle, 4, Vector(thinker.radius,1,(end_radius - thinker.radius) / expansion_duration))

	local elapsed_time = 0

	Timers:CreateTimer(0,function()
		if thinker.radius < end_radius then
			-- Update radius
			thinker.radius = thinker.radius + ((end_radius - initial_radius) / expansion_duration) * update_interval
			if thinker.radius > end_radius then thinker.radius = end_radius end
			ParticleManager:SetParticleControl(particle, 1, Vector(thinker.radius,0,0))
		end

		-- Tick down duration unless caster is in radius
		local caster_in_radius = (caster:GetAbsOrigin() - target_point):Length2D() < thinker.radius
		if not caster_in_radius then -- Don't need to check connected fields if already in this one
			for ice_field,v in pairs(connected_ice_fields) do
				if not ice_field:IsNull() then
					if (caster:GetAbsOrigin() - ice_field:GetAbsOrigin()):Length2D() < ice_field.radius then
						caster_in_radius = true
						break
					end
				end
			end
		end
		if not caster_in_radius then elapsed_time = elapsed_time + update_interval end

		if elapsed_time < duration then
			-- Check for overlapping ice fields
			for ice_field,v in pairs(caster.ice_fields) do
				if not ice_field:IsNull() then
					local overlapping = (ice_field:GetAbsOrigin() - thinker:GetAbsOrigin()):Length2D() < thinker.radius + ice_field.radius
					if not connected_ice_fields[ice_field] and overlapping then
						connected_ice_fields[ice_field] = true

						-- local connected_particle = ParticleManager:CreateParticle("particles/letty/ice_field_connection", PATTACH_POINT_FOLLOW, thinker)
						-- ParticleManager:SetParticleControlEnt(connected_particle, 0, thinker, PATTACH_POINT_FOLLOW, "attach_hitloc", thinker:GetAbsOrigin(), true)
						-- ParticleManager:SetParticleControlEnt(connected_particle, 1, ice_field, PATTACH_POINT_FOLLOW, "attach_hitloc", ice_field:GetAbsOrigin(), true)
					end
				end
			end

			-- Find number of Northern Winner allies in the field and connected fields
			local northern_winner_allies = {}

			local team1 = caster:GetTeamNumber()
			local origin1 = target_point
			local iTeam1 = DOTA_UNIT_TARGET_TEAM_FRIENDLY
			local iType1 = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
			local iFlag1 = DOTA_UNIT_TARGET_FLAG_NONE
			local iOrder1 = FIND_ANY_ORDER

			local targets1 = FindUnitsInRadius(team1, origin1, nil, thinker.radius, iTeam1, iType1, iFlag1, iOrder1, false)

			for k,unit in pairs(targets1) do
				if unit:HasModifier("modifier_northern_winner") then
					table.insert(northern_winner_allies, unit)
				end
			end

			for ice_field,v in pairs(connected_ice_fields) do
				if not ice_field:IsNull() then
					local team = caster:GetTeamNumber()
					local origin = ice_field:GetAbsOrigin()
					local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
					local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
					local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
					local iOrder = FIND_ANY_ORDER

					local targets = FindUnitsInRadius(team, origin, nil, ice_field.radius, iTeam, iType, iFlag, iOrder, false)

					for k,unit in pairs(targets) do
						if unit:HasModifier("modifier_northern_winner") and not tableContains(northern_winner_allies, unit) then
							table.insert(northern_winner_allies, unit)
						end
					end
				end
			end

			-- Apply debuff
			local team = caster:GetTeamNumber()
			local origin = target_point
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
			local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
			local iOrder = FIND_ANY_ORDER

			local targets = FindUnitsInRadius(team, origin, nil, thinker.radius, iTeam, iType, iFlag, iOrder, false)

			for k,unit in pairs(targets) do
				ability:ApplyDataDrivenModifier(caster, unit, "modifier_lingering_cold_debuff", {})
				local modifier = unit:FindModifierByName("modifier_lingering_cold_debuff")
				modifier.northern_winner_allies = #northern_winner_allies
			end

			return update_interval
		else
			-- print(#caster.ice_fields, caster.ice_fields[thinker]) -- I legit do not understand this at all
			caster.ice_fields[thinker] = false
			thinker:RemoveSelf()
			-- print(#caster.ice_fields, caster.ice_fields[thinker])
		end
	end)
end

function updateCharges(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local max_charges = ability:GetLevelSpecialValueFor("max_charges", ability_level)
	local charge_restore_time = ability:GetLevelSpecialValueFor("charge_restore_time", ability_level) / 10

	if not caster.lingering_cold_charges then caster.lingering_cold_charges = 0 end
	local remaining_time_for_charge = (1 - caster.lingering_cold_charges % 1) * charge_restore_time

	if caster.lingering_cold_charges < max_charges then
		caster.lingering_cold_charges = caster.lingering_cold_charges + ability:GetLevelSpecialValueFor("update_interval", ability_level) / charge_restore_time
	else
		caster.lingering_cold_charges = max_charges
	end

	if caster.lingering_cold_charges >= 1 then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_lingering_cold_charges", {})
		local old_stack_count = caster:GetModifierStackCount("modifier_lingering_cold_charges", caster)
		local new_stack_count = math.floor(caster.lingering_cold_charges)
		caster:SetModifierStackCount("modifier_lingering_cold_charges", caster, new_stack_count)
		if new_stack_count ~= old_stack_count and new_stack_count ~= max_charges and caster:IsAlive() then
			caster:FindModifierByName("modifier_lingering_cold_charges"):SetDuration(remaining_time_for_charge, true)
		end
	else
		caster:RemoveModifierByName("modifier_lingering_cold_charges")
		if ability:IsCooldownReady() then
			ability:StartCooldown(remaining_time_for_charge)
		end
	end
end

function checkRestoreCharges(keys)
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	if ability_level == 0 then keys.caster.lingering_cold_charges = ability:GetLevelSpecialValueFor("max_charges", ability_level) end
end

function checkNorthernWinnerDamage(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local northern_winner_ability = caster:FindAbilityByName("northern_winner")
	local northern_winner_ability_level = northern_winner_ability:GetLevel() - 1
	local target = keys.target

	if target:HasModifier("modifier_lingering_cold_debuff") then -- ............. ellipse
		local modifier = target:FindModifierByName("modifier_lingering_cold_debuff")
		local damage = northern_winner_ability:GetLevelSpecialValueFor("damage_per_second", northern_winner_ability_level) * ability:GetLevelSpecialValueFor("update_interval", ability_level) * modifier.northern_winner_allies
		local damage_type = northern_winner_ability:GetAbilityDamageType()
		ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})
	end
end