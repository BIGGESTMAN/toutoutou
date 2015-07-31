modifier_hanumans_dance = class({})

function modifier_hanumans_dance:OnCreated( kv )
	if IsServer() then
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() - 1
		self:StartIntervalThink(ability:GetLevelSpecialValueFor("update_interval", ability_level))
	end
end

function modifier_hanumans_dance:OnIntervalThink()
	if IsServer() then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() - 1

		if caster:HasModifier("modifier_vajrapanis_charges") or caster:HasModifier("modifier_dance_recastable") then
			ability:SetActivated(true)
		else
			ability:SetActivated(false)
		end
	end
end

function modifier_hanumans_dance:IsHidden()
	return true
end

function modifier_hanumans_dance:IsPurgable()
	return false
end

function modifier_hanumans_dance:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK,
			MODIFIER_EVENT_ON_ABILITY_EXECUTED }
end

function modifier_hanumans_dance:OnAttack( params )
	if params.attacker == self:GetParent() then
		if not self:GetCaster():HasModifier("modifier_dancing") then
			self:GetCaster():RemoveModifierByName("modifier_dance_recastable")
		end
	end
end

function modifier_hanumans_dance:OnAbilityExecuted( params )
	if params.unit == self:GetParent() then
		if params.ability ~= self:GetAbility() then
			self:GetCaster():RemoveModifierByName("modifier_dance_recastable")
		end
	end
end