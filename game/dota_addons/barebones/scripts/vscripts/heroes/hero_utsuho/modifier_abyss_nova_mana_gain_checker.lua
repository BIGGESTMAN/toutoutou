modifier_abyss_nova_mana_gain_checker = class({})

function modifier_abyss_nova_mana_gain_checker:DeclareFunctions()
	return {MODIFIER_EVENT_ON_MANA_GAINED}
end

function modifier_abyss_nova_mana_gain_checker:IsHidden()
	return true
end

function modifier_abyss_nova_mana_gain_checker:OnManaGained(params)
	if IsServer() then
		local caster = self:GetParent()
		local ability = self:GetAbility()

		if not self.mana_gained then self.mana_gained = 0 end
		self.mana_gained = self.mana_gained + params.gain
		caster:SetModifierStackCount("modifier_abyss_nova_active", caster, self.mana_gained)

		if caster:GetMana() == caster:GetMaxMana() then
			local damage_type = ability:GetAbilityDamageType()
			local base_damage = ability:GetSpecialValueFor("base_damage")
			local damage_bonus_percent = ability:GetSpecialValueFor("damage_bonus_percent")
			local radius = ability:GetSpecialValueFor("radius")

			local damage = base_damage + damage_bonus_percent * self.mana_gained / 100

			local team = caster:GetTeamNumber()
			local origin = caster:GetAbsOrigin()
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
			local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
			local iOrder = FIND_ANY_ORDER
			local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
			for k,unit in pairs(targets) do
				ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
			end
			DebugDrawCircle(origin, Vector(255,0,0), 5, radius, true, 1)
			caster:RemoveModifierByName("modifier_abyss_nova_active")
		end
	end
end