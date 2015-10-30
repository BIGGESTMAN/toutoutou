there_will_be_none = class({})
LinkLuaModifier("modifier_there_will_be_none_mark", "heroes/hero_flandre/modifier_there_will_be_none_mark.lua", LUA_MODIFIER_MOTION_NONE )


function there_will_be_none:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()
		local ability = self

		local radius = ability:GetSpecialValueFor("scepter_radius")
		local update_interval = ability:GetSpecialValueFor("update_interval")
		local mark_duration = ability:GetSpecialValueFor("mark_duration")

		if not caster:HasScepter() then
			target:AddNewModifier(caster, ability, "modifier_there_will_be_none_mark", {duration = mark_duration})
		else
			local team = caster:GetTeamNumber()
			local origin = self:GetCursorPosition()
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_HERO
			local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
			local iOrder = FIND_ANY_ORDER
			local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
			-- DebugDrawCircle(origin, Vector(0,255,0), 1, radius, true, 0.2)
			for k,unit in pairs(targets) do
				unit:AddNewModifier(caster, ability, "modifier_there_will_be_none_mark", {duration = mark_duration})
			end
		end
	end
end

function there_will_be_none:GetBehavior()
	if self:GetCaster():HasScepter() then
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE
	end

	return self.BaseClass.GetBehavior(self)
end

function there_will_be_none:GetAOERadius()
	return self:GetSpecialValueFor("scepter_radius")
end