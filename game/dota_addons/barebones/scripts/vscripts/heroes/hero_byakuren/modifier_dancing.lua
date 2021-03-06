modifier_dancing = class({})

function modifier_dancing:OnCreated( kv )
	if IsServer() then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() -1
		self.target = EntIndexToHScript(kv.target)
		self.target_point = self.target:GetAbsOrigin()
		self.prior_slashes = kv.prior_slashes

		self.direction = (self.target_point - caster:GetAbsOrigin()):Normalized()
		caster:SetForwardVector(self.direction)

		local base_dash_duration = 0.8
		self.minimum_range = 75
		self.distance_traveled = 0
		self.dash_range = ability:GetLevelSpecialValueFor("dash_range", ability_level)
		local distance = (self.target_point - caster:GetAbsOrigin()):Length2D()
		if distance < self.minimum_range then
			self.dash_range = distance
		end

		-- If Superhuman is enabled and sufficient charges, add bonus attack speed
		if caster:HasModifier("modifier_brilliance_of_mahavairocana_active") and caster:HasModifier("modifier_vajrapanis_charges") then
			local superhuman_cost = ability:GetSpecialValueFor("superhuman_cost")
			local charge_modifier = caster:FindModifierByName("modifier_vajrapanis_charges")
			if charge_modifier:GetStackCount() >= superhuman_cost then
				caster:AddNewModifier(caster, ability, "modifier_hanumans_dance_as_bonus", {})
				if charge_modifier:GetStackCount() > superhuman_cost then
					charge_modifier:SetStackCount(charge_modifier:GetStackCount() - superhuman_cost)
				else
					charge_modifier:Destroy()
				end
			end
			-- Manually set cooldown, because this happens after the cast technically -- disabled for now
			-- ability:EndCooldown()
			-- ability:StartCooldown(caster:GetSecondsPerAttack())
		end

		local total_dash_duration = base_dash_duration * caster:GetSecondsPerAttack() / caster:GetBaseAttackTime()
		self.speed = self.dash_range / total_dash_duration

		-- Place autoattack on cooldown afterward -- disabled for now
		-- caster:AttackNoEarlierThan(caster:GetSecondsPerAttack())

		-- Remove superhuman bonus attackspeed
		caster:RemoveModifierByName("modifier_hanumans_dance_as_bonus")

		local animation_properties = {duration=total_dash_duration, activity=ACT_DOTA_CAST_ABILITY_1, rate=(15 / 30) / total_dash_duration}
		StartAnimation(caster, animation_properties)
		
		self:StartIntervalThink(ability:GetLevelSpecialValueFor("update_interval", ability_level))
	end
end

function modifier_dancing:OnIntervalThink()
	if IsServer() then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() -1 
		local target = self.target
		local target_point = self.target_point

		-- Virudhaka's Sword light fragments interaction -- dash instantly
		if target:HasModifier("modifier_virudhakas_sword_light_fragment") then
			local dash_particle = ParticleManager:CreateParticle("particles/byakuren/hanumans_dash_instant.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(dash_particle, 0, caster:GetAbsOrigin())

			local direction = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Normalized()
			caster:SetAbsOrigin(target:GetAbsOrigin() + direction * self.minimum_range)
			slash(caster, ability, self)

			ParticleManager:SetParticleControl(dash_particle, 1, caster:GetAbsOrigin())
		else
			local distance = (target_point - caster:GetAbsOrigin()):Length2D()
			if self.distance_traveled < self.dash_range then
				if distance > self.minimum_range then
					caster:SetAbsOrigin(caster:GetAbsOrigin() + self.direction * self.speed * 0.03)
				end
				self.distance_traveled = self.distance_traveled + self.speed * 0.03
			else
				slash(caster, ability, self)
			end
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
	[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}

	return state
end

function slash(caster, ability, modifier)
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

	local ability_level = ability:GetLevel()

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin() + caster:GetForwardVector() * caster:GetAttackRange()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level) * (1 + ability:GetLevelSpecialValueFor("radius_increase", ability_level) * modifier.prior_slashes)

	local bonus_damage = ability:GetLevelSpecialValueFor("bonus_damage", ability_level) * (1 + ability:GetLevelSpecialValueFor("damage_increase", ability_level) * modifier.prior_slashes)
	local damage_type = ability:GetAbilityDamageType()
	-- DebugDrawCircle(origin, Vector(0,255,0), 5, radius, true, 2)
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		caster:PerformAttack(unit, true, true, false, true, false)
		ApplyDamage({victim = unit, attacker = caster, damage = bonus_damage, damage_type = damage_type})
		local hit_particle = ParticleManager:CreateParticle("particles/byakuren/hanumans_dance_slash_hit.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(hit_particle, 0, unit:GetAbsOrigin())
	end

	caster:RemoveModifierByName("modifier_dancing")

	-- local particle = ParticleManager:CreateParticle("particles/byakuren/hanumans_dance_slash_b.vpcf", PATTACH_ABSORIGIN, caster)
	local particle = ParticleManager:CreateParticle("particles/byakuren/hanumans_dance_slash_alt.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 2, origin)
end