function init()
	isWhiteHuman = false
  local eid = entity.id()
	
	if world.entitySpecies(eid) == "human" then
		local portrait = world.entityPortrait(eid, "head")
		if portrait then
			local image = portrait[1].image
			local hex = image:match("ffe2c5=([%x]+)")
			
			local min = effect.getParameter("min")
			local rgb = {tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))}
			
			isWhiteHuman = true
			for i = 1, 3 do
				if rgb[i] < min[i] then
					isWhiteHuman = false
					break
				end
			end
			
			if isWhiteHuman then
				effect.expire()
				return
			end
		end
	end
	
	particleCfg = effect.getParameter("particle")
	duration = effect.getParameter("duration", 2)
	timer = 0
	
	local box = mcontroller.boundBox()
	animator.setParticleEmitterOffsetRegion("death", box)
	animator.setParticleEmitterOffsetRegion("dijon", box)
	animator.playSound("start")
	
	effect.addStatModifierGroup({{stat = "invulnerable", amount = 1}})
end

function update(dt)
	if isWhiteHuman then return end
	
	if timer < 1 then
		timer = math.min(1, timer + dt / duration)
		if timer == 1 then
			spawnParts()
			killTicks = 2
			animator.burstParticleEmitter("death")
			animator.burstParticleEmitter("dijon")
		end
		
		effect.setParentDirectives(string.format("?fade=FFF;%s?border=2;FFFFFF%02x;FFF0?scalenearest=%s", timer, math.floor(timer*255), 1-(timer^8)))
		
		mcontroller.setVelocity{0,0}
		mcontroller.controlParameters({movementEnabled = false})
	end
	
	if killTicks and killTicks >= 0 then
		if killTicks == 0 then
			effect.addStatModifierGroup({{stat = "maxHealth", effectiveMultiplier = 0}})
		end
		killTicks = killTicks - 1
	end
end


local partsList = {"head", "frontarm", "backarm", "sleeve", "chest", "pants"}
function spawnParts()
	local eid = entity.id()
	
	local portrait = world.entityPortrait(eid, "full")
	local particles = {}
	
	for _,v in ipairs(portrait) do
		local found = false
		for _,part in ipairs(partsList) do
			if v.image:match(part) then found = true; break end
		end
		
		if found then makePart(particles, v.image) end
	end
	
	if #particles > 0 then
		world.spawnProjectile("invisibleprojectile", mcontroller.position(), 0, {0,0}, false, {timeToLive = 0, actionOnReap = particles})
	end
end

function makePart(t, image, dir, params)
	if dir and image:sub(1,1) ~= "/" then image = dir..image end
	
	local rect = root.nonEmptyRegion(image)
	if rect then
		image = image..string.format("?crop=%s;%s;%s;%s", table.unpack(rect))
		
		local p = sb.jsonMerge(particleCfg, params or {})
		p.image = image
		
		t[#t+1] = {action = "particle", specification = p}
	end
end