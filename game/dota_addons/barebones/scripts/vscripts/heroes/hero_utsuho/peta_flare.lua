peta_flare = class({})

-- function peta_flare:OnUpgrade()
-- 	local ability = self
-- 	if ability:GetLevel() == 1 and IsServer() then
-- 		CT(0, function()
-- 			if IsValidEntity(self:GetCaster()) then
-- 				local entindexstr = tostring(self:GetCaster():entindex())
-- 				print(self:GetCursorPosition())
-- 				CustomNetTables:SetTableValue("cursor_positions", entindexstr, {position = self:GetCursorPosition()})
-- 				return 1/30
-- 			end
-- 		end)
-- 	end
-- end

function peta_flare:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local target_location = self:GetCursorPosition()
		local ability = self

		local range = ability:GetSpecialValueFor("range")
		local update_interval = ability:GetSpecialValueFor("update_interval")
		local paper_speed = ability:GetSpecialValueFor("speed")
		local speed = paper_speed * update_interval
		local base_damage = ability:GetSpecialValueFor("damage")
		local damage_type = ability:GetAbilityDamageType()
		local starting_radius = ability:GetSpecialValueFor("starting_radius")
		local ending_radius = ability:GetSpecialValueFor("ending_radius")
		local reduction_start_time = ability:GetSpecialValueFor("reduction_start_time")
		local damage_reduction_factor = ability:GetSpecialValueFor("damage_reduction_factor")

		local projectile = CreateUnitByName("npc_dummy_unit", caster:GetOrigin(), false, caster, caster, caster:GetTeamNumber())
		local particle = ParticleManager:CreateParticle("particles/utsuho/peta_flare/flare.vpcf", PATTACH_ABSORIGIN_FOLLOW, projectile)

		local direction = (target_location - projectile:GetAbsOrigin()):Normalized()
		local initial_distance = starting_radius * 0.8
		projectile:SetAbsOrigin(projectile:GetAbsOrigin() + direction * initial_distance)
		local units_hit = {}
		local distance_traveled = 0

		ProjectileList:AddProjectile(projectile)

		Timers:CreateTimer(0, function()
			if not projectile:IsNull() then
				if distance_traveled < range then
					if not projectile.frozen then
						projectile:SetAbsOrigin(projectile:GetAbsOrigin() + direction * speed)
						distance_traveled = distance_traveled + speed

						local team = caster:GetTeamNumber()
						local origin = projectile:GetAbsOrigin()
						local radius = radiusAtDistance(distance_traveled, range, paper_speed, starting_radius, ending_radius, reduction_start_time)
						local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
						local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
						local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
						local iOrder = FIND_ANY_ORDER
						local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
						-- DebugDrawCircle(origin, Vector(255,0,0), 5, radius, true, 0.25)

						local radius_reduction = 1 - (radius / starting_radius)
						local damage = (1 - radius_reduction * damage_reduction_factor) * base_damage

						for k,unit in pairs(targets) do
							if not units_hit[unit] then
								ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
								units_hit[unit] = true
							end
						end

						ParticleManager:SetParticleControl(particle, 1, Vector(radius / 5,0,0))
					end
					return update_interval
				else
					projectile:RemoveSelf()
				end
			end
		end)
	end
end

-- function peta_flare:GetAOERadius()
-- 	-- if IsServer() then
-- 	-- 	print("server")
-- 	-- 	local caster = self:GetCaster()
-- 	-- 	local target_location = self:GetCursorPosition()
-- 	-- 	local ability = self

-- 	-- 	local range = ability:GetSpecialValueFor("range")
-- 	-- 	local paper_speed = ability:GetSpecialValueFor("speed")
-- 	-- 	local starting_radius = ability:GetSpecialValueFor("starting_radius")
-- 	-- 	local ending_radius = ability:GetSpecialValueFor("ending_radius")
-- 	-- 	local reduction_start_time = ability:GetSpecialValueFor("reduction_start_time")

-- 	-- 	local distance = (caster:GetAbsOrigin() - target_location):Length2D()
-- 	-- 	local radius = nil
-- 	-- 	if distance <= range then radius = radiusAtDistance(distance, range, paper_speed, starting_radius, ending_radius, reduction_start_time) end
-- 	-- 	return radius
-- 	-- end
-- 	local entindexstr = tostring(self:GetCaster():entindex())
-- 	local nettable = CustomNetTables:GetTableValue("cursor_positions", entindexstr)
-- 	print(nettable.position)
-- end

function radiusAtDistance(distance, range, speed, starting_radius, ending_radius, reduction_start_time)
	local reduction_start_distance = speed * reduction_start_time
	local radius = nil
	if distance < reduction_start_distance then
		radius = starting_radius
	else
		local percent_along_path = (distance - reduction_start_distance) / (range - reduction_start_distance)
		local radius_change = ending_radius - starting_radius
		radius = starting_radius + percent_along_path * radius_change
	end
	return radius
end