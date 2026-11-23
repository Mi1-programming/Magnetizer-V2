--Rotates a shape around a pivot point
function rotateShape(handle, newQuat, pivot, rotT)

	--Spin around current pos
    local origin = Transform(VecAdd(pivot, rotT.pos))
    local handleT = TransformToLocalTransform(origin, rotT)
    origin.rot = QuatCopy(newQuat)
    local t = TransformToParentTransform(origin, handleT)

    SetShapeLocalTransform(handle, t)
end
--Generate a random vector
function VecRand(min, max, precision, xScale, yScale, zScale)

	return Vec(
		math.random(min*10^precision, max*10^precision)/10^precision*xScale,
		math.random(min*10^precision, max*10^precision)/10^precision*yScale,
		math.random(min*10^precision, max*10^precision)/10^precision*zScale
	)
end
--Gets the position of a body more accuratery
function getPos(body)

	return TransformToParentPoint(GetBodyTransform(body), GetBodyCenterOfMass(body))
end
--Gets the voxel amount of a body
function getBodyVoxelCount(body)

	shapes = GetBodyShapes(body)
	count = 0
	for x=1, #shapes do
		count = count + GetShapeVoxelCount(shapes[x])
	end
	return count
end
--Clamps value
function clamp(value, min, max)

	if value > max then
		value = max
	end
	if value < min then
		value = min
	end
	return value
end
--Lerps the value from a to b by time
function lerp(valA, valB, t)

	return valA + (valB - valA) * t
end
--Lerps colors (including alpha)
function lerpColor(colA, colB, t)

    return {
		lerp(colA[1], colB[1], t),
		lerp(colA[2], colB[2], t),
		lerp(colA[3], colB[3], t),
		lerp(colA[4], colB[4], t)
	}
end
--Renders a sprite based line
function drawHDLine(posA, posB, sprite, size, r, g, b, a, add)

	for x=0, 1 do
		DrawSprite(
			sprite,
			Transform(
				VecLerp(posA, posB, 0.5),
				QuatRotateQuat(
					QuatLookAt(posA, posB),
					QuatEuler(90, 0, x * 90)
				)
			),
			size, VecLength(VecSub(posA, posB)),
			r, g, b, a,
			true, add
		)
	end
end
--Smoothly move a value from A to B
function damp(a, b, speed, dt)

	return lerp(a, b, 1-math.exp(-speed*dt))
end
function VecDamp(a, b, speed, dt)

	return Vec(
		lerp(a[1], b[1], 1-math.exp(-speed*dt)),
		lerp(a[2], b[2], 1-math.exp(-speed*dt)),
		lerp(a[3], b[3], 1-math.exp(-speed*dt))
	)
end
function QuatDamp(a, b, speed, dt)

	return QuatSlerp(a, b, 1-math.exp(-speed*dt))
end
--Only returns the nearby objects
--The objects are meant to be tables with a distance variable named "dist"
function getNearby(objects, amount, invert)

	if invert then

		table.sort(objects, function(a, b) return a.dist > b.dist end)
	else

		table.sort(objects, function(a, b) return a.dist < b.dist end)
	end
	
	if amount == -1 then return objects end

	local cut = {}
	for x=1, amount do

		table.insert(cut, objects[x])
	end

	return cut
end
--Get a bool from the registry, but with a default value
function getBoolWithDefault(path, def)

	if HasKey(path) then return GetBool(path) else return def end
end

--EASINGS ----------

	function easeOut(value, power)

		return 1 - math.pow(1 - value, power)
	end
	function easeIn(value, power)

		for x=1, power do
			value = value * value
		end
		return value
	end