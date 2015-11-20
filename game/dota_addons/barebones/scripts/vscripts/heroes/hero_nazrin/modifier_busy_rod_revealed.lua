modifier_busy_rod_revealed = class({})

function modifier_busy_rod_revealed:OnCreated( kv )
	if IsServer() then
		local ability = self:GetAbility()
		local caster = self:GetCaster()

		self:GetParent():AddNewModifier(caster, ability, "modifier_truesight", {duration = self:GetDuration()})
	end
end

function modifier_busy_rod_revealed:OnRefresh( kv )
	if IsServer() then
		local ability = self:GetAbility()
		local caster = self:GetCaster()

		self:GetParent():AddNewModifier(caster, ability, "modifier_truesight", {duration = self:GetDuration()})
	end
end

function modifier_busy_rod_revealed:IsDebuff()
	return true
end

function modifier_busy_rod_revealed:CheckState()
	local state = {
	[MODIFIER_STATE_PROVIDES_VISION] = true,
	}
 
	return state
end