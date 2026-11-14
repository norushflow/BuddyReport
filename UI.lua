local addonName, ns = ...
local de = GetLocale() == "deDE"
local window, reportBox, errorCount, captureStatus, scroll
local report = ""
local fontPath
local white = "Interface\\Buttons\\WHITE8X8"
local expressway = "Interface\\AddOns\\" .. addonName .. "\\Media\\Expressway.ttf"
local gold = {1, .82, .44, 1}
local textColor = {.96, .91, .81, 1}
local muted = {.76, .70, .61, 1}

local function setFont(widget, size, color)
    if not fontPath then
        local locale = GetLocale()
        if locale ~= "koKR" and locale ~= "zhCN" and locale ~= "zhTW" then
            local ok, loaded = pcall(widget.SetFont, widget, expressway, size)
            if ok and loaded then fontPath = expressway end
        end
        fontPath = fontPath or GameFontNormal:GetFont()
    end
    widget:SetFont(fontPath, size)
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
    if window and window:IsShown() then
        errorCount:SetText((de and "Unterschiedliche Fehler: %d" or "Distinct errors: %d"):format(ns.GetErrorCount()))
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
        ns.RefreshCount()
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

SLASH_BUDDYREPORT1 = "/br"
SlashCmdList.BUDDYREPORT = function()
    if not window then createWindow() end
    if window:IsShown() then window:Hide() else window:Show() end
end
