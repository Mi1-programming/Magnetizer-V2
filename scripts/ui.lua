#include "boids.lua"

menu = {
    value = 0,
    indicator = 0
}
local powerSpinner = {
    rotation = 0,
    force = 0
}
local buttonInfos = {
    {
        image = "MOD/ui/modes/magnetizer.png",
        desc = "Selected to each other",
        hover = 0
    },
    {
        image = "MOD/ui/modes/magnetmagnetizer.png",
        desc = "Selected to nearby",
        hover = 0
    },
    {
        image = "MOD/ui/modes/magnet.png",
        desc = "Selected to Magnetizer",
        hover = 0
    }
}
local booleanInfos = {
    {
        title = "Lightning effects",
        setting = "lightning",
        on = 1
    },
    {
        title = "Visible controls",
        setting = "controls",
        on = 1
    }
}
local inited = false
function initUi()

    --INIT VARIABLE BUTTON INFO VALUES ----------
    
        for k, v in ipairs(buttonInfos) do

            v.hover = 0
        end

    --INIT BOOLEAN INFO VALUES ----------

        for k, v in ipairs(booleanInfos) do

            v.on = (config.settings[v.setting]) and 1 or 0
        end

    inited = true
end
function drawUi(dt)

    if inited == false then initUi() end
   
    --MENU ----------

        if menu.value == 1 then

            SetBool("game.disablepause", true)
            UiMakeInteractive()
        end
        if menu.indicator > 0.005 then

            handleBoids(menu.indicator, dt)

            --Settings for the whole UI
            menuWidths = 350
            menuHeights = 600
            offsets = 500
            globalMargins = 25
            titleMargins = 50
            alpha = easeOut(menu.indicator - 0.1, 8) --Used for fading out things at regular pace
            UiButtonPressColor(1.6, 1.6, 1.6, 1)
            UiButtonPressDist(0)

            --Close button
            UiPush()

                local closeWidth = 128
                local closeHeight = 64
                UiAlign("middle center")
                UiTranslate(UiCenter(), UiHeight() - closeHeight / 2 - 150)
                UiScale(menu.indicator)
                UiButtonImageBox("MOD/ui/sliced/panel.png", 8, 8, 0.15, 0.1, 0.1, alpha)
                UiColor(0.75, 0, 0, alpha)

                if UiImageButton("MOD/ui/images/close.png", closeWidth, closeHeight) then

                    closeMenu()
                end

            UiPop()

            UiTranslate(
                UiCenter() - menuWidths / 2,
                UiMiddle() - menuHeights * menu.indicator / 2
            )

            UiPush()

                UiTranslate(-offsets, 0)

                drawMenu(
                    "Magnet Modes",
                    {1, 0.25, 0.35, 0}, {1, 0.1, 0.1, 3},
                    actives,
                    indicators
                )

                --ACTUAL UI FOR THE MENU (LEFT) ----------

                    UiWindow(menuWidths, menuHeights * menu.indicator, true)
                    UiPush()

                        UiAlign("top center")
                        UiTranslate(menuWidths / 2, titleMargins)
                        
                        verticalChoiceButtons(
                            buttonInfos,
                            menuWidths - globalMargins * 2,
                            menuHeights - globalMargins - titleMargins,
                            dt,
                            "magnetMode"
                        )
                    UiPop()


            UiPop()

            local powerPanelSize = menuWidths - globalMargins * 2
            local magnetPowerPanelSpcae = menuHeights * menu.indicator - powerPanelSize / 2 - titleMargins
            
            UiPush()
                
                UiTranslate(offsets, 0)
                UiAlign("bottom left")
                
                UiTranslate(0, menuHeights * menu.indicator)

                drawMenu(
                    "Adjustments",
                    {0.5, 1, 0.8, 0}, {0, 1, 1, 3},
                    actives,
                    indicators
                )

                --ACTUAL UI FOR THE MENU (RIGHT) ----------

                    --MAGNET SPINNER ----------

                        UiWindow(menuWidths, menuHeights * menu.indicator, true)
                        UiAlign("middle center")
                        UiTextOutline(0, 0, 0, 1, 0.5)
                        UiTranslate(
                            menuWidths / 2,
                            magnetPowerPanelSpcae
                        )
                        UiPush()

                            --ABILITY TO SPIN THE WHEEL ----------

                                if UiIsMouseInRect(powerPanelSize, powerPanelSize) then

                                    if InputDown("usetool") then

                                        local mousePosX = UiGetMousePos()
                                        powerSpinner.force = mousePosX

                                        --Spin sound
                                        local mpx = math.abs(mousePosX)
                                        if mpx > 50 then UiSoundLoop("MOD/snd/uiSpinnerFast.ogg", 0.4)
                                        elseif mpx > 10 then UiSoundLoop("MOD/snd/uiSpinner.ogg", 0.2)
                                        end
                                    end
                                end

                                powerSpinner.force = damp(powerSpinner.force, 0, 4, dt)
                                powerSpinner.rotation = powerSpinner.rotation + powerSpinner.force * dt
                                config.tool.force = math.max(config.tool.force + powerSpinner.force * dt, 0)

                            plate("Magnet Power Spinner", powerPanelSize, powerPanelSize, indicators)
                            UiPush()

                                local rotation = 10

                                UiRotate(-powerSpinner.rotation * rotation)

                                local images = 11
                                local frameRotationOffset = 360 / images
                                local imageTime = powerSpinner.rotation * rotation / frameRotationOffset
                                local alphaBias = (imageTime * images) % images / images
                                
                                UiScale(easeIn(menu.indicator, 2))
                                UiImageBox(
                                    "MOD/ui/uiPower/" ..
                                        math.floor(
                                            (imageTime - 1) % images
                                        ) ..
                                        ".png",
                                    powerPanelSize - globalMargins * 2,
                                    powerPanelSize - globalMargins * 2,
                                    0,
                                    0
                                )
                                UiColor(1, 1, 1, alphaBias)
                                UiImageBox(
                                    "MOD/ui/uiPower/" ..
                                        math.floor(
                                            imageTime % images
                                        ) ..
                                        ".png",
                                    powerPanelSize - globalMargins * 2,
                                    powerPanelSize - globalMargins * 2,
                                    0,
                                    0
                                )

                            UiPop()
                            UiPush()
                                
                                UiScale(easeIn(menu.indicator, 2))
                                UiFont("MOD/ui/fonts/Acme-Regular.ttf", 46)
                                UiText(math.floor(config.tool.force) .. "W")

                            UiPop()

                        UiPop()

                    --BOOLEAN BUTTONS ----------

                        UiPush()

                            UiTranslate(
                                0,
                                -menuHeights / 2 + globalMargins
                            )
                            plate(
                                "On/Off Switches (Saving)",
                                powerPanelSize,
                                (powerPanelSize - globalMargins * 4),
                                indicators
                            )
                            UiWindow(
                                powerPanelSize * 2,
                                (powerPanelSize - globalMargins * 4) - globalMargins * 2
                            )
                            UiTranslate(
                                globalMargins + powerPanelSize / 2,
                                0
                            )

                            for k, v in ipairs(booleanInfos) do

                                booleanButton(v, dt)
                            end

                        UiPop()

            UiPop()

        else

            resetBoids()
        end

end
function openMenu()

    menu.value = 1
    UiSound("MOD/snd/uiOpen.ogg", 0.4)
end
function closeMenu()

    menu.value = 0
    UiSound("MOD/snd/uiClose.ogg", 0.4)
end
function drawMenu(title, glowColorA, glowColorB, actives, indicators)

    UiPush()

        UiPush()

            local outline = 4

            UiTranslate(-outline / 2, 0)
            UiColor(glowColorB[1], glowColorB[2], glowColorB[3], alpha)
            UiImageBox("MOD/ui/sliced/clearPanel.png", menuWidths + outline, (menuHeights * menu.indicator + outline / 2), 8, 8)
        
        UiPop()

        UiColor(0.15, 0.1, 0.1, alpha)
        UiImageBox("MOD/ui/sliced/panel.png", menuWidths, menuHeights * menu.indicator, 8, 8)

        UiPush()

            local glowHeight = 100
            local glowWidthPadding = 125

            UiAlign("middle center")

            local colC = lerpColor(glowColorA, glowColorB, easeOut(menu.indicator, 2))
            UiColor(colC[1], colC[2], colC[3], colC[4])

            UiTranslate(
                menuWidths / 2,
                0
            )
            UiScale(1 - easeOut(menu.indicator, 12) + 1)
            UiImageBox(
                "MOD/ui/uiGlow/glow" .. math.floor(GetTime() * 12) % 11 .. ".png",
                menuWidths + glowWidthPadding,
                glowHeight,
                0,
                0
            )

        UiPop()

        UiTranslate(menuWidths / 2, 6)
        UiAlign("bottom center")
        UiFont("MOD/ui/fonts/Acme-Regular.ttf", 24)
        UiText(title)
        
    UiPop()
end
function verticalChoiceButtons(buttonInfos, width, height, dt, targetVar)

    UiFont("MOD/ui/fonts/Acme-Regular.ttf", 24)
    UiButtonImageBox("MOD/ui/sliced/panel.png", 8, 8, 0.15, 0.1, 0.1, 1 * alpha)
    
    local adjustedHeight = height / #buttonInfos

    for k, v in ipairs(buttonInfos) do

        local selAlpha = 0.15
        if (config.tool[targetVar] == k) then selAlpha = 1 end  

        if UiBlankButton(

            width, adjustedHeight
        ) then

            config.tool[targetVar] = k
            UiSound("MOD/snd/uiMode.ogg", 0.5)
        end

        if UiIsMouseInRect(width, adjustedHeight) then

            v.hover = damp(v.hover, 1, 8, dt)
        else

            v.hover = damp(v.hover, 0, 8, dt)
        end

        UiPush()

            UiColor(1, 1, 1, selAlpha * v.hover * alpha)
            UiAlign("middle center")
            UiTranslate(0, adjustedHeight / 2)
            UiText(v.desc)

        UiPop()
        UiPush()

            UiColor(1, 1, 1, selAlpha * (1 - v.hover) * alpha)
            UiAlign("middle center")
            UiTranslate(0, adjustedHeight / 2)
            UiImage(v.image)

        UiPop()

        UiTranslate(
            0,
            adjustedHeight
        )
    end
end
function booleanButton(info, dt)

    UiPush()

        UiWindow(UiWidth() / 2 - globalMargins * 2, 32)
        UiTranslate(UiWidth(), UiHeight())

        UiPush()

            UiColor(0.15, 0.1, 0.1)
            --Draws the background and borders of the boolean button switches
            UiImageBox(
                "MOD/ui/sliced/panel.png",
                UiWidth() + 8,
                UiHeight() + 8,
                8,
                8
            )

        UiPop()

        UiPush()

            UiTranslate(
                lerp(UiCenter() / 2, -UiCenter() / 2, info.on),
                0
            )
            local colorC = lerpColor(
                {0.8, 0, 0, 1},
                {0.376, 0.8, 0, 1},
                info.on
            )
            UiButtonImageBox(
                "MOD/ui/sliced/panel.png",
                8,
                8,
                colorC[1],
                colorC[2],
                colorC[3]
            )
            if UiBlankButton(UiCenter(), UiHeight()) then

                config.settings[info.setting] = not config.settings[info.setting]
                SetBool("savegame.mod.magnetizerv2.settings." .. info.setting, config.settings[info.setting])
                
                UiSound("MOD/snd/uiSwitch.ogg", 1)
            end

            --Progress animation
            
            info.on = damp(info.on, (config.settings[info.setting]) and 1 or 0, 10, dt)

        UiPop()

        UiFont("MOD/ui/fonts/Acme-Regular.ttf", 24)
        UiText(info.title)

    UiPop()

    UiTranslate(0, 50)
end
function plate(title, width, height, indicators)

    local fontSize = 24
    height = height - fontSize / 2
    UiPush()

        UiColor(0.15, 0.1, 0.1, 1 * alpha)
        UiImageBox(
            "MOD/ui/sliced/panel.png",
            width,
            height,
            8,
            8
        )

    UiPop()
    UiPush()

        UiColor(1, 1, 1, menu.indicator)
        UiTranslate(
            0,
            -height / 2
        )
        UiFont("MOD/ui/fonts/Acme-Regular.ttf", fontSize)
        UiText(title)
    
    UiPop()
end