require "libraries/util"

function setupProjectileList()
	ProjectileList = {}
	ProjectileList.__index = ProjectileList
	ProjectileList.projectiles = {}

	function ProjectileList:AddProjectile(unit)
		self.projectiles[unit] = true
	end

	function ProjectileList:RemoveProjectile(unit)
		self.projectiles[unit] = nil
	end

	function ProjectileList:GetProjectiles()
		for projectile,_ in pairs(self.projectiles) do
			-- print(projectile)
			if projectile:IsNull() or not projectile:IsAlive() then
				self.projectiles[projectile] = nil
			end
		end

		return self.projectiles
	end

	function ProjectileList:GetProjectilesInArea(center, radius)
		local projectiles = {}
		for projectile,_ in pairs(self:GetProjectiles()) do
			local distance = (center - projectile:GetAbsOrigin()):Length2D()
			if distance <= radius then
				table.insert(projectiles, projectile)
			end
		end
		return projectiles
	end

	function ProjectileList:FreezeProjectiles()
		for projectile,_ in pairs(self:GetProjectiles()) do
			projectile.frozen = true
		end
	end

	function ProjectileList:UnfreezeProjectiles()
		for projectile,_ in pairs(self:GetProjectiles()) do
			projectile.frozen = false
		end
	end

	function ProjectileList:TrackingProjectileCreated(event)
		local origin = EntIndexToHScript(event.entindex_source_const)
		local target = EntIndexToHScript(event.entindex_target_const)
		local speed = event.move_speed
		local dodgeable = event.dodgeable
		local is_attack = event.is_attack

		-- not sure if these are useful for anything
		local ability = EntIndexToHScript(event.entindex_ability_const)
		local max_impact_time = event.max_impact_time
		local expire_time = event.expire_time

		local unit_name = origin:GetUnitName()
		if is_attack then
			local origin_location = origin:GetAttachmentOrigin(origin:ScriptLookupAttachment("attach_attack1"))
			local projectile = CreateUnitByName("npc_dummy_unit", origin_location, false, origin, origin, origin:GetTeamNumber())
			projectile:SetAbsOrigin(origin_location)
			ProjectileList:AddProjectile(projectile)

			local target_location = getTargetHitloc(target)
			local projectile_location = projectile:GetAbsOrigin()
			local direction = (target_location - projectile_location):Normalized()

			local dummy_speed = speed * 0.03
			local arrival_distance = target:GetModelRadius()
			local minimum_arrival_distance = dummy_speed / 2 + 5
			if arrival_distance < minimum_arrival_distance then arrival_distance = minimum_arrival_distance end

			local particle_name = getProjectileModel(unit_name)
			local particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, projectile)
			ParticleManager:SetParticleControl(particle, 0, projectile_location)
			ParticleManager:SetParticleControl(particle, 1, target_location)
			ParticleManager:SetParticleControl(particle, 2, Vector(speed,0,0))

			Timers:CreateTimer(0, function()
				if not projectile:IsNull() then
					if not projectile.frozen then
						ParticleManager:SetParticleControl(particle, 2, Vector(speed,0,0))
						if not target:IsNull() then
							target_location = getTargetHitloc(target)
							ParticleManager:SetParticleControl(particle, 1, target_location)
						end
						projectile_location = projectile:GetAbsOrigin()
						local distance = (target_location - projectile_location):Length2D()
						direction = (target_location - projectile_location):Normalized()

						if distance > arrival_distance then
							projectile:SetAbsOrigin(projectile_location + direction * dummy_speed)
							return 0.03
						else
							if not target:IsNull() and not origin:IsNull() then
								origin:PerformAttack(target, true, true, true, true, false)
							end
							ParticleManager:DestroyParticle(particle, false)
							Timers:CreateTimer(3, function()
								projectile:RemoveSelf()
							end)
						end
					else
						ParticleManager:SetParticleControl(particle, 2, Vector(0,0,0))
						return 0.03
					end
				end
			end)
			-- origin:AttackNoEarlierThan(origin:GetSecondsPerAttack())
			return false
		else
			return true
		end
	end
end