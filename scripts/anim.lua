targetChannels = {}
local transformChannels = {}

local speed = 8
local inited = false

function initAnim()

    --Create channels which keep track of offsets
    for x=1, #targetChannels do
        transformChannels[x] = Transform()
    end

    inited = true
end
function tickAnim(tool, dt)

    if inited == false then initAnim() end

    --Progress animations
    for k, v in ipairs(targetChannels) do
        
        transformChannels[k].pos = VecDamp(transformChannels[k].pos, v.pos, speed, dt)
        transformChannels[k].rot = QuatDamp(transformChannels[k].rot, v.rot, speed, dt)

        v.pos = VecDamp(v.pos, Vec(), speed, dt)
        v.rot = QuatDamp(v.rot, Quat(), speed, dt)
    end

    --Add together all channels
    local transformPos = Vec()
    local transformRot = Quat()
    for k, v in ipairs(transformChannels) do

        transformPos = VecAdd(
            transformPos,
            v.pos
        )
        transformRot = QuatRotateQuat(
            transformRot,
            v.rot
        )
    end

    --Apply animations
    SetToolTransform(
        Transform(
            transformPos,
            transformRot
        )
    )
end