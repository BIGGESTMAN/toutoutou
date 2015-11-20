require "libraries/popups"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local update_interval = ability:GetSpecialValueFor("update_interval")
	local duration = ability:GetSpecialValueFor("duration")
	local gold_drain_percent = ability:GetSpecialValueFor("gold_drain_percent")
	local damage_type = ability:GetAbilityDamageType()
	local damage_interval = ability:GetSpecialValueFor("damage_interval")
	local damage = ability:GetSpecialValueFor("total_damage") / (duration / damage_interval + 1)
	local latch_distance = 40
	if target:IsBuilding() then
		damage = damage * (1 - ability:GetSpecialValueFor("building_damage_penalty") / 100)
		latch_distance = 170
	end
	local latched = false
	local duration_elapsed = 0
	local damage_ticks = 0

	caster.rats_active = caster.rats_active + 1

	local rat = CreateUnitByName("clever_commander_rat", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
	ability:ApplyDataDrivenModifier(caster, rat, "modifier_clever_commander_rat", {})
	rat.gold_stolen = 0

	-- Set rat stats based on skill rank
	local ability_level = ability:GetLevel() - 1
	if ability_level > 0 then rat:CreatureLevelUp(ability_level) end

	local tether_particle = ParticleManager:CreateParticle("particles/alice/hourai_doll_tether.vpcf", PATTACH_POINT_FOLLOW, rat)
	ParticleManager:SetParticleControlEnt(tether_particle, 0, rat, PATTACH_POINT_FOLLOW, "attach_hitloc", rat:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(tether_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

	CT(0, function()
		if IsValidEntity(rat) and rat:IsAlive() then
			if duration_elapsed < duration and IsValidEntity(target) and target:IsAlive() then
				if not latched then
					rat:SetForceAttackTarget(target)
					local distance = (rat:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
					if distance < latch_distance then
						latched = true
						ability:ApplyDataDrivenModifier(caster, target, "modifier_clever_commander_debuff", {})
						target:FindModifierByName("modifier_clever_commander_debuff").rat = rat
						target:FindModifierByName("modifier_clever_commander_debuff").gold_drain_percent = gold_drain_percent
						ApplyDamage({victim = target, attacker = rat, damage = damage, damage_type = damage_type})
					end
				else
					if not target:IsBuilding() then FindClearSpaceForUnit(rat, target:GetAbsOrigin(), true) end
					duration_elapsed = duration_elapsed + update_interval
					if duration_elapsed / (damage_ticks + 1) >= damage_interval then
						ApplyDamage({victim = target, attacker = rat, damage = damage, damage_type = damage_type})
						damage_ticks = damage_ticks + 1
					end
				end
			else
				if rat:GetForceAttackTarget() then
					ParticleManager:SetParticleControlEnt(tether_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
					rat:SetForceAttackTarget(nil)
					rat:MoveToNPC(caster)
					target:RemoveModifierByName("modifier_clever_commander_debuff")
				end
				local distance = (rat:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
				if distance < latch_distance then
					if rat.gold_stolen > 0 then
						caster:ModifyGold(rat.gold_stolen, false, DOTA_ModifyGold_AbilityCost)
						PopupGoldGain(caster, rat.gold_stolen)
					end
					rat:RemoveSelf()
					caster.rats_active = caster.rats_active - 1
				end
			end
			return update_interval
		else
			if IsValidEntity(target) and target:IsAlive() then
				target:RemoveModifierByName("modifier_clever_commander_debuff")
			end
			ParticleManager:DestroyParticle(tether_particle, false)
		end
	end)
end

function onDeath(keys)
	local rat = keys.unit
	local killer = keys.attacker
	local caster = keys.caster

	if killer:IsRealHero() and rat.gold_stolen > 0 then
		killer:ModifyGold(rat.gold_stolen, false, DOTA_ModifyGold_AbilityCost)
		PopupGoldGain(killer, rat.gold_stolen)
	end
	caster.clever_commander_charges = caster.clever_commander_charges - 1
	caster.rats_active = caster.rats_active - 1
end

function updateCharges(keys)
	local caster = keys.caster
	local ability = keys.ability
	local max_charges = ability:GetSpecialValueFor("max_rats")
	local charge_restore_time = ability:GetSpecialValueFor("charge_restore_time")
	local update_interval = ability:GetSpecialValueFor("update_interval")

	if not caster.clever_commander_charges then caster.clever_commander_charges = 0 end
	local remaining_time_for_charge = (1 - caster.clever_commander_charges % 1) * charge_restore_time

	if caster.clever_commander_charges < max_charges then
		caster.clever_commander_charges = caster.clever_commander_charges + update_interval / charge_restore_time
	else
		caster.clever_commander_charges = max_charges
	end

	if caster.clever_commander_charges >= 1 then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_clever_commander_charges", {})
		local old_stack_count = caster:GetModifierStackCount("modifier_clever_commander_charges", caster)
		local new_stack_count = math.floor(caster.clever_commander_charges)
		caster:SetModifierStackCount("modifier_clever_commander_charges", caster, new_stack_count)
		if new_stack_count ~= old_stack_count and new_stack_count ~= max_charges and caster:IsAlive() then
			caster:FindModifierByName("modifier_clever_commander_charges"):SetDuration(remaining_time_for_charge, true)
		end
	else
		caster:RemoveModifierByName("modifier_clever_commander_charges")
		if ability:IsCooldownReady() then
			ability:StartCooldown(remaining_time_for_charge)
		end
	end

	if not caster.rats_active then caster.rats_active = 0 end
	ability:SetActivated(caster.clever_commander_charges >= 1 + caster.rats_active)
end

function spellUpgraded(keys)
	local caster = keys.caster
	local ability = keys.ability

	if ability:GetLevel() == 1 then caster.clever_commander_charges = ability:GetSpecialValueFor("max_rats") end
end