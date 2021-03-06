function spawnDoll(ability, target, caster, origin)
	local targeted_wire = false
	if target:HasModifier("modifier_trip_wire_unit") then targeted_wire = true end

	local wire_ability = caster:FindAbilityByName("trip_wire")
	local wire_level = wire_ability:GetLevel() - 1
	local max_dolls = wire_ability:GetLevelSpecialValueFor("max_dolls", wire_level)
	if not targeted_wire or #target.stored_dolls < max_dolls then
		local movement_interval = 0.03
		local ability_level = ability:GetLevel() - 1

		local allied_target = target:GetTeamNumber() == caster:GetTeamNumber()
		local doll_type = nil
		if allied_target then
			doll_type = "shanghai_doll"
		else
			doll_type = "hourai_doll"
		end
		local doll = CreateUnitByName(doll_type, origin, true, caster, caster, caster:GetTeamNumber())
		doll.target = target

		-- Set doll stats based on skill rank
		if ability_level > 0 then
			doll:CreatureLevelUp(ability_level)
		end

		if not caster.dolls then caster.dolls = {} end
		caster.dolls[doll] = true

		ability:ApplyDataDrivenModifier(caster, doll, "modifier_little_legion_doll", {})
		ability:ApplyDataDrivenModifier(caster, doll, "modifier_kill", {duration = ability:GetLevelSpecialValueFor("doll_duration", ability_level)})
		local speed = ability:GetLevelSpecialValueFor("dash_speed", ability_level) * 0.03

		-- Dash towards target
		Timers:CreateTimer(0, function()
			local direction = (target:GetAbsOrigin() - doll:GetAbsOrigin()):Normalized()
			local target_distance = (target:GetAbsOrigin() - doll:GetAbsOrigin()):Length2D()

			if not allied_target then
				doll:SetForceAttackTarget(target)

				if target_distance < doll:GetAttackRange() then -- Check if doll is in range
					local damage = ability:GetLevelSpecialValueFor("hourai_damage", ability_level)
					ApplyDamage({ victim = target, attacker = doll, damage = damage, damage_type = DAMAGE_TYPE_PHYSICAL})
					FindClearSpaceForUnit(doll, doll:GetAbsOrigin(), false)
				else
					doll:SetAbsOrigin(doll:GetAbsOrigin() + direction * speed)
					doll:SetForwardVector(direction)
					return 0.03
				end
			else
				if target_distance < doll:GetAttackRange() then -- Check if doll is in range
					if not targeted_wire then
						ability:ApplyDataDrivenModifier(doll, target, "modifier_little_legion_shanghai_buff", {})
						FindClearSpaceForUnit(doll, doll:GetAbsOrigin(), false)
					else
						removeDoll(doll, caster)
						storeDoll(target, ability_level)
					end
				else
					doll:SetAbsOrigin(doll:GetAbsOrigin() + direction * speed)
					doll:SetForwardVector(direction)
					return 0.03
				end
			end
		end)

		doll.tether_particle = ParticleManager:CreateParticle("particles/alice/"..doll_type.."_tether.vpcf", PATTACH_POINT_FOLLOW, doll)
		ParticleManager:SetParticleControlEnt(doll.tether_particle, 0, doll, PATTACH_POINT_FOLLOW, "attach_hitloc", doll:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(doll.tether_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	else
		ability:RefundManaCost()
		ability:EndCooldown()
	end
end

function removeDoll(doll, caster)
	doll:RemoveSelf()
	caster.dolls[doll] = nil
end

function storeDoll(wire, doll_level)
	local caster = wire:GetOwner()
	local wire_ability = caster:FindAbilityByName("trip_wire")
	local ability_level = wire_ability:GetLevel() - 1
	local max_dolls = wire_ability:GetLevelSpecialValueFor("max_dolls", ability_level)
	if #wire.stored_dolls < max_dolls then
		table.insert(wire.stored_dolls, doll_level)
	end
end