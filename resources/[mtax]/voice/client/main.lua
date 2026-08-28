root = getRootElement()
resourceRoot = getRootElement()

local pushToTalkKey = "z"

local talking = {}
local transmitting = false

local barWidth = 4
local barHeight = 18
local barGap = 3
local barCount = 4

local _, screenHeight = guiGetScreenSize()

local function startTalking()
    if transmitting then return end
    transmitting = (setVoiceTransmitting and setVoiceTransmitting(true)) == true
end

local function stopTalking()
    if not transmitting then return end
    if setVoiceTransmitting then setVoiceTransmitting(false) end
    transmitting = false
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    bindKey(pushToTalkKey, "down", startTalking)
    bindKey(pushToTalkKey, "up", stopTalking)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    stopTalking()
    unbindKey(pushToTalkKey, "down", startTalking)
    unbindKey(pushToTalkKey, "up", stopTalking)
end)

addEventHandler("onClientPlayerVoiceStart", root, function()
    if not source then
        return
    end

    talking[source] = true
end)

addEventHandler("onClientPlayerVoiceStop", root, function()
    if not source then
        return
    end

    talking[source] = nil
end)

local function drawMicIndicator(x, y, active)
    local color = active and tocolor(120, 230, 140, 235) or tocolor(255, 255, 255, 90)
    for i = 1, barCount do
        local height = barHeight * (0.35 + 0.22 * i)
        dxDrawRectangle(x + (i - 1) * (barWidth + barGap), y + (barHeight - height), barWidth, height, color)
    end
end

addEventHandler("onClientRender", root, function()
    local enabled = isVoiceEnabled and isVoiceEnabled()
    
    local x = 32
    local y = screenHeight - 96

    drawMicIndicator(x, y, transmitting)

    local label, labelColor
    if not enabled then
        label = "VOICE: connecting..."
        labelColor = tocolor(255, 210, 120, 160)
    elseif transmitting then
        label = "TRANSMITTING"
        labelColor = tocolor(120, 230, 140, 235)
    else
        label = "HOLD [" .. string.upper(pushToTalkKey) .. "] TO TALK"
        labelColor = tocolor(255, 255, 255, 150)
    end

    dxDrawText(label, x + barCount * (barWidth + barGap) + 8, y, 0, y + barHeight, labelColor, 1.0, "default-bold",
               "left", "center")

    local listY = y - 26
    for element in pairs(talking) do
        local playerName = getPlayerName(element)

        if not playerName then
            goto skip
        end

        dxDrawText("* player " .. playerName .. " speaking", x, listY, 0, listY + 16,
                   tocolor(120, 230, 140, 210), 0.9, "default", "left", "center")
        listY = listY - 18

        ::skip::
    end
end)