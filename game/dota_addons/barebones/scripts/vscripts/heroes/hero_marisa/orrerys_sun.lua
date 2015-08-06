function orrerysSunStart( event )
	local caster = event.caster
	if (caster:IsAlive()) then
		local ability = event.ability
		local orbs = ability:GetLevelSpecialValueFor( "orbs", ability:GetLevel() - 1 )
		local unit_name = "orrerys_sun_orb"

		-- Initialize the table to keep track of all orbs
		if caster.orbs then
			for k,orb in pairs(caster.orbs) do
				orb:RemoveSelf()
			end
		end
		caster.orbs = {}

		local particles = {"particles/orrerys_sun_yellow.vpcf", "particles/orrerys_sun_green.vpcf", "particles/orrerys_sun_orange.vpcf",
						   "particles/orrerys_sun_pink.vpcf", "particles/orrerys_sun_blue.vpcf", "particles/orrerys_sun_red.vpcf"}
		for i=1,orbs do
			local unit = CreateUnitByName(unit_name, caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
			local particle = ParticleManager:CreateParticle(particles[#caster.orbs + 1], PATTACH_ABSORIGIN, unit)
			ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_ABSORIGIN, "attach_origin", unit:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(particle, 0, unit, PATTACH_ABSORIGIN, "attach_origin", unit:GetAbsOrigin(), true)

			ability:ApplyDataDrivenModifier(caster, unit, "modifier_orrerys_sun_orb", {})
			
			-- Add the spawned unit to the table
			table.insert(caster.orbs, unit)
		end
		
		caster.orbs_angle = 0
	end
end

-- Movement logic for each orb
function updateOrbs( event )
	local frozen = false

	local caster = event.caster
	local caster_location = caster:GetAbsOrigin()
	local ability = event.ability
	local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
	local vertical_distance_from_caster = ability:GetLevelSpecialValueFor( "vertical_distance_from_caster", ability:GetLevel() - 1 )
	local number_of_orbs = #caster.orbs

	local rotation_point = caster_location + Vector(0,0,1) * vertical_distance_from_caster

	-- Make orbs spin
	local rotation_time = ability:GetLevelSpecialValueFor("rotation_time", ability:GetLevel() - 1)
	caster.orbs_angle = caster.orbs_angle + (360 / rotation_time) * ability:GetLevelSpecialValueFor("orb_update_interval", ability:GetLevel() - 1)

	local overallAngleInRadians = 0
	if not frozen then
		overallAngleInRadians = caster.orbs_angle * math.pi / 180
	end
	local prototype_target_point = rotation_point + Vector(math.sin(overallAngleInRadians), math.cos(overallAngleInRadians), 0) * radius

	for orb_number=1, number_of_orbs do
		local angle = (360 / number_of_orbs) * (orb_number - 1)
		local target_point = RotatePosition(rotation_point, QAngle(0,angle,0), prototype_target_point)
		caster.orbs[orb_number]:SetAbsOrigin(target_point)
	end
end

-- Fire autoattack bolts when caster attacks
function orrerysSunAttack( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	for i=1,ability:GetLevelSpecialValueFor("orbs", ability:GetLevel() - 1) do
		Timers:CreateTimer(i * ability:GetLevelSpecialValueFor("delay_between_orb_attacks", ability:GetLevel() - 1), function()
			caster.orbs[i]:PerformAttack(target, true, true, true, true )
		end)
	end
end

function orbAttackHit( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	local damage_table = {}
		damage_table.attacker = caster
		damage_table.victim = target
		damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
		damage_table.ability = ability
		damage_table.damage = caster:GetAverageTrueAttackDamage() / 10

	ApplyDamage(damage_table)
end

-- Kill all units when the owner dies
function endOrrerysSun( event )
	local caster = event.caster
	local targets = caster.orbs or {}

	for _,unit in pairs(targets) do
	   	if unit and IsValidEntity(unit) then
	        unit:ForceKill(false)
    	end
	end

	caster.orbs = {}
	caster.orbs_angle = 0
end

function spellCast( event )
	local caster = event.caster
	if not event.event_ability:IsItem() and event.event_ability ~= caster:FindAbilityByName("blazing_star_reverse") then
		fireLasers(caster, event.ability)
	end
end

function fireLasers(caster, ability)
	local ability_level = ability:GetLevel() - 1

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_CLOSEST

	for i=1,ability:GetLevelSpecialValueFor("orbs", ability:GetLevel() - 1) do
		Timers:CreateTimer(i * ability:GetLevelSpecialValueFor("delay_between_orb_attacks", ability:GetLevel() - 1), function()
			fireLaser(caster, ability, caster.orbs[i])
		end)
	end
end

function fireLaser(caster, ability, orb)
	local ability_level = ability:GetLevel() - 1
	local search_radius = ability:GetLevelSpecialValueFor("search_radius", ability_level)

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_CLOSEST

	local units = FindUnitsInRadius(team, orb:GetAbsOrigin(), nil, search_radius, iTeam, iType, iFlag, iOrder, false)
	if #units > 0 then
		local target = units[RandomInt(1, #units)]
		fireLaserAt(caster, ability, orb, target)
		orb:EmitSound("Hero_Tinker.Laser")
	end
end

function fireLaserAt(caster, ability, orb, target)
	local orb_location = orb:GetAbsOrigin()
	local ability_level = ability:GetLevel() - 1
	local range = ability:GetLevelSpecialValueFor("search_radius", ability_level)
	local radius = ability:GetLevelSpecialValueFor("laser_radius", ability_level)
	local particle_name = "particles/units/heroes/hero_tinker/tinker_laser.vpcf"
	local thinkerRadius = radius * 1.5
	local targetDirection = (target:GetAbsOrigin() - orb_location):Normalized()

	local targets = {}

	local number_of_thinkers = math.ceil(range / radius)
	local distance_per_thinker = (range / number_of_thinkers)
	local thinkers = {}
	for i=1, number_of_thinkers do
		local thinker = CreateUnitByName("npc_dota_invisible_vision_source", orb_location, false, caster, caster, caster:GetTeam() )
		thinkers[i] = thinker

		thinker:SetDayTimeVisionRange( thinkerRadius )
		thinker:SetNightTimeVisionRange( thinkerRadius )

		thinker:SetAbsOrigin(orb_location + targetDirection * (distance_per_thinker * (i-1) + thinkerRadius / 2))
		ability:ApplyDataDrivenModifier(caster, thinker, "modifier_orrerys_sun_dummy", {})

		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_CLOSEST

		local possible_targets = FindUnitsInRadius(team, thinker:GetAbsOrigin(), nil, thinkerRadius, iTeam, iType, iFlag, iOrder, false)
		for k,unit in pairs(possible_targets) do
			-- Calculate distance
			local pathStartPos	= orb_location * Vector( 1, 1, 0 )
			local pathEndPos	= pathStartPos + targetDirection * range

			local distance = DistancePointSegment(unit:GetAbsOrigin() * Vector( 1, 1, 0 ), pathStartPos, pathEndPos )
			if distance <= radius and not tableContains(targets, unit) then
				table.insert(targets, unit)
			end
		end
	end

	for k,thinker in pairs(thinkers) do
		thinker:RemoveSelf()
	end

	--print("laser hit target:", tableContains(targets, target))

	for k,unit in pairs(targets) do
		ApplyDamage({ victim = unit, attacker = caster, damage = ability:GetLevelSpecialValueFor("laser_damage", ability_level),
					damage_type = ability:GetAbilityDamageType()})
	end

	-- Particle
	local particle = ParticleManager:CreateParticle(particle_name, PATTACH_POINT_FOLLOW, orb)
	ParticleManager:SetParticleControl(particle,9,orb_location)	
	ParticleManager:SetParticleControl(particle,1,target:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle,0,orb_location)

	-- Sound
	-- orb:EmitSound("Hero_Tinker.Laser")
end

function tableContains(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return true
        end
    end
    return false
end

function DistancePointSegment( p, v, w )
	local l = w - v
	local l2 = l:Dot( l )
	t = ( p - v ):Dot( w - v ) / l2
	if t < 0.0 then
		return ( v - p ):Length2D()
	elseif t > 1.0 then
		return ( w - p ):Length2D()
	else
		local proj = v + t * l
		return ( proj - p ):Length2D()
	end
end