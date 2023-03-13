import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/math"

-- Declaring this "gfx" shorthand will make your life easier. Instead of having
-- to preface all graphics calls with "playdate.graphics", just use "gfx."
-- Performance will be slightly enhanced, too.
-- NOTE: Because it's local, you'll have to do it in every .lua source file.

local gfx <const> = playdate.graphics
local mth <const> = playdate.math

-- Here's our player sprite declaration. We'll scope it to this file because
-- several functions need to access it.

local playerSprite = nil
local sandboxImg = nil
local imgOffsetX, imgOffsetY = 20, 20
local drawMode = false
local wc, bc, cc = gfx.kColorWhite, gfx.kColorBlack, gfx.kColorClear

function myGameSetUp()
    -- Set up the player sprite.
    -- The :setCenter() call specifies that the sprite will be anchored at its center.
    -- The :moveTo() call moves our sprite to the center of the display.

    local playerImage = gfx.image.new("Images/crosshair")
    assert(playerImage) -- make sure the image was where we thought

    playerSprite = gfx.sprite.new(playerImage)
    gfx.sprite.add(playerSprite)
    playerSprite:moveTo(50, 50) -- this is where the center of the sprite is placed; (200,120) is the center of the Playdate screen


    sandboxImg = gfx.image.new(360, 200)
    local sandboxSprite = gfx.sprite.new(sandboxImg)
    gfx.sprite.add(sandboxSprite)
    sandboxSprite:moveTo(180 + imgOffsetX, 100 + imgOffsetY)
    -- We want an environment displayed behind our sprite.
    -- There are generally two ways to do this:
    -- 1) Use setBackgroundDrawingCallback() to draw a background image. (This is what we're doing below.)
    -- 2) Use a tilemap, assign it to a sprite with sprite:setTilemap(tilemap),
    --       and call :setZIndex() with some low number so the background stays behind
    --       your other sprites.

    local backgroundImage = gfx.image.new("Images/background")
    assert(backgroundImage)

    gfx.sprite.setBackgroundDrawingCallback(
        function(x, y, width, height)
            print("Drawing frame")
            gfx.setClipRect(x, y, width, height) -- let's only draw the part of the screen that's dirty
            gfx.clearClipRect()                  -- clear so we don't interfere with drawing that comes after this
            gfx.setColor(bc)
            gfx.drawRect(20, 20, 360, 200)
        end
    )
end

function range(from, to, step)
    step = step or 1
    return function(_, lastvalue)
        local nextvalue = lastvalue + step
        if step > 0 and nextvalue <= to or step < 0 and nextvalue >= to or
            step == 0
        then
            return nextvalue
        end
    end, nil, from - step
end

-- Now we'll call the function above to configure our game.
-- After this runs (it just runs once), nearly everything will be
-- controlled by the OS calling `playdate.update()` 30 times a second.

myGameSetUp()
local prevx, prevy = playerSprite:getPosition()

-- `playdate.update()` is the heart of every Playdate game.
-- This function is called right before every frame is drawn onscreen.
-- Use this function to poll input, run game logic, and move sprites.

local trailNum = 3
local spacingY = 7

function drawTrail(num, x, y)
    local spacingX = 0
    for i in range(-0 - math.floor(num / 2), -1 + num - math.floor(num / 2), 1) do
        gfx.drawLine(prevx - imgOffsetX, prevy - imgOffsetY + (i * spacingY), x - imgOffsetX,
            y - imgOffsetY + (i * spacingY))
        gfx.drawLine(prevx - imgOffsetX - 1, prevy - imgOffsetY - 2 + (i * spacingY), x - imgOffsetX - 1,
            y - imgOffsetY - 2 + (i * spacingY))
        gfx.drawLine(prevx - imgOffsetX - 3, prevy - imgOffsetY + 1 + (i * spacingY), x - imgOffsetX - 3,
            y - imgOffsetY + 1 + (i * spacingY))
    end
end

function drawGhostTrail(num, x, y)
    local spacingX = 0
    for i in range(-0 - math.floor(num / 2), -1 + num - math.floor(num / 2), 1) do
        gfx.drawPixel(x - 1, y + (i * spacingY))
    end
end

function updateSandboxImg()
    local x, y = playerSprite:getPosition()
    if drawMode then
        gfx.setColor(bc)
        gfx.pushContext(sandboxImg)
        drawTrail(trailNum, x, y)
        gfx.popContext()
    end
    prevx, prevy = x, y
end

function clearSandboxImg()
    gfx.pushContext(sandboxImg)
    gfx.setColor(cc)
    gfx.fillRect(0, 0, 360, 200)
    gfx.popContext()
end

function playdate.update()
    -- Poll the d-pad and move our player accordingly.
    -- (There are multiple ways to read the d-pad; this is the simplest.)
    -- Note that it is possible for more than one of these directions
    -- to be pressed at once, if the user is pressing diagonally.
    newTrailNum = math.floor(((450 + playdate.getCrankPosition()) % 360) / 45)

    if trailNum ~= newTrailNum then
        trailNum = newTrailNum
        gfx.sprite.redrawBackground()
    end
    if playdate.buttonJustReleased(playdate.kButtonA) then
        drawMode = not drawMode
        gfx.sprite.redrawBackground()
    end
    if playdate.buttonJustReleased(playdate.kButtonB) then
        clearSandboxImg()
    end
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        playerSprite:moveBy(0, -2)
        updateSandboxImg()
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        playerSprite:moveBy(2, 0)
        updateSandboxImg()
    end
    if playdate.buttonIsPressed(playdate.kButtonDown) then
        playerSprite:moveBy(0, 2)
        updateSandboxImg()
    end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        playerSprite:moveBy(-2, 0)
        updateSandboxImg()
    end

    -- Call the functions below in playdate.update() to draw sprites and keep
    -- timers updated. (We aren't using timers in this example, but in most
    -- average-complexity games, you will.)

    gfx.sprite.update()
    playdate.timer.updateTimers()
end

gfx.sprite.setBackgroundDrawingCallback(
    function(_x, _y, width, height)
        local x, y = playerSprite:getPosition()
        if drawMode then
            drawGhostTrail(trailNum, x, y)
            prevx = x
            prevy = y
        end
    end
)
