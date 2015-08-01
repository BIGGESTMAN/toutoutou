modifier_dancing = class({})

function modifier_dancing:OnCreated( kv )
	if IsServer() then
		local caster = self:GetCaster()
		-- for k,v in pairs(kv) do
		-- 	print(k,v)
		-- end
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() -1

		self.minimum_range = 75
		self.distance_traveled = 0
		self.total_dash_duration = caster:GetSecondsPerAttack()
		self.dash_range = ability:GetLevelSpecialValueFor("dash_range", ability_level)
		self.speed = self.dash_range / self.total_dash_duration

		self.target_point = nil
		self.direction = nil

		self:StartIntervalThink(ability:GetLevelSpecialValueFor("update_interval", ability_level))

		-- Place autoattack on cooldown afterward
		caster:AttackNoEarlierThan(caster:GetSecondsPerAttack())

		local animation_properties = {duration=self.total_dash_duration, activity=ACT_DOTA_ATTACK, rate=(25 / 30) / self.total_dash_duration, translate="meld"}
		StartAnimation(caster, animation_properties)
	end
end

function modifier_dancing:OnIntervalThink()
	if IsServer() then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() -1 

		if not self.target_point then
			self.target_point = self.target:GetAbsOrigin()
			self.direction = (self.target_point - caster:GetAbsOrigin()):Normalized()
			-- self.direction.z = 0

			caster:SetForwardVector(self.direction)
		end

		local distance = (self.target_point - caster:GetAbsOrigin()):Length2D()

		if distance > self.minimum_range and self.distance_traveled < self.dash_range then
			caster:SetAbsOrigin(caster:GetAbsOrigin() + self.direction * self.speed * 0.03)
			self.distance_traveled = self.distance_traveled + self.speed * 0.03
			return 0.03
		else
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

			local team = caster:GetTeamNumber()
			local origin = caster:GetAbsOrigin() + caster:GetForwardVector() * caster:GetAttackRange()
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
			local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
			local iOrder = FIND_ANY_ORDER
			local radius = ability:GetLevelSpecialValueFor("radius", ability_level) * (1 + ability:GetLevelSpecialValueFor("radius_increase", ability_level) * self.prior_slashes)
			DebugDrawCircle(origin, Vector(0,255,0), 5, radius, true, 2)
			local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
			local bonus_damage = ability:GetLevelSpecialValueFor("bonus_damage", ability_level) * (1 + ability:GetLevelSpecialValueFor("damage_increase", ability_level) * self.prior_slashes)
			local damage_type = ability:GetAbilityDamageType()

			for k,unit in pairs(targets) do
				caster:PerformAttack(unit, true, true, false, true)
				ApplyDamage({victim = unit, attacker = caster, damage = bonus_damage, damage_type = damage_type})
			end

			caster:RemoveModifierByName("modifier_dancing")

			local particle = ParticleManager:CreateParticle("particles/byakuren_sword.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(particle, 2, origin)
		end
	end
end

function modifier_dancing:IsHidden()
	return true
end

function modifier_dancing:IsPurgable()
	return false
end

function modifier_dancing:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	}

	return state
end