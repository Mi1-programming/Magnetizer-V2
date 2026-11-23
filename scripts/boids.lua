local boids = {}
local width = 0
local height = 0
local created = false
local amount = 4

local edge = 0.3
local pointer = 0.0002
local clickRadius = 400
local clickPower = 200
local sep = 0.03
local alig = 0.05
local cohes = 0.0005
local flee = 16
local vision = 50
local maxSpeed = 16
local minSpeed = 4

function create(newPosX, newPosY, newVelX, newVelY, index)

    local boid = {}
    boid["posX"] = newPosX; boid["posY"] = newPosY
    boid["velX"] = newVelX; boid["velY"] = newVelY
    boid["index"] = index
    table.insert(boids, boid)
end
function createBoids(amount)

    width = UiWidth()
    height = UiHeight()

    local index = 0
    for x=0, amount do

        for y=0, amount do

            create(
                x/amount*UiWidth(),
                y/amount*UiHeight(),
                math.random(-maxSpeed*10, maxSpeed*10)/10,
                math.random(-maxSpeed*10, maxSpeed*10)/10,
                index
            )
            index = index + 1
        end
    end
end
function resetBoids()

    created = false
    boids = {}
end
function handleBoids(visibility, dt)

    if created == false then createBoids(amount); created = true end

    function separation(boid, boids)

        local closeDX = 0
        local closeDY = 0
        for _, bb in ipairs(boids) do
            if bb.dist < flee then
                closeDX = closeDX + bb.boid.posX - boid.posX
                closeDY = closeDY + bb.boid.posY - boid.posY
            end
        end
        return closeDX, closeDY
    end
    function alignment(boids)

        local boidCount = 0
        local velXAvg = 0
        local velYAvg = 0
        for _, bb in ipairs(boids) do
            if bb.dist < vision then
                velXAvg = velXAvg + bb.boid.velX
                velYAvg = velYAvg + bb.boid.velY
                boidCount = boidCount + 1
            end
        end
        if boidCount > 0 then

            return velXAvg/boidCount, velYAvg/boidCount
        else

            return 0, 0
        end 
    end
    function cohesion(boid, boids)

        local posXAvg = 0
        local posYAvg = 0
        local boidCount = 0
        for _, bb in ipairs(boids) do
            if bb.dist < vision then
                posXAvg = posXAvg + bb.boid.posX
                posYAvg = posYAvg + bb.boid.posY
                boidCount = boidCount + 1
            end
        end
        if boidCount > 0 then
            return posXAvg/boidCount, posYAvg/boidCount
        else
            return boid.posX, boid.posY
        end 
    end

    --Tick boid logic
    for kb, b in ipairs(boids) do

        --Find information about boids
        local otherBoids = {}
        for kbb, bb in ipairs(boids) do

            if kb ~= kbb and kb < kbb then

                local otherBoid = {}
                otherBoid["boid"] = bb
                otherBoid["dist"] = math.sqrt((b.posX - bb.posX)^2 + (b.posY - bb.posY)^2)        
                table.insert(otherBoids, otherBoid)
            end
        end

        --RULES
        local closeDX, closeDY = separation(b, otherBoids)
        local velXAvg, velYAvg = alignment(otherBoids)
        local posXAvg, posYAvg = cohesion(b, otherBoids)

        --Apply velocity
        b.velX = b.velX + closeDX*sep + (velXAvg - b.velX)*alig + (posXAvg - b.posX)*cohes
        b.velY = b.velY + closeDY*sep + (velYAvg - b.velY)*alig + (posYAvg - b.posY)*cohes

        --Avoid edges
        if b.posX < 100 then

            b.velX = b.velX - edge
        end
        if b.posX > width-100 then

            b.velX = b.velX + edge
        end
        if b.posY < 100 then

            b.velY = b.velY - edge
        end
        if b.posY > height-100 then

            b.velY = b.velY + edge
        end

        --Go towards pointer
        local pPosX, pPosY = UiGetMousePos()
        b.velX = b.velX + (b.posX - pPosX) * pointer
        b.velY = b.velY + (b.posY - pPosY) * pointer
        --Create force when clicked
        if InputPressed("usetool") then
            b.velX = b.velX - clickRadius / (b.posX - pPosX) / clickRadius * clickPower
            b.velY = b.velY - clickRadius / (b.posY - pPosY) / clickRadius * clickPower
        end

        --Limit speed
        local speed = math.sqrt(b.velX*b.velX+b.velY*b.velY)
        if speed < minSpeed then

            b.velX = (b.velX/speed)*minSpeed
            b.velY = (b.velY/speed)*minSpeed
        elseif speed > maxSpeed then

            b.velX = (b.velX/speed)*maxSpeed
            b.velY = (b.velY/speed)*maxSpeed
        end

        --Apply movement
        b.posX = b.posX - b.velX * dt / (1 / 60)
        b.posY = b.posY - b.velY * dt / (1 / 60)

        drawBoid(b, otherBoids, visibility)
    end
end
function drawBoid(boid, otherBoids, visibility)

    local sortedNearestObjects = getNearby(otherBoids, 2, false)

    for k, v in ipairs(sortedNearestObjects) do

        UiPush()

            --Position boid
            UiAlign("center middle")
            UiTranslate(
                lerp(boid.posX, v.boid.posX, 0.5),
                lerp(boid.posY, v.boid.posY, 0.5)
            )
            local dirX = v.boid.posX - boid.posX
            local dirY = v.boid.posY - boid.posY
            local angle = -math.deg(
                math.atan2(
                    dirY,
                    dirX
                )
            ) - 90
            UiRotate(angle)

            --Drawing boid
            local dist = VecLength(Vec(dirX, dirY, 0))
            UiColor(0.9, 0.85, 1, 0.2 * visibility)
            UiImageBox("MOD/sprites/line.png", 8, dist, 0, 0)
        
        UiPop()
    end
    UiPush()

        UiAlign("center middle")
        UiTranslate(
            boid.posX,
            boid.posY
        )

        UiScale(visibility)
        UiColor(0.9, 0.85, 1, visibility)
        UiImage("MOD/ui/images/boid.png")

    UiPop()
end 