require "heroes/hero_murasa/anchors"

function pullAnchors(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local team = caster:GetTeamNumber()
	local origin = keys.target_points[1]
	local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local iType = DOTA_UNIT_TARGET_BASIC
	local iFlag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE
	local iOrder = FIND_ANY_ORDER
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		if unit:GetUnitName() == "anchor" and not unit:HasModifier("modifier_pulled") then
			pullAnchor(caster, ability, caster:GetAbsOrigin(), unit)
		end
	end

	if #targets > 0 then EmitSoundOn("Touhou.Anchor_Cast", caster) end
end