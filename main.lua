#include "scripts/extras.lua"
#include "scripts/anim.lua"
#include "scripts/ui.lua"
#include "scripts/liveControls.lua"

config = {

	tool = {
		--Adjustable values in the internal config
		range = 100,
		minVox = 60,
		safeDist = 12,
		forcePoints = 3,
		selectionMode = 0,
		startingAmmo = 4000,
		consumeForMass = 5000,
		maxPower = 8,
		anim = {

			--Smooth versions of actual values
			appliedForceIndicator = 0,
			
			--Other variables used for animation
			spinTime = 0
		},
		partProperties = {

			tipRotation = 0
		},
		--Info from last frame
		lastAppliedForce = 0,

		--Settings you can adjust from game
		appliedForce = 0,
		magnetMode = 1,
		force = 80,
		
	},
	settings = {
		lightning = getBoolWithDefault("savegame.mod.magnetizerv2.settings.lightning", true),
		controls = getBoolWithDefault("savegame.mod.magnetizerv2.settings.controls", true)
	},
	magnetTypes = {
		[1] = {

			lightningDepth = 2
		},
		[2] = {

			lightningDepth = 12,
			range = 0.175
		},
		[3] = {

			lightningDepth = 16
		}
	}
}
local magnets = {}
local curDt = 0

--TEARDOWN NATIVE FUNCTIONS ----------

	function init()

		--SETUP TOOL ----------

			RegisterTool("magnetizerv2", "Magnetizer V2", "MOD/vox/model.vox")
			SetBool("game.tool.magnetizerv2.enabled", true)

			--Ammo
			SetFloat("game.tool.magnetizerv2.ammo", config.tool.startingAmmo)

		--SPRITES ----------

			line = LoadSprite("MOD/sprites/line.png")

		--SOUNDS ----------

			activeS = LoadLoop("MOD/snd/active.ogg")
			sparksS = LoadLoop("MOD/snd/sparks.ogg", 2)
			deselectS = LoadSound("MOD/snd/deselect.ogg")
			deselectAllS = LoadSound("MOD/snd/deselectAll.ogg")
			resetS = LoadSound("MOD/snd/reset.ogg")

		--SETUP ANIMATION CHANNELS ----------

			for x=1, 3 do

				targetChannels[x] = Transform()
			end
			
		--INITS ----------

			initUi()

	end
	function tick(dt)

		--DISPLAY AMMO ----------

			if GetBool("level.unlimitedammo") == false then

				SetString("game.tool.magnetizerv2.ammo.display", math.floor(GetFloat("game.tool.magnetizerv2.ammo")) .. "W")
			end

		--TICKS ----------

			tickControls()

		--SET STARTING VALUES ----------

			curDt = dt
			local currentAmmo = GetBool("level.unlimitedammo") and config.tool.startingAmmo or GetFloat("game.tool.magnetizerv2.ammo")
			config.tool.lastAppliedForce = config.tool.appliedForce

			menu.indicator = damp(
				menu.indicator,
				menu.value,
				4,
				dt
			)
			config.tool.anim.appliedForceIndicator = damp(
				config.tool.anim.appliedForceIndicator,
				config.tool.appliedForce,
				16,
				dt
			)

		--MAKE MAGNET BODIES ATTRACT EACH OTHER ----------
			
			if config.tool.appliedForce ~= 0 then
				
				handleMagnetMode(config.tool.magnetMode, dt)
			end

		--DESELECT TOO SMALL OBJECTS ----------

			for k, v in ipairs(magnets) do

				if getBodyVoxelCount(v.body) < config.tool.minVox then deselect(k) end
			end	

		--DRAW SELECTED OBJECTS ----------

			--Make outlines
			for k, v in ipairs(magnets) do

				DrawBodyOutline(v.body, 1, 0, 0, 0.5)
			end

		--STOP AND RESET VALUES IF NOT USING THE TOOL ----------

			if GetString("game.player.tool") ~= "magnetizerv2" then
				
				menu.value = 0
				return
			end

		--OPENING/CLOSING MENU ----------
			
			possibleControls.menu.visible = 1
			if InputPressed("mmb") or PauseMenuButton("Magnetizer V2") or (InputPressed("esc") and menu.value == 1) then

				if menu.value == 1 then closeMenu() else openMenu() end
			end

		--TOOL VARIABLES ----------

			local tool = GetToolBody()
			local toolT = GetBodyTransform(GetToolBody())
			local toolParts = GetBodyShapes(tool)

		--APPLY SETTINGS TO THE MAGNETIZER'S LOOK ----------

			--FIXED PARTS ----------

				SetShapeLocalTransform(toolParts[5], Transform(
					Vec(
						-0.15, -0.46, -0.9
					)	
				))

			--FORCE ----------

				SetShapeLocalTransform(toolParts[4], Transform(
					Vec(
						-0.025 + config.tool.anim.appliedForceIndicator * 0.125,
						-0.425,
						-0.9
					)
				))

			--MENU ----------

				targetChannels[3] = Transform(
					Vec(0, menu.value * -1.15, menu.value * -1),
					QuatEuler(menu.value * 90, 0, 0)
				)
				DrawBodyHighlight(
					tool,
					lerp(0, (math.sin(GetTime() * 4) + 2) / 24, menu.indicator)
				)
				if menu.value == 1 then

					SetCameraDof(
						menu.indicator * 1.6,
						menu.indicator * 0.25
					)
				end

			--RUN TOOL MOVEMENT ANIMATION ----------

				tickAnim(tool, dt)

		--ROTATE THE TOOL TIPS ----------

			rotateTips(dt * 1000 * config.tool.anim.appliedForceIndicator, toolParts)
		
		--DRAW TOOL ELECTRIC LINES ----------

			local posA = VecAdd(TransformToParentVec(
				toolT,
				Vec(0.275, -0.475, -1.45)),
				toolT.pos
			)
			local posB = VecAdd(TransformToParentVec(
				toolT,
				Vec(-0.275, -0.475, -1.45)),
				toolT.pos
			)

			local electricPower = math.abs(0.06 * config.tool.anim.appliedForceIndicator)
			local electricVisibility = math.abs(0.08 * config.tool.anim.appliedForceIndicator)
			electricity(
				posA,
				posB,
				electricPower,
				8,
				8,
				0,
				electricVisibility
			)

			--Electric sounds
			if electricVisibility > 0.01 then
			
				PlayLoop(sparksS, GetPlayerTransform().pos, electricVisibility * 5)
			end
		
		--STOP IF CAN'T USE TOOL ----------
			
			if not GetBool("game.player.canusetool") then return end

		--ADJUSTING POWER ----------

			possibleControls.scrollPower.visible = 1
			possibleControls.stepPower.visible = 1
			if #magnets > 0 then possibleControls.deselectAll.visible = 1 end

			if InputDown("shift") then

				SetBool("game.player.toolselect", false)
				SetBool("game.input.locktool", true)

				local addValue = -InputValue("mousewheel") + (InputPressed("1") and -1 or 0) + (InputPressed("2") and 1 or 0)

				local points = config.tool.forcePoints
				config.tool.appliedForce = clamp(
					math.floor((config.tool.appliedForce + addValue / points) * points) / points,
					-1,
					1
				)
			else

				SetBool("game.input.locktool", false)
			end
			
		--SELECTION/DESELECTION ----------

			local t = GetCameraTransform()
			local fwd = TransformToParentVec(t, Vec(0, 0, -1))

			--Shoot raycast
			local _, _, _, preShape = QueryRaycast(t.pos, fwd, config.tool.range)
			QueryRequire("physical dynamic")
			local hit, dist, normal, shape = QueryRaycast(t.pos, fwd, config.tool.range)
			if hit then

				local body = GetShapeBody(shape)
				if getBodyVoxelCount(body) >= config.tool.minVox then

					possibleControls.select.visible = 1

					if preShape == shape then

						DrawBodyHighlight(body, 0.15)
					else

						DrawBodyOutline(body, 0, 1, 1, 0.5)
					end

					if InputPressed("usetool") then config.tool.selectionMode = 0 end
					if InputDown("usetool") then

						
						local sameIndex = -1
						for k, v in ipairs(magnets) do

							if v.body == body then sameIndex = k end
						end

						if sameIndex == -1 then
								
							if config.tool.selectionMode == 1 then return end

							select(body)
							config.tool.selectionMode = 2
						else

							if config.tool.selectionMode == 2 then return end

							deselect(sameIndex)
							config.tool.selectionMode = 1
						end
					end
				end
			end

		--DESELECT ALL LOGIC ----------

			if InputPressed("grab") then

				if GetPlayerGrabBody() == 0 then

					deselectAll()
				end
			end
		
		--STOP IF NO AMMO ----------

			if currentAmmo <= 0 then config.tool.appliedForce = 0 end
			if config.tool.appliedForce ~= 0 then

				possibleControls.reset.visible = 1
			end

		--POWER SOUNDS ----------

			if config.tool.lastAppliedForce ~= config.tool.appliedForce then

				--Make sound
				UiSound("MOD/snd/step.ogg", 0.25, lerp(1, config.tool.appliedForce, 0.25))
			end

		--RESET VARIABLES ----------
			
			config.tool.lastAppliedForce = config.tool.appliedForce

		--RESET CONTROL ----------

			if InputPressed("r") and config.tool.appliedForce ~= 0 then

				config.tool.appliedForce = 0

				--Sound
				PlaySound(resetS, GetPlayerTransform().pos, 0.5)
			end

	end
	function draw()

		--DRAWS ----------

			drawControls(curDt)
			drawUi(curDt)

	end

--CUSTOM FUNCTIONS ----------

	function deselectAll()

		if #magnets < 1 then return end

		--Animate rotation
		targetChannels[1].rot = QuatEuler(0, -45, 0)

		PlaySound(deselectAllS, GetPlayerTransform().pos, 1)
		magnets = {}
	end
	function deselect(index)

		--Animate tool
		targetChannels[1].pos = Vec(0, 0, 0.25)

		PlaySound(deselectS, GetPlayerTransform().pos, 1)

		table.remove(magnets, index)
	end
	function rotateTips(amount, toolParts)

		--Getting shapes
		local tipA = toolParts[2]
		local tipB = toolParts[3]

		config.tool.partProperties.tipRotation = config.tool.partProperties.tipRotation + amount

		--Do rotation
		rotateShape(
			tipA,
			QuatEuler(0, 0, config.tool.partProperties.tipRotation),
			Vec(0.075, -0.075, 0),
			Transform(Vec(0.2, -0.4, -1.55), QuatEuler(90, 0, 0))
		)
		rotateShape(
			tipB,
			QuatEuler(0, 0, -config.tool.partProperties.tipRotation),
			Vec(0.075, -0.075, 0),
			Transform(Vec(-0.35, -0.4, -1.55), QuatEuler(90, 0, 0))
		)
	end
	function select(body)

		--Animate tool
		targetChannels[1].pos = Vec(0, 0, -0.7)
		
		--Play selection sound
		UiSound("MOD/snd/select.ogg", 1, #magnets / 12 + 1)

		local magnet = {}
		magnet["body"] = body

		table.insert(magnets, magnet)
	end
	--Make object a be attracted to object b
	--Apply for both objects to get the magnetic effect
	function attract(bodyA, massB, power, pointA, pointB, distance, dt)

		power = power * dt

		local velA = GetBodyVelocity(bodyA)
		local massA = GetBodyMass(bodyA)
		local delta = VecSub(pointA, pointB)
		local dir = VecNormalize(delta)
		local distPow = 1

		--Creates a falloff for the magnet field
		if distance < config.tool.safeDist and power > 0 then

			distPow = 1 - ((config.tool.safeDist - distance) / config.tool.safeDist)
		end
		
		--Calculate power
		local limit = math.abs(massA * config.tool.maxPower * config.tool.appliedForce)
		local f = -power * distPow * massB
		local lf = clamp(f, -limit, limit)
		local push = VecScale(dir, lf)

		--Actually apply the force
		ApplyBodyImpulse(bodyA, pointA, push)

		--Consuming Magnetizer ammo
		if GetBool("level.unlimitedammo") == false then

			local consume = math.abs(lf / config.tool.consumeForMass)
			SetFloat("game.tool.magnetizerv2.ammo", math.max(0, GetFloat("game.tool.magnetizerv2.ammo") - consume))
		end
	end
	function electricity(posA, posB, power, resolution, maxResolution, fadePower, alpha)

		if config.settings.lightning == false then return end

		--Cheap distance calculation
		local distance = VecLength(VecSub(posA, posB))

		--Fade out alpha when objects are close together
		alpha = alpha * math.min(lerp(1, distance / config.tool.safeDist, fadePower), 1)

		--How many points should the line have?
		local points = math.min(distance * resolution, maxResolution)

		local lastEnd = VecCopy(posA)
		for x=1, points do

			local startPos = VecCopy(lastEnd)
			local endPos = VecAdd(VecLerp(posA, posB, (x+1)/(points+1)), VecRand(-power, power, 3, 1, 1, 1))
			drawHDLine(startPos, endPos, line, math.log(distance) / 10, 0.9, 0.85, 1, alpha, false)
			lastEnd = endPos
		end
	end
	function handleMagnetMode(index, dt)

		local objects = {}
		local magnetizing = false
		local modes = {
			[1] = function()

				--MAGNET MODE A ----------
					--Magnet mode A is the original magnet mode which attracts selected objects together

					local power = config.tool.force * config.tool.appliedForce
					for kx, vx in ipairs(magnets) do

						local newObjects = {}
						for ky, vy in ipairs(magnets) do

							--Exclude cases where objects would be magnetized to their self or twice
							if kx ~= ky and kx < ky then

								local newObject = {}

								newObject["bodyA"] = vx.body;
								newObject["bodyB"] = vy.body;

								local posA = getPos(vx.body)
								local posB = getPos(vy.body)
								local _, pointA = GetBodyClosestPoint(vx.body, posB)
								local _, pointB = GetBodyClosestPoint(vy.body, posA)

								newObject["pointA"] = pointA
								newObject["pointB"] = pointB
								newObject["dist"] = VecLength(VecSub(pointA, pointB))

								table.insert(newObjects, newObject)
							end
						end
						for ky, vy in ipairs(newObjects) do
							
							--Attract object A
							attract(
								vy.bodyA,
								GetBodyMass(vy.bodyB),
								power,
								vy.pointA,
								vy.pointB,
								vy.dist,
								dt
							)
							--Attract object B
							attract(
								vy.bodyB,
								GetBodyMass(vy.bodyA),
								power,
								vy.pointB,
								vy.pointA,
								vy.dist,
								dt
							)
							magnetizing = true
						end

						--Cut the object table for the lightning effect to reduce lag
						local cutObjects = getNearby(newObjects, config.magnetTypes[1].lightningDepth, false)
						for ky, vy in ipairs(cutObjects) do

							table.insert(objects, vy)
						end
					end

			end,
			[2] = function()

				--MAGNET MODE B ----------
					--Magnet mode B attracts all nearby objects towards the seleted objects
				
					local newObjects = {}
					local power = config.tool.force * config.tool.appliedForce
					local radius = config.magnetTypes[2].range * math.abs(power)
					for kx, vx in ipairs(magnets) do

						--Find nearby objects
						QueryRequire("physical dynamic")
						QueryRejectBody(vx.body)
						local posA = getPos(vx.body)
						local foundObjects = QueryAabbBodies(
							VecAdd(posA, Vec(-radius, -radius, -radius)),
							VecAdd(posA, Vec(radius, radius, radius))
						)

						for ky, vy in ipairs(foundObjects) do

							if (getBodyVoxelCount(vy) > config.tool.minVox) then
							
								local newObject = {}

								newObject["bodyA"] = vx.body;
								newObject["bodyB"] = vy;

								local posB = getPos(vy)
								local _, pointA = GetBodyClosestPoint(vx.body, posB)
								local _, pointB = GetBodyClosestPoint(vy, posA)

								newObject["pointA"] = pointA
								newObject["pointB"] = pointB
								newObject["dist"] = VecLength(VecSub(pointA, pointB))

								table.insert(newObjects, newObject)
							end
						end

						magnetizing = true
					end
					for kx, vx in ipairs(newObjects) do
						
						--Attract object A
						attract(
							vx.bodyB,
							GetBodyMass(vx.bodyA),
							power * (vx.dist / radius),
							vx.pointB,
							vx.pointA,
							vx.dist,
							dt
						)
						--Attract object B
						attract(
							vx.bodyA,
							GetBodyMass(vx.bodyB),
							power * (vx.dist / radius),
							vx.pointA,
							vx.pointB,
							vx.dist,
							dt
						)
					end

					--Cut the object table for the lightning effect to reduce lag
					local cutObjects = getNearby(newObjects, config.magnetTypes[2].lightningDepth, false)
					for kx, vx in ipairs(cutObjects) do

						table.insert(objects, vx)
					end

			end,
			[3] = function()

				--MAGNET MODE C ----------
					--Magnet mode C attracts all selected objects towards the player

					local power = config.tool.force * config.tool.appliedForce
					local newObjects = {}
					for kx, vx in ipairs(magnets) do

						if GetString("game.player.tool") ~= "magnetizerv2" then return end
						if not GetBool("game.player.canusetool") then return end

						local toolBody = GetToolBody()
						local newObject = {}

						newObject["bodyA"] = vx.body

						local posA = getPos(vx.body)
						local posB = getPos(toolBody)
						local _, pointA = GetBodyClosestPoint(vx.body, posB)
						local _, pointB = GetBodyClosestPoint(toolBody, posA)

						newObject["pointA"] = pointA
						newObject["pointB"] = pointB
						newObject["dist"] = VecLength(VecSub(pointA, pointB))

						table.insert(newObjects, newObject)
					end
					for kx, vx in ipairs(newObjects) do

						--Attract towards player
						attract(
							vx.bodyA,
							GetBodyMass(vx.bodyA),
							power,
							vx.pointA,
							vx.pointB,
							vx.dist,
							dt
						)
						magnetizing = true
					end

					--Cut the object table for the lightning effect to reduce lag
					local cutObjects = getNearby(newObjects, config.magnetTypes[3].lightningDepth, true)
					for kx, vx in ipairs(cutObjects) do

						table.insert(objects, vx)
					end
			end
		}

		--Run one of them
		modes[index]()

		--VISUAL EFFECTS ----------

			for kx, vx in ipairs(objects) do
				
				electricity(
					vx.pointA,
					vx.pointB,
					math.abs(0.2 * config.tool.anim.appliedForceIndicator),
					2,
					16,
					0.5,
					math.abs(0.065 * config.tool.anim.appliedForceIndicator)
				)
			end

		--SOUND AND ANIMATION ----------
		if magnetizing and math.abs(config.tool.appliedForce) > 0 then

			PlayLoop(activeS, GetPlayerTransform().pos, 1)

			--Animate spin
			config.tool.anim.spinTime = config.tool.anim.spinTime + dt * config.tool.anim.appliedForceIndicator * 10
			targetChannels[2].rot = QuatEuler(0, 0, math.sin(config.tool.anim.spinTime) * 15)	
		else

			--Reset spin
			config.tool.anim.spinTime = 0
		end
	end