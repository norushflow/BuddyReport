local function loadAddon(options)
    local env = setmetatable({}, {__index = _G})
    local ns, frames, callbacks, forwarded = {}, {}, {}, {}
    local clientHandler = function(message)
        forwarded[#forwarded + 1] = message
        return "forwarded"
    end
    local handler = clientHandler
    local secret = {}
    local interface = options.forever and 16001 or 120105

    env.BuddyReportDB = options.saved
    env.issecretvalue = function(value) return value == secret end
    env.geterrorhandler = function() return handler end
    if options.missing then env.geterrorhandler = false end
    env.seterrorhandler = function(value)
        if not options.blocked then handler = value end
    end
    env.debugstack = function(level)
        if options.noErrorHeight then assert(level == 6) else assert(level == 7) end
        return options.stack or "[Fixture/Example.lua]:12: in function 'Run'"
    end
    env.GetCallstackHeight = function() return 9 end
    env.GetErrorCallstackHeight = function()
        if not options.noErrorHeight then return 3 end
    end
    env.EventRegistry = {RegisterCallback = function(_, event, callback, owner)
        callbacks[event] = function(...) callback(owner, ...) end
    end}
    env.C_CVar = {GetCVarBool = function(name)
        assert(name == "scriptErrors")
        return options.popups
    end}
    env.GetBuildInfo = function()
        if options.forever then return "1.60.1", "70938", "Nov 13 2026", interface end
        return "12.1.5", "70783", "Nov 4 2026", interface
    end
    env.date = function(format)
        assert(format == "%Y-%m-%d %H:%M:%S")
        return "2026-11-14 05:00:00"
    end
    env.GetLocale = function() return options.forever and "deDE" or "enUS" end
    env.UnitGUID = function(unit)
        assert(unit == "player")
        return options.secretGUID and secret or "Player-1-ABCDEF"
    end
    env.C_AddOns = {
        GetNumAddOns = function() return 3 end,
        GetAddOnInfo = function(index) return ({"ZDisabled", "BuddyReport", "AEnabled"})[index] end,
        GetAddOnMetadata = function(index, field)
            assert(field == "Version")
            return ({[2] = "1.0.0", [3] = "2.5", BuddyReport = "1.0.0"})[index]
        end,
        GetAddOnEnableState = function(index, character)
            assert(character == (not options.secretGUID and "Player-1-ABCDEF" or nil))
            return ({0, 2, 1})[index]
        end,
    }
    env.wipe = function(t)
        for key in pairs(t) do t[key] = nil end
    end
    local widget = {}
    widget.__index = widget
    local ignored = {
        "SetSize", "SetWidth", "SetHeight", "SetAllPoints", "SetFrameStrata",
        "SetClampedToScreen", "EnableMouse", "SetMovable", "StartMoving",
        "StopMovingOrSizing", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor",
        "SetColorTexture", "SetTextColor", "SetMultiLine", "SetAutoFocus",
        "SetAltArrowKeyMode", "SetTextInsets", "UpdateScrollChildRect", "SetCursorPosition",
    }
    for _, name in ipairs(ignored) do widget[name] = function() end end
    function widget:RegisterEvent(event) self.events[event] = true end
    function widget:UnregisterEvent(event) self.events[event] = nil end
    function widget:RegisterForClicks(button) self.click = button end
    function widget:RegisterForDrag(button) self.dragButton = button end
    function widget:SetTexture(path) self.texture = path end
    function widget:SetPoint(...) self.point = {...} end
    function widget:SetVertexColor(...) self.color = {...} end
    function widget:IsForbidden() return options.forbiddenMinimap end
    function widget:SetScript(event, callback) self[event] = callback end
    function widget:SetFont(path, _, flags)
        if self.kind == "EditBox" then
            assert(type(flags) == "string", "EditBox:SetFont requires flags")
        end
        return path == "Fonts\\FRIZQT__.TTF"
    end
    function widget:GetFont() return "Fonts\\FRIZQT__.TTF" end
    function widget:GetName() return self.name end
    function widget:SetText(value)
        self.textWrites = (self.textWrites or 0) + 1
        self.text = value
        if self.OnTextChanged then self:OnTextChanged(false) end
    end
    function widget:SetNormalTexture() self.normal = setmetatable({}, widget) end
    function widget:SetPushedTexture() self.pushed = setmetatable({}, widget) end
    function widget:SetHighlightTexture() self.highlight = setmetatable({}, widget) end
    function widget:GetNormalTexture() return self.normal end
    function widget:GetPushedTexture() return self.pushed end
    function widget:GetHighlightTexture() return self.highlight end
    function widget:GetWidth() return 1200 end
    function widget:GetHeight() return 220 end
    function widget:GetVerticalScrollRange() return 200 end
    function widget:GetVerticalScroll() return self.verticalScroll or 0 end
    function widget:SetVerticalScroll(offset) self.verticalScroll = offset end
    function widget:SetScrollChild(child) self.scrollChild = child end
    function widget:CreateTexture(_, layer)
        local texture = setmetatable({}, widget)
        self[layer] = texture
        return texture
    end
    function widget:CreateFontString()
        local label = setmetatable({kind = "FontString", parent = self}, widget)
        frames[#frames + 1] = label
        return label
    end
    function widget:IsShown() return not self.hidden end
    function widget:Show()
        self.hidden = false
        if self.OnShow then self:OnShow() end
    end
    function widget:Hide()
        self.hidden = true
        if self.OnHide then self:OnHide() end
    end
    function widget:SetMaxBytes(limit) self.maxBytes = limit end
    function widget:SetMaxLetters(limit) self.maxLetters = limit end
    function widget:SetFocus() self.focus = true end
    function widget:ClearFocus() self.focus = false end
    function widget:HighlightText(start, finish)
        self.selection = self.text:sub((start or 0) + 1, finish)
    end
    env.CreateFrame = function(kind, name, parent, template)
        local frame = setmetatable({kind = kind, name = name, parent = parent, template = template, events = {}}, widget)
        if name then env[name] = frame end
        frames[#frames + 1] = frame
        return frame
    end
    env.GameFontNormal = setmetatable({}, widget)
    env.UIParent = setmetatable({}, widget)
    if not options.noMinimap then
        env.Minimap = setmetatable({width = 140, height = 140}, widget)
        function env.Minimap:GetSize() return self.width, self.height end
        function env.Minimap:GetCenter() return 400, 300 end
        function env.Minimap:GetEffectiveScale() return .8 end
        function env.Minimap:GetMaskTexture() return options.minimapMask end
        function env.Minimap:HookScript(event, callback) self[event] = callback end
    end
    env.GetCursorPosition = function() return 320, 296 end
    env.GameTooltip = setmetatable({hidden = true}, widget)
    function env.GameTooltip:SetOwner(owner) self.owner = owner end
    function env.GameTooltip:IsOwned(owner) return self.owner == owner end
    function env.GameTooltip:AddLine(line) self.line = line end
    env.UISpecialFrames = {}
    env.SlashCmdList = {}
    env.tinsert = table.insert

    for _, file in ipairs({"Core.lua", "UI.lua"}) do
        setfenv(assert(loadfile(file)), env)("BuddyReport", ns)
    end
    local function dispatch(event, ...)
        for _, frame in ipairs(frames) do
            if frame.events and frame.events[event] then frame:OnEvent(event, ...) end
        end
    end
    dispatch("ADDON_LOADED", "OtherAddon")
    dispatch("ADDON_LOADED", "BuddyReport")
    assert(not env.BuddyReportMinimapButton)
    dispatch("PLAYER_LOGIN")
    local function fire(message)
        local function raise() error(message, 0) end
        return xpcall(raise, handler)
    end
    local function replaceHandler() handler = clientHandler end
    return ns, env, fire, callbacks, forwarded, frames, secret, replaceHandler, dispatch
end

local function contains(text, part)
    assert(text:find(part, 1, true), "Missing: " .. part)
end

local ns, env, fire, _, forwarded, frames, secret, replaceHandler = loadAddon({})
assert(ns.GetCaptureMode() == "client" and ns.GetErrorCount() == 0)
local minimapButton = env.BuddyReportMinimapButton
assert(minimapButton.parent == env.Minimap and minimapButton.click == "LeftButtonUp")
assert(minimapButton.dragButton == "LeftButton" and not minimapButton.OnUpdate)
assert(minimapButton.ARTWORK.texture == "Interface\\AddOns\\BuddyReport\\Media\\Icon.tga")
assert(minimapButton.ARTWORK.color[2] == 1)
assert(not env.BuddyReportWindow, "The window should be created on demand")
minimapButton:OnEnter()
assert(env.GameTooltip:IsShown() and env.GameTooltip.text == "BuddyReport (/br)")
assert(env.GameTooltip.line == "Drag to move")
minimapButton:OnLeave()
assert(not env.GameTooltip:IsShown())
assert(env.SLASH_BUDDYREPORT1 == "/br")
local cleanReport = ns.CreateReport()
contains(cleanReport, "World of Warcraft Retail 12.1.5 (build 70783, interface 120105)")
contains(cleanReport, "Client locale: enUS")
contains(cleanReport, "BuddyReport version: 1.0.0")
contains(cleanReport, "Blizzard Lua error popups: off")
contains(cleanReport, "No errors recorded.")
contains(cleanReport, "AEnabled | 2.5 | enabled\nBuddyReport | 1.0.0 | enabled\nZDisabled | unknown | disabled")
assert(not cleanReport:find("ABCDEF", 1, true))

minimapButton:OnDragStart()
assert(minimapButton.OnUpdate and math.abs(env.BuddyReportDB.minimapAngle - math.pi / 2) < .0001)
assert(minimapButton.point[5] == 70)
minimapButton:OnDragStop()
assert(not minimapButton.OnUpdate and not env.BuddyReportWindow)
env.Minimap.height = 180
env.Minimap:OnSizeChanged()
assert(minimapButton.point[5] == 90)
minimapButton:OnDragStart()
minimapButton:Hide()
assert(not minimapButton.OnUpdate)
minimapButton:Show()

local ok, result = fire("sample Lua error")
assert(not ok and result == "forwarded")
assert(minimapButton.ARTWORK.color[2] < 1 and minimapButton.OVERLAY.color[2] < .5)
fire("sample Lua error")
assert(ns.GetErrorCount() == 1 and #forwarded == 2)
env.geterrorhandler()(secret)
env.geterrorhandler()({})
assert(ns.GetErrorCount() == 1)
local report = ns.CreateReport()
contains(report, "Occurrences: 2")
contains(report, "Stack:\n[Fixture/Example.lua]:12: in function 'Run'")

local reloaded, reloadedEnv = loadAddon({saved = env.BuddyReportDB})
assert(reloaded.GetErrorCount() == 1)
contains(reloaded.CreateReport(), "Occurrences: 2")
assert(reloadedEnv.BuddyReportMinimapButton.point[5] > 65)
assert(reloadedEnv.BuddyReportMinimapButton.ARTWORK.color[2] < 1)

minimapButton:OnClick()
local reportWindow = env.BuddyReportWindow
assert(reportWindow:IsShown())
env.SlashCmdList.BUDDYREPORT()
assert(not reportWindow:IsShown())
minimapButton:OnClick()
assert(env.BuddyReportWindow == reportWindow and reportWindow:IsShown())
local editBox, scrollFrame, buttons
buttons = {}
for _, frame in ipairs(frames) do
    if frame.kind == "EditBox" then editBox = frame end
    if frame.kind == "ScrollFrame" then scrollFrame = frame end
    if frame.kind == "Button" and not frame.template and frame ~= minimapButton then
        buttons[#buttons + 1] = frame
    end
    assert(not frame.OnUpdate)
end
assert(scrollFrame.scrollChild == editBox)
assert(editBox.maxBytes == 0 and editBox.maxLetters == 0)
for i = 1, 55 do fire("different error " .. i .. " " .. string.rep("x", 1500)) end
assert(ns.GetErrorCount() == 50 and #env.BuddyReportDB.errors == 50)
assert(#env.BuddyReportDB.errors[1].message <= 1024)
contains(env.BuddyReportDB.errors[1].message, "different error 6 ")
contains(env.BuddyReportDB.errors[1].message, "[truncated]")
fire("different error 55 " .. string.rep("x", 1500))
assert(env.BuddyReportDB.errors[50].count == 2)
buttons[1]:OnClick()
assert(#editBox.text > 50000 and editBox.selection == ns.CreateReport() and editBox.focus)
editBox.text = "typed replacement"
editBox:OnTextChanged(true)
assert(editBox.text == editBox.selection)
editBox:OnCursorChanged(0, -300, 0, 12)
assert(scrollFrame.verticalScroll == 92)
buttons[2]:OnClick()
assert(ns.GetErrorCount() == 0 and #env.BuddyReportDB.errors == 0 and editBox.text == "" and not editBox.focus)
assert(minimapButton.ARTWORK.color[2] == 1 and minimapButton.OVERLAY.color[2] > .5)
assert(loadAddon({saved = env.BuddyReportDB}).GetErrorCount() == 0)
replaceHandler()
assert(ns.GetCaptureMode() == "unavailable")

local privacy, privacyEnv, redact = loadAddon({stack = "home/path\n" .. string.rep("ä", 2200)})
redact("player@example.org MyBattleTag#12345 |Kq12|k |Hplayer:Private|h[Private]|h " ..
    "/home/private/game C:\\Users\\private\\WoW Player-1-ABCDEF <WTF/Account/PRIVATE/Realm/Name.lua>")
local redacted = privacy.CreateReport()
for _, private in ipairs({"player@example.org", "MyBattleTag", "q12", "Private", "private", "ABCDEF", "PRIVATE"}) do
    assert(not redacted:find(private, 1, true))
end
contains(redacted, "[redacted name]")
contains(redacted, "[redacted link]")
contains(redacted, "[redacted path]")
assert(#privacyEnv.BuddyReportDB.errors[1].stack <= 4096)
assert(not privacyEnv.BuddyReportDB.errors[1].stack:match("\195\n%[truncated%]$"), "Truncation split a UTF-8 codepoint")

local missing = loadAddon({missing = true, secretGUID = true, saved = {errors = {{count = -1}, false}}})
assert(missing.GetCaptureMode() == "unavailable" and missing.GetErrorCount() == 0)
contains(missing.CreateReport(), "AEnabled | 2.5 | enabled for some characters")

local forever, foreverEnv, foreverFire, _, _, foreverFrames = loadAddon({forever = true, popups = true, noErrorHeight = true})
foreverFire("Forever test")
foreverEnv.debugstack = function() error("unavailable stack") end
foreverFire("Stack API failure")
contains(forever.CreateReport(), "World of Warcraft Forever 1.60.1 (build 70938, interface 16001)")
contains(forever.CreateReport(), "Client locale: deDE")
contains(forever.CreateReport(), "Message: Stack API failure\nStack:\n(unavailable)")
contains(forever.CreateReport(), "Blizzard Lua error popups: on")
assert(foreverEnv.BuddyReportMinimapButton.parent == foreverEnv.Minimap)
foreverEnv.BuddyReportMinimapButton:OnClick()
assert(foreverEnv.BuddyReportWindow:IsShown())
foreverEnv.BuddyReportMinimapButton:OnClick()
assert(not foreverEnv.BuddyReportWindow:IsShown())
foreverEnv.SlashCmdList.BUDDYREPORT()
assert(foreverEnv.BuddyReportWindow:IsShown())
assert(foreverEnv.UISpecialFrames[1] == "BuddyReportWindow")
local labels = {}
for _, frame in ipairs(foreverFrames) do
    if frame.kind == "FontString" then labels[frame.text] = frame end
end
assert(labels["Unterschiedliche Fehler: 2"])
assert(labels["Bericht erstellen"].parent.OnClick and labels["Fehler löschen"].parent.OnClick)

for _, options in ipairs({{noMinimap = true}, {forbiddenMinimap = true}}) do
    local _, noButton = loadAddon(options)
    assert(not noButton.BuddyReportMinimapButton)
    noButton.SlashCmdList.BUDDYREPORT()
    assert(noButton.BuddyReportWindow:IsShown())
end

local _, square = loadAddon({saved = {minimapAngle = math.pi / 4}, minimapMask = "Interface\\Buttons\\WHITE8X8"})
assert(math.abs(square.BuddyReportMinimapButton.point[4] - 70) < .0001)
assert(math.abs(square.BuddyReportMinimapButton.point[5] - 70) < .0001)

local bug, bugEnv, _, bugCallbacks, _, _, hiddenValue, _, dispatch = loadAddon({forever = true, blocked = true})
assert(bug.GetCaptureMode() == "unavailable")
bugEnv.BugGrabber = {
    GetErrorByID = function(_, id)
        return {message = id, stack = "BugGrabber stack"}
    end,
}
assert(bug.GetCaptureMode() == "BugGrabber")
local notification = bugCallbacks["BugGrabber.BugGrabbed"]
notification("BugGrabber example Lua error")
notification("BugGrabber example Lua error")
notification("LUA_WARNING: synthetic warning")
notification("[ADDON_ACTION_BLOCKED] synthetic event")
assert(bug.GetErrorCount() == 1)
assert(bugEnv.BuddyReportMinimapButton.ARTWORK.color[2] < 1)
contains(bug.CreateReport(), "Occurrences: 2")
contains(bug.CreateReport(), "Stack:\nBugGrabber stack")
bugEnv.BugGrabber.IsPaused = function() return true end
assert(bug.GetCaptureMode() == "unavailable")
dispatch("ADDON_ACTION_BLOCKED", "AzerothBuddyUI", "Reload()")
dispatch("ADDON_ACTION_BLOCKED", "AzerothBuddyUI", "Reload()")
dispatch("ADDON_ACTION_FORBIDDEN", hiddenValue, nil)
assert(bug.GetErrorCount() == 3)
local blockedReport = bug.CreateReport()
contains(blockedReport, "[ADDON_ACTION_BLOCKED] AzerothBuddyUI: Reload()")
contains(blockedReport, "[ADDON_ACTION_FORBIDDEN] (unknown addon): (unknown action)")
assert(bugEnv.BuddyReportDB.errors[2].count == 2)
for _, isForever in ipairs({false, true}) do
    local api, client, raise, _, _, widgets = loadAddon({forever=isForever})
    client.SlashCmdList.BUDDYREPORT()
    local label
    for _, widget in ipairs(widgets) do
        if widget.text == (isForever and 'Unterschiedliche Fehler: 0' or 'Distinct errors: 0') then
            label = widget
        end
    end
    assert(label)
    local writes = label.textWrites
    for i=1,100 do raise('repeated error') end
    assert(label.textWrites == writes+1, 'duplicate errors must not rewrite an unchanged count')
    contains(api.CreateReport(), 'Occurrences: 100')
    client.SlashCmdList.BUDDYREPORT() -- hide
    raise('another error')
    assert(label.textWrites == writes+1, 'hidden window must not update text')
    client.SlashCmdList.BUDDYREPORT() -- reopen
    assert(label.textWrites == writes+2 and label.text:sub(-1)=='2', 'reopen must show the latest count')
    api.ClearErrors()
    assert(label.textWrites == writes+3 and label.text:sub(-1)=='0', 'clearing must refresh immediately')
end
print("BuddyReport Lua tests passed (simulated Retail and Forever).")

local handled, handledEnv, _, handledCallbacks = loadAddon({})
handledCallbacks["BuddyReport.HandledError"]("AzerothBuddyUI", "layout import failed", "stack /home/private-user/WoW")
assert(handled.GetErrorCount() == 1)
local entry = handledEnv.BuddyReportDB.errors[1]
contains(entry.message, "AzerothBuddyUI: layout import failed")
contains(entry.stack, "/home/[redacted]/WoW")
