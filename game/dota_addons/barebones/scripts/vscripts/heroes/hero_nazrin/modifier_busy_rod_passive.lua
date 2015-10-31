modifier_busy_rod_passive = class({})

function modifier_busy_rod_passive:OnCreated( kv )
	if IsServer() then
		local ability = self:GetAbility()

		self:StartIntervalThink(ability:GetSpecialValueFor("update_interval"))
	end
end

function modifier_busy_rod_passive:OnIntervalThink()
	if IsServer() then
		local caster = self:GetParent()
		local ability = self:GetAbility()

		local radius = ability:GetSpecialValueFor("reveal_radius")
		local vision_duration = ability:GetSpecialValueFor("vision_duration")
		local gold_threshold_per_level = ability:GetSpecialValueFor("gold_threshold_per_level")

		local team = caster:GetTeamNumber()
		local origin = caster:GetAbsOrigin()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
		for k,unit in pairs(targets) do
			if unit:GetGold() >= gold_threshold_per_level * unit:GetLevel() then
				unit:AddNewModifier(caster, ability, "modifier_busy_rod_revealed", {duration = vision_duration})
			end
		end
	end
end

function modifier_busy_rod_passive:IsHidden()
	return true
end