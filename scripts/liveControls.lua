--Controls you can set as visible
possibleControls = {

    select = {
        text = "Select/Deselect",
        key = "LMB",
        visibilityIndicator = 0,
        visible = 0
    },
    deselectAll = {
        text = "Deselect all",
        key = "RMB",
        visibilityIndicator = 0,
        visible = 0
    },
    reset = {
        text = "Reset power",
        key = "R",
        visibilityIndicator = 0,
        visible = 0
    },
    scrollPower = {
        text = "Scroll power",
        key = "Shift + mouse wheel",
        visibilityIndicator = 0,
        visible = 0
    },
    stepPower = {
        text = "Step power",
        key = "Shift + 1 or 2",
        visibilityIndicator = 0,
        visible = 0
    },
    menu = {
        text = "Open/Close menu",
        key = "MMB or from pause",
        visibilityIndicator = 0,
        visible = 0
    }
}
orderedControls = {
    possibleControls.menu,
    possibleControls.stepPower,
    possibleControls.scrollPower,
    possibleControls.reset,
    possibleControls.deselectAll,
    possibleControls.select
}
function tickControls()

    --Resets the visible controls
    for k, v in pairs(possibleControls) do
        
        v.visible = 0
    end
end
function drawControls(dt)

    if config.settings.controls == false then return end

    UiPush()

        UiAlign("bottom left")
        UiTranslate(0, UiHeight())
        local textSize = 24
        local padding = 16
        local spacing = 4
        local edgeMargins = 12.5
        UiTranslate(edgeMargins, -edgeMargins)

        for k, v in ipairs(orderedControls) do

            --ANIMATE THE CONTROL ----------

                v.visibilityIndicator = damp(v.visibilityIndicator, v.visible, 10, dt)

            --DRAW THE CONTROL ----------

                if v.visibilityIndicator > 0.01 then

                    UiFont("MOD/ui/fonts/Acme-Regular.ttf", textSize)
                    local text = v.text .. ": " .. "( " .. v.key .. " )"
                    local tw, th = UiGetTextSize(text)

                    UiPush()

                        UiTranslate((-edgeMargins - tw) * (1 - v.visibilityIndicator), 0)
                        local boxW = tw
                        local boxH = textSize + padding

                        UiPush()

                            UiColor(0, 0, 0)
                            UiImageBox("MOD/ui/sliced/clearPanel.png", boxW, boxH, 8, 8)

                        UiPop()

                        UiTranslate(0, -boxH / 2)
                        UiAlign("middle left")
                        UiText(text)

                    UiPop()
                end

                UiTranslate(0, -spacing - padding - textSize)

        end

    UiPop()
end