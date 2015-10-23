function setupProjectileList()
	ProjectileList = {}
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
end