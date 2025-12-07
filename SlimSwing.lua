-- SlimSwing Minimal for Turtle WoW (Vanilla 1.12)
-- Version 6.2 - Con opcion de estilo ultra delgado

-- ============================================================
-- SAVED VARIABLES Y DEFAULTS
-- ============================================================
SlimSwingDB = SlimSwingDB or {}

local defaults = {
    locked = false,
    showOffhand = true,
    showTimer = true,
    thinMode = false,
    pos = {x = 0, y = 100},
}

-- Compensacion de latencia (ajustar si es necesario)
local SWING_OFFSET = 0.05

-- ============================================================
-- VARIABLES LOCALES
-- ============================================================
local playerMHStart, playerMHSpeed = 0, 0
local playerOHStart, playerOHSpeed = 0, 0
local lastMHSwing, lastOHSwing = 0, 0
local mhCount, ohCount = 0, 0

-- ============================================================
-- FUNCIONES AUXILIARES
-- ============================================================
local function InitDB()
    for k, v in pairs(defaults) do
        if SlimSwingDB[k] == nil then
            if type(v) == "table" then
                SlimSwingDB[k] = {}
                for k2, v2 in pairs(v) do
                    SlimSwingDB[k][k2] = v2
                end
            else
                SlimSwingDB[k] = v
            end
        end
    end
end

local function FormatTime(seconds)
    if seconds <= 0 then return "0.0" end
    return string.format("%.1f", seconds)
end

-- ============================================================
-- FRAME CONTENEDOR INVISIBLE
-- ============================================================
local AnchorFrame = CreateFrame("Button", "SlimSwingAnchor", UIParent)
AnchorFrame:SetWidth(220)
AnchorFrame:SetHeight(22)
AnchorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
AnchorFrame:SetMovable(true)
AnchorFrame:EnableMouse(true)
AnchorFrame:SetClampedToScreen(true)
AnchorFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

-- ============================================================
-- BARRA MAIN HAND
-- ============================================================
local MHBar = CreateFrame("StatusBar", "SlimSwingMH", AnchorFrame)
MHBar:SetWidth(180)
MHBar:SetHeight(8)
MHBar:SetPoint("TOPLEFT", AnchorFrame, "TOPLEFT", 0, 0)
MHBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
MHBar:SetStatusBarColor(0.2, 0.6, 1.0)
MHBar:SetMinMaxValues(0, 1)
MHBar:SetValue(0)

MHBar.bg = MHBar:CreateTexture(nil, "BACKGROUND")
MHBar.bg:SetAllPoints()
MHBar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
MHBar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.7)

MHBar.border = MHBar:CreateTexture(nil, "OVERLAY")
MHBar.border:SetTexture("Interface\\Tooltips\\UI-StatusBar-Border")
MHBar.border:SetWidth(190)
MHBar.border:SetHeight(14)
MHBar.border:SetPoint("CENTER", MHBar, "CENTER", 0, 0)

-- Texto velocidad (dentro de barra - modo normal)
MHBar.text = MHBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
MHBar.text:SetPoint("LEFT", MHBar, "LEFT", 2, 0)
MHBar.text:SetTextColor(1, 1, 1, 0.9)
MHBar.text:SetText("")

-- Timer dentro de barra (modo normal)
MHBar.timer = MHBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
MHBar.timer:SetPoint("RIGHT", MHBar, "RIGHT", -2, 0)
MHBar.timer:SetTextColor(1, 1, 1, 0.9)
MHBar.timer:SetText("")

-- Timer FUERA de barra (modo thin)
MHBar.timerOut = MHBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
MHBar.timerOut:SetPoint("LEFT", MHBar, "RIGHT", 4, 0)
MHBar.timerOut:SetTextColor(0.8, 0.8, 0.8, 1)
MHBar.timerOut:SetText("")
MHBar.timerOut:Hide()

MHBar.spark = MHBar:CreateTexture(nil, "OVERLAY")
MHBar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
MHBar.spark:SetWidth(12)
MHBar.spark:SetHeight(20)
MHBar.spark:SetBlendMode("ADD")
MHBar.spark:SetPoint("CENTER", MHBar, "LEFT", 0, 0)
MHBar.spark:Hide()

-- ============================================================
-- BARRA OFF HAND
-- ============================================================
local OHBar = CreateFrame("StatusBar", "SlimSwingOH", AnchorFrame)
OHBar:SetWidth(180)
OHBar:SetHeight(8)
OHBar:SetPoint("TOPLEFT", MHBar, "BOTTOMLEFT", 0, -3)
OHBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
OHBar:SetStatusBarColor(0.4, 0.8, 0.4)
OHBar:SetMinMaxValues(0, 1)
OHBar:SetValue(0)

OHBar.bg = OHBar:CreateTexture(nil, "BACKGROUND")
OHBar.bg:SetAllPoints()
OHBar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
OHBar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.7)

OHBar.border = OHBar:CreateTexture(nil, "OVERLAY")
OHBar.border:SetTexture("Interface\\Tooltips\\UI-StatusBar-Border")
OHBar.border:SetWidth(190)
OHBar.border:SetHeight(14)
OHBar.border:SetPoint("CENTER", OHBar, "CENTER", 0, 0)

OHBar.text = OHBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
OHBar.text:SetPoint("LEFT", OHBar, "LEFT", 2, 0)
OHBar.text:SetTextColor(1, 1, 1, 0.9)
OHBar.text:SetText("")

OHBar.timer = OHBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
OHBar.timer:SetPoint("RIGHT", OHBar, "RIGHT", -2, 0)
OHBar.timer:SetTextColor(1, 1, 1, 0.9)
OHBar.timer:SetText("")

OHBar.timerOut = OHBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
OHBar.timerOut:SetPoint("LEFT", OHBar, "RIGHT", 4, 0)
OHBar.timerOut:SetTextColor(0.8, 0.8, 0.8, 1)
OHBar.timerOut:SetText("")
OHBar.timerOut:Hide()

OHBar.spark = OHBar:CreateTexture(nil, "OVERLAY")
OHBar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
OHBar.spark:SetWidth(12)
OHBar.spark:SetHeight(20)
OHBar.spark:SetBlendMode("ADD")
OHBar.spark:SetPoint("CENTER", OHBar, "LEFT", 0, 0)
OHBar.spark:Hide()

-- ============================================================
-- FUNCIONES DE ESTILO
-- ============================================================
local function ApplyThinMode()
    -- Barras ultra delgadas (3px)
    MHBar:SetHeight(3)
    OHBar:SetHeight(3)
    
    -- Sin borde
    MHBar.border:Hide()
    OHBar.border:Hide()
    
    -- Sin texto interno
    MHBar.text:Hide()
    MHBar.timer:Hide()
    OHBar.text:Hide()
    OHBar.timer:Hide()
    
    -- Timer externo visible
    MHBar.timerOut:Show()
    OHBar.timerOut:Show()
    
    -- Spark mas pequeño
    MHBar.spark:SetWidth(8)
    MHBar.spark:SetHeight(12)
    OHBar.spark:SetWidth(8)
    OHBar.spark:SetHeight(12)
    
    -- Espaciado
    OHBar:SetPoint("TOPLEFT", MHBar, "BOTTOMLEFT", 0, -2)
end

local function ApplyNormalMode()
    -- Barras normales (8px)
    MHBar:SetHeight(8)
    OHBar:SetHeight(8)
    
    -- Con borde
    MHBar.border:Show()
    OHBar.border:Show()
    
    -- Texto interno visible
    MHBar.text:Show()
    MHBar.timer:Show()
    OHBar.text:Show()
    OHBar.timer:Show()
    
    -- Timer externo oculto
    MHBar.timerOut:Hide()
    OHBar.timerOut:Hide()
    
    -- Spark normal
    MHBar.spark:SetWidth(12)
    MHBar.spark:SetHeight(20)
    OHBar.spark:SetWidth(12)
    OHBar.spark:SetHeight(20)
    
    -- Espaciado
    OHBar:SetPoint("TOPLEFT", MHBar, "BOTTOMLEFT", 0, -3)
end

local function UpdateStyle()
    if SlimSwingDB.thinMode then
        ApplyThinMode()
    else
        ApplyNormalMode()
    end
end

local function UpdateVisibility()
    local _, hasOH = UnitAttackSpeed("player")
    
    MHBar:Show()
    
    if hasOH and SlimSwingDB.showOffhand then
        OHBar:Show()
        if SlimSwingDB.thinMode then
            AnchorFrame:SetHeight(10)
        else
            AnchorFrame:SetHeight(22)
        end
    else
        OHBar:Hide()
        if SlimSwingDB.thinMode then
            AnchorFrame:SetHeight(5)
        else
            AnchorFrame:SetHeight(10)
        end
    end
end

local function SavePosition()
    local _, _, _, x, y = AnchorFrame:GetPoint()
    SlimSwingDB.pos.x = x
    SlimSwingDB.pos.y = y
end

local function LoadPosition()
    AnchorFrame:ClearAllPoints()
    AnchorFrame:SetPoint("CENTER", UIParent, "CENTER", SlimSwingDB.pos.x, SlimSwingDB.pos.y)
end

-- ============================================================
-- DRAG Y CLICK
-- ============================================================
local isDragging = false

AnchorFrame:SetScript("OnMouseDown", function()
    if arg1 == "LeftButton" and not SlimSwingDB.locked then
        AnchorFrame:StartMoving()
        isDragging = true
    end
end)

AnchorFrame:SetScript("OnMouseUp", function()
    if isDragging then
        AnchorFrame:StopMovingOrSizing()
        isDragging = false
        SavePosition()
    end
end)

AnchorFrame:SetScript("OnClick", function()
    if arg1 == "RightButton" then
        SlimSwingDB.locked = not SlimSwingDB.locked
        if SlimSwingDB.locked then
            DEFAULT_CHAT_FRAME:AddMessage("|cff6699FF[SlimSwing]|r |cffFF0000Bloqueado|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff6699FF[SlimSwing]|r |cff00FF00Desbloqueado|r - arrastra para mover")
        end
    end
end)

AnchorFrame:SetScript("OnEnter", function()
    GameTooltip:SetOwner(AnchorFrame, "ANCHOR_TOP")
    GameTooltip:AddLine("SlimSwing", 0.4, 0.6, 1)
    GameTooltip:AddLine(" ")
    local mhSpeed, ohSpeed = UnitAttackSpeed("player")
    if mhSpeed then
        GameTooltip:AddDoubleLine("Main Hand:", string.format("%.2fs", mhSpeed), 1, 1, 1, 0.4, 0.6, 1)
    end
    if ohSpeed then
        GameTooltip:AddDoubleLine("Off Hand:", string.format("%.2fs", ohSpeed), 1, 1, 1, 0.4, 0.8, 0.4)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Estilo: " .. (SlimSwingDB.thinMode and "|cff00FF00Delgado|r" or "|cffFFFF00Normal|r"), 0.7, 0.7, 0.7)
    if SlimSwingDB.locked then
        GameTooltip:AddLine("|cffFF0000Bloqueado|r - click der. para desbloquear", 0.5, 0.5, 0.5)
    else
        GameTooltip:AddLine("|cff00FF00Desbloqueado|r - arrastra para mover", 0.5, 0.5, 0.5)
    end
    GameTooltip:AddLine("|cffFFFF00/ss|r para opciones", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end)

AnchorFrame:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- ============================================================
-- LÓGICA DE SWING TIMER
-- ============================================================
local function StartMHSwing()
    local mhSpeed = UnitAttackSpeed("player")
    if mhSpeed then
        playerMHStart = GetTime() - SWING_OFFSET
        playerMHSpeed = mhSpeed
        MHBar:SetMinMaxValues(0, mhSpeed)
        MHBar:SetValue(0)
        MHBar.text:SetText(string.format("%.1f", mhSpeed))
    end
end

local function StartOHSwing()
    local _, ohSpeed = UnitAttackSpeed("player")
    if ohSpeed then
        playerOHStart = GetTime() - SWING_OFFSET
        playerOHSpeed = ohSpeed
        OHBar:SetMinMaxValues(0, ohSpeed)
        OHBar:SetValue(0)
        OHBar.text:SetText(string.format("%.1f", ohSpeed))
    end
end

local function DetectSwingHand()
    local mhSpeed, ohSpeed = UnitAttackSpeed("player")
    local now = GetTime()
    
    if not ohSpeed then
        StartMHSwing()
        return
    end
    
    local mhExpected = lastMHSwing + mhSpeed
    local ohExpected = lastOHSwing + ohSpeed
    local mhDiff = math.abs(now - mhExpected)
    local ohDiff = math.abs(now - ohExpected)
    
    if mhDiff <= ohDiff or mhCount <= ohCount then
        lastMHSwing = now
        mhCount = mhCount + 1
        StartMHSwing()
    else
        lastOHSwing = now
        ohCount = ohCount + 1
        StartOHSwing()
    end
end

local function ResetSwingCounters()
    mhCount = 0
    ohCount = 0
    lastMHSwing = 0
    lastOHSwing = 0
    playerMHSpeed = 0
    playerOHSpeed = 0
    MHBar.text:SetText("")
    MHBar.timer:SetText("")
    MHBar.timerOut:SetText("")
    OHBar.text:SetText("")
    OHBar.timer:SetText("")
    OHBar.timerOut:SetText("")
    MHBar.spark:Hide()
    OHBar.spark:Hide()
end

-- ============================================================
-- UPDATE FRAME
-- ============================================================
local UpdateFrame = CreateFrame("Frame")
UpdateFrame:SetScript("OnUpdate", function()
    local now = GetTime()
    
    -- Update MH Bar
    if playerMHSpeed > 0 then
        local elapsed = now - playerMHStart
        if elapsed <= playerMHSpeed then
            MHBar:SetValue(elapsed)
            local remaining = playerMHSpeed - elapsed
            if SlimSwingDB.showTimer then
                local timeText = FormatTime(remaining)
                MHBar.timer:SetText(timeText)
                MHBar.timerOut:SetText(timeText)
            end
            local sparkPos = (elapsed / playerMHSpeed) * MHBar:GetWidth()
            MHBar.spark:SetPoint("CENTER", MHBar, "LEFT", sparkPos, 0)
            MHBar.spark:Show()
        else
            MHBar:SetValue(playerMHSpeed)
            MHBar.timer:SetText("")
            MHBar.timerOut:SetText("")
            MHBar.spark:Hide()
        end
    end
    
    -- Update OH Bar
    if playerOHSpeed > 0 then
        local elapsed = now - playerOHStart
        if elapsed <= playerOHSpeed then
            OHBar:SetValue(elapsed)
            local remaining = playerOHSpeed - elapsed
            if SlimSwingDB.showTimer then
                local timeText = FormatTime(remaining)
                OHBar.timer:SetText(timeText)
                OHBar.timerOut:SetText(timeText)
            end
            local sparkPos = (elapsed / playerOHSpeed) * OHBar:GetWidth()
            OHBar.spark:SetPoint("CENTER", OHBar, "LEFT", sparkPos, 0)
            OHBar.spark:Show()
        else
            OHBar:SetValue(playerOHSpeed)
            OHBar.timer:SetText("")
            OHBar.timerOut:SetText("")
            OHBar.spark:Hide()
        end
    end
end)

-- ============================================================
-- EVENT HANDLER
-- ============================================================
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("VARIABLES_LOADED")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
EventFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
EventFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
EventFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")

EventFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" or event == "PLAYER_LOGIN" then
        InitDB()
        LoadPosition()
        UpdateStyle()
        UpdateVisibility()
        DEFAULT_CHAT_FRAME:AddMessage("|cff6699FFSlimSwing v6.2|r cargado! |cffFFFF00/ss|r para opciones")
        
    elseif event == "PLAYER_LEAVE_COMBAT" then
        ResetSwingCounters()
        
    elseif event == "CHAT_MSG_COMBAT_SELF_HITS" or event == "CHAT_MSG_COMBAT_SELF_MISSES" then
        local _, _, spell = string.find(arg1, "Your (.+) hits")
        if not spell then _, _, spell = string.find(arg1, "Your (.+) crits") end
        if not spell then _, _, spell = string.find(arg1, "Your (.+) misses") end
        
        if spell then
            if spell == "Heroic Strike" or spell == "Cleave" or 
               spell == "Maul" or spell == "Raptor Strike" or
               spell == "Mongoose Bite" then
                DetectSwingHand()
            end
        else
            DetectSwingHand()
        end
        
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        if string.find(arg1, "Auto Shot") or string.find(arg1, "Shoot") then
            StartMHSwing()
        end
    end
end)

-- ============================================================
-- SLASH COMMANDS
-- ============================================================
SLASH_SlimSwing1 = "/ss"
SLASH_SlimSwing2 = "/SlimSwing"

SlashCmdList["SlimSwing"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "" or msg == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff6699FF=== SlimSwing v6.2 ===|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFFF00/ss lock|r - Bloquear/Desbloquear")
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFFF00/ss thin|r - Alternar estilo delgado")
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFFF00/ss offhand|r - Mostrar/Ocultar off-hand")
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFFF00/ss timer|r - Mostrar/Ocultar tiempo")
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFFF00/ss reset|r - Resetear posicion")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00Tip:|r Click derecho para bloquear/desbloquear")
        
    elseif msg == "lock" then
        SlimSwingDB.locked = not SlimSwingDB.locked
        DEFAULT_CHAT_FRAME:AddMessage("|cff6699FF[SlimSwing]|r " .. (SlimSwingDB.locked and "|cffFF0000Bloqueado|r" or "|cff00FF00Desbloqueado|r"))
        
    elseif msg == "thin" then
        SlimSwingDB.thinMode = not SlimSwingDB.thinMode
        UpdateStyle()
        UpdateVisibility()
        DEFAULT_CHAT_FRAME:AddMessage("|cff6699FF[SlimSwing]|r Estilo: " .. (SlimSwingDB.thinMode and "|cff00FF00Delgado|r" or "|cffFFFF00Normal|r"))
        
    elseif msg == "offhand" then
        SlimSwingDB.showOffhand = not SlimSwingDB.showOffhand
        UpdateVisibility()
        DEFAULT_CHAT_FRAME:AddMessage("|cff6699FF[SlimSwing]|r Off-hand: " .. (SlimSwingDB.showOffhand and "|cff00FF00ON|r" or "|cffFF0000OFF|r"))
        
    elseif msg == "timer" then
        SlimSwingDB.showTimer = not SlimSwingDB.showTimer
        DEFAULT_CHAT_FRAME:AddMessage("|cff6699FF[SlimSwing]|r Timer: " .. (SlimSwingDB.showTimer and "|cff00FF00ON|r" or "|cffFF0000OFF|r"))
        
    elseif msg == "reset" then
        SlimSwingDB.pos = {x = 0, y = 100}
        LoadPosition()
        DEFAULT_CHAT_FRAME:AddMessage("|cff6699FF[SlimSwing]|r Posicion reseteada")
        
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff6699FF[SlimSwing]|r Usa |cffFFFF00/ss help|r")
    end
end