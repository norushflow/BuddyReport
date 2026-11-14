local addonName, ns = ...
local de = GetLocale() == "deDE"
local window, reportBox, errorCount, captureStatus, scroll
local minimapIcon, minimapBorder, minimapHasErrors
local report = ""
local fontPath
local white = "Interface\\Buttons\\WHITE8X8"
local expressway = "Interface\\AddOns\\" .. addonName .. "\\Media\\Expressway.ttf"
local gold = {1, .82, .44, 1}
local textColor = {.96, .91, .81, 1}
local muted = {.76, .70, .61, 1}
local isSecret = issecretvalue or function() return false end

local function setFont(widget, size, color)
    if not fontPath then
        local locale = GetLocale()
        if locale ~= "koKR" and locale ~= "zhCN" and locale ~= "zhTW" then
            local ok, loaded = pcall(widget.SetFont, widget, expressway, size, "")
            if ok and loaded then fontPath = expressway end
        end
        fontPath = fontPath or GameFontNormal:GetFont()
    end
    widget:SetFont(fontPath, size, "")
    widget:SetTextColor(unpack(color))
end

local function panel(parent, color)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetBackdrop({bgFile = white, edgeFile = white, edgeSize = 1})
    frame:SetBackdropColor(unpack(color))
    frame:SetBackdropBorderColor(.56, .40, .22, .83)
    return frame
end

local function label(parent, value, size, color)
    local widget = parent:CreateFontString(nil, "OVERLAY")
    setFont(widget, size, color)
    widget:SetText(value)
    return widget
end

local function button(parent, value, action)
    local widget = CreateFrame("Button", nil, parent)
    widget:SetSize(150, 26)
    for _, kind in ipairs({
        {"SetNormalTexture", "GetNormalTexture", .23, .16, .09, 1},
        {"SetPushedTexture", "GetPushedTexture", .32, .22, .12, 1},
        {"SetHighlightTexture", "GetHighlightTexture", 1, .74, .35, .16},
    }) do
        widget[kind[1]](widget, white)
        widget[kind[2]](widget):SetVertexColor(unpack(kind, 3))
    end
    local caption = label(widget, value, 13, textColor)
    caption:SetPoint("CENTER")
    widget:SetScript("OnClick", action)
    return widget
end

local function setReport(value)
    report = value
    reportBox:SetText(value)
    reportBox:SetCursorPosition(0)
    scroll:UpdateScrollChildRect()
    scroll:SetVerticalScroll(0)
end

function ns.RefreshCount()
    local count = ns.GetErrorCount()
    if window and window:IsShown() then
        errorCount:SetText((de and "Unterschiedliche Fehler: %d" or "Distinct errors: %d"):format(count))
    end
    local hasErrors = count > 0
    if minimapIcon and minimapHasErrors ~= hasErrors then
        if hasErrors then
            minimapIcon:SetVertexColor(1, .42, .40)
            minimapBorder:SetVertexColor(1, .24, .21, 1)
        else
            minimapIcon:SetVertexColor(1, 1, 1)
            minimapBorder:SetVertexColor(unpack(gold))
        end
        minimapHasErrors = hasErrors
    end
end

local function refreshCaptureStatus()
    local mode = ns.GetCaptureMode()
    local text = ""
    if mode == "unavailable" then
        text = de and "Fehlererfassung nicht verfügbar" or "Error capture unavailable"
    elseif mode == "BugGrabber" then
        text = de and "Fehlerquelle: BugGrabber" or "Error source: BugGrabber"
    end
    captureStatus:SetText(text)
end

local function createWindow()
    local width = math.min(660, UIParent:GetWidth() - 32)
    local height = math.min(430, UIParent:GetHeight() - 32)
    window = CreateFrame("Frame", "BuddyReportWindow", UIParent)
    window:SetSize(width, height)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:Hide()
    tinsert(UISpecialFrames, window:GetName())

    local background = panel(window, {.048, .035, .024, .98})
    background:SetAllPoints(window)
    local header = background:CreateTexture(nil, "ARTWORK")
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(35)
    header:SetColorTexture(.20, .12, .055, .74)
    local title = label(background, "BuddyReport", 20, gold)
    title:SetPoint("TOPLEFT", 14, -9)
    local close = CreateFrame("Button", nil, background, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -1)
    close:SetScript("OnClick", function() window:Hide() end)

    errorCount = label(background, "", 13, textColor)
    errorCount:SetPoint("TOPLEFT", 14, -47)
    captureStatus = label(background, "", 12, muted)
    captureStatus:SetPoint("TOPRIGHT", -14, -47)

    local inset = panel(background, {.026, .021, .016, 1})
    inset:SetPoint("TOPLEFT", 13, -69)
    inset:SetPoint("BOTTOMRIGHT", -13, 75)
    scroll = CreateFrame("ScrollFrame", nil, inset, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 5, -5)
    scroll:SetPoint("BOTTOMRIGHT", -26, 5)

    reportBox = CreateFrame("EditBox", nil, scroll)
    reportBox:SetWidth(width - 57)
    reportBox:SetMultiLine(true)
    reportBox:SetAutoFocus(false)
    reportBox:SetAltArrowKeyMode(false)
    reportBox:SetMaxBytes(0)
    reportBox:SetMaxLetters(0)
    reportBox:SetTextInsets(2, 2, 2, 2)
    reportBox:SetScript("OnEscapePressed", function() window:Hide() end)
    reportBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then self:SetText(report) end
    end)
    reportBox:SetScript("OnCursorChanged", function(_, _, y, _, lineHeight)
        local top = scroll:GetVerticalScroll()
        local bottom = top + scroll:GetHeight()
        y = -y
        if y < top or y + lineHeight > bottom then
            local offset = y < top and y or y + lineHeight - scroll:GetHeight()
            scroll:SetVerticalScroll(math.max(0, math.min(offset, scroll:GetVerticalScrollRange())))
        end
    end)
    setFont(reportBox, 12, textColor)
    scroll:SetScrollChild(reportBox)

    local hint = label(background, de and "Strg+A, Strg+C · Bericht vor dem Teilen prüfen."
        or "Ctrl+A, Ctrl+C · Review the report before sharing.", 12, muted)
    hint:SetPoint("BOTTOMLEFT", 14, 50)

    local generate = button(background, de and "Bericht erstellen" or "Create report", function()
        setReport(ns.CreateReport())
        refreshCaptureStatus()
        reportBox:SetFocus()
        reportBox:HighlightText(0)
    end)
    generate:SetPoint("BOTTOMLEFT", 13, 13)

    local clear = button(background, de and "Fehler löschen" or "Clear errors", function()
        ns.ClearErrors()
        setReport("")
        reportBox:ClearFocus()
        refreshCaptureStatus()
    end)
    clear:SetPoint("BOTTOMRIGHT", -13, 13)

    window:SetScript("OnShow", function()
        ns.RefreshCount()
        refreshCaptureStatus()
    end)
    window:SetScript("OnHide", function()
        reportBox:ClearFocus()
    end)
end

local function toggleWindow()
    if not window then createWindow() end
    if window:IsShown() then window:Hide() else window:Show() end
end

SLASH_BUDDYREPORT1 = "/br"
SlashCmdList.BUDDYREPORT = toggleWindow

local function isNumber(value)
    return not isSecret(value) and type(value) == "number"
end

function ns.CreateMinimapButton()
    local map = Minimap
    if not map or map:IsForbidden() then return end

    local button = CreateFrame("Button", "BuddyReportMinimapButton", map)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetClampedToScreen(true)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    minimapIcon = button:CreateTexture(nil, "ARTWORK")
    minimapIcon:SetSize(18, 18)
    minimapIcon:SetPoint("CENTER")
    minimapIcon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Media\\Icon.tga")

    minimapBorder = button:CreateTexture(nil, "OVERLAY")
    minimapBorder:SetSize(52, 52)
    minimapBorder:SetPoint("TOPLEFT")
    minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local function place()
        local width, height = map:GetSize()
        if not (isNumber(width) and isNumber(height)) or width <= 0 or height <= 0 then return end
        local angle = BuddyReportDB.minimapAngle
        local x, y = math.cos(angle), math.sin(angle)
        local mask = map.GetMaskTexture and map:GetMaskTexture()
        local shape = GetMinimapShape and GetMinimapShape()
        if (not isSecret(shape) and shape == "SQUARE") or (not isSecret(mask) and mask == white) then
            local edge = math.max(math.abs(x), math.abs(y))
            x, y = x / edge, y / edge
        end
        button:SetPoint("CENTER", map, "CENTER", x * width / 2, y * height / 2)
    end

    local function drag()
        local centerX, centerY = map:GetCenter()
        local width, height = map:GetSize()
        local scale = map:GetEffectiveScale()
        if not (isNumber(centerX) and isNumber(centerY) and isNumber(width) and isNumber(height)
            and isNumber(scale)) or width <= 0 or height <= 0 or scale <= 0 then return end
        local cursorX, cursorY = GetCursorPosition()
        if not (isNumber(cursorX) and isNumber(cursorY)) then return end
        local x = (cursorX / scale - centerX) / width
        local y = (cursorY / scale - centerY) / height
        if x == 0 and y == 0 then return end
        BuddyReportDB.minimapAngle = math.atan2(y, x)
        place()
    end

    button:SetScript("OnClick", toggleWindow)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("BuddyReport (/br)")
        GameTooltip:AddLine(de and "Ziehen: Position ändern" or "Drag to move", unpack(muted, 1, 3))
        GameTooltip:Show()
    end)
    local function hideTooltip(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end
    button:SetScript("OnLeave", hideTooltip)
    button:SetScript("OnDragStart", function(self)
        hideTooltip(self)
        self:SetScript("OnUpdate", drag)
        drag()
    end)
    local function stopDrag(self)
        self:SetScript("OnUpdate", nil)
    end
    button:SetScript("OnDragStop", stopDrag)
    button:SetScript("OnHide", function(self)
        stopDrag(self)
        hideTooltip(self)
    end)
    map:HookScript("OnSizeChanged", place)
    button:SetScript("OnShow", place)
    place()
    ns.RefreshCount()
end
