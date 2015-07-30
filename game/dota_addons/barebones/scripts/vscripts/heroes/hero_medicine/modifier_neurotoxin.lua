modifier_neurotoxin = class({})

function modifier_neurotoxin:OnCreated( kv )
	if IsServer() then
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() - 1
		 ability:GetLevelSpecialValueFor("update_interval", ability_level)
		self.slow_percent = 0
		self:StartIntervalThink(ability:GetLevelSpecialValueFor("update_interval", ability_level))
	end
end

function modifier_neurotoxin:OnIntervalThink()
	if IsServer() then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() - 1
		local slow_per_second = ability:GetLevelSpecialValueFor("slow_per_second", ability_level)
		local update_interval = ability:GetLevelSpecialValueFor("update_interval", ability_level)
		local spread_range = ability:GetLevelSpecialValueFor("spread_range", ability_level)
		local target = self:GetParent()
		if not target:HasModifier("modifier_neurotoxin_sleep") then
			if self.slow_percent <= -100 then
				self:Destroy()
				target:AddNewModifier(caster, self:GetAbility(), "modifier_neurotoxin_sleep", {duration = self:GetRemainingTime()})

				local team = caster:GetTeamNumber()
				local point = target:GetAbsOrigin()
				local radius = spread_range
				local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
				local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
				local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
				local iOrder = FIND_CLOSEST

				local targets = FindUnitsInRadius(team, point, nil, radius, iTeam, iType, iFlag, iOrder, false)
				for k,unit in ipairs(targets) do
					if unit ~= target and not unit:HasModifier("modifier_neurotoxin") and not unit:HasModifier("modifier_neurotoxin_sleep") then
						unit:AddNewModifier(caster, self:GetAbility(), "modifier_neurotoxin", {duration = self:GetDuration()})
						EmitSoundOn("Hero_Bane.BrainSap", unit)

						local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_undying/undying_decay_strength_xfer.vpcf", PATTACH_POINT_FOLLOW, target)
						ParticleManager:SetParticleControl(particle,2,target:GetAbsOrigin())
						ParticleManager:SetParticleControl(particle,1,unit:GetAbsOrigin())
						ParticleManager:SetParticleControl(particle,0,target:GetAbsOrigin())

						break
					end
				end
			else
				self.slow_percent = self.slow_percent - update_interval * slow_per_second
			end
		end
	end
end

function modifier_neurotoxin:GetModifierMoveSpeedBonus_Percentage()
	return self.slow_percent
end

function modifier_neurotoxin:IsHidden()
	return false
end

function modifier_neurotoxin:IsPurgable()
	return false
end

function modifier_neurotoxin:IsDebuff()
	return true
end

function modifier_neurotoxin:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end