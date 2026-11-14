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
        "SetSize", "SetWidth", "SetHeight", "SetPoint", "SetAllPoints", "SetFrameStrata",
        "SetClampedToScreen", "EnableMouse", "SetMovable", "RegisterForDrag", "StartMoving",
        "StopMovingOrSizing", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor",
        "SetColorTexture", "SetVertexColor", "SetTextColor", "SetMultiLine", "SetAutoFocus",
        "SetAltArrowKeyMode", "SetTextInsets", "UpdateScrollChildRect", "SetCursorPosition",
        "RegisterEvent", "UnregisterEvent",
    }
    for _, name in ipairs(ignored) do widget[name] = function() end end
    function widget:SetScript(event, callback) self[event] = callback end
    function widget:SetFont(path) return path == "Fonts\\FRIZQT__.TTF" end
    function widget:GetFont() return "Fonts\\FRIZQT__.TTF" end
    function widget:GetName() return self.name end
    function widget:SetText(value)
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
    function widget:CreateTexture() return setmetatable({}, widget) end
    function widget:CreateFontString() return setmetatable({}, widget) end
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
    env.CreateFrame = function(kind, name, _, template)
        local frame = setmetatable({kind = kind, name = name, template = template}, widget)
        frames[#frames + 1] = frame
        return frame
    end
    env.GameFontNormal = setmetatable({}, widget)
    env.UIParent = setmetatable({}, widget)
    env.UISpecialFrames = {}
    env.SlashCmdList = {}
    env.tinsert = table.insert

    for _, file in ipairs({"Core.lua", "UI.lua"}) do
        setfenv(assert(loadfile(file)), env)("BuddyReport", ns)
    end
    frames[1]:OnEvent("ADDON_LOADED", "OtherAddon")
    frames[1]:OnEvent("ADDON_LOADED", "BuddyReport")
    local function fire(message)
        local function raise() error(message, 0) end
        return xpcall(raise, handler)
    end
    local function replaceHandler() handler = clientHandler end
    return ns, env, fire, callbacks, forwarded, frames, secret, replaceHandler
end

local function contains(text, part)
    assert(text:find(part, 1, true), "Missing: " .. part)
end

local ns, env, fire, _, forwarded, frames, secret, replaceHandler = loadAddon({})
assert(ns.GetCaptureMode() == "client" and ns.GetErrorCount() == 0)
assert(#frames == 1, "The window should be created on demand")
assert(env.SLASH_BUDDYREPORT1 == "/br")
local cleanReport = ns.CreateReport()
contains(cleanReport, "World of Warcraft Retail 12.1.5 (build 70783, interface 120105)")
contains(cleanReport, "Client locale: enUS")
contains(cleanReport, "BuddyReport version: 1.0.0")
contains(cleanReport, "Blizzard Lua error popups: off")
contains(cleanReport, "No Lua errors recorded.")
contains(cleanReport, "AEnabled | 2.5 | enabled\nBuddyReport | 1.0.0 | enabled\nZDisabled | unknown | disabled")
assert(not cleanReport:find("ABCDEF", 1, true))

local ok, result = fire("sample Lua error")
assert(not ok and result == "forwarded")
fire("sample Lua error")
assert(ns.GetErrorCount() == 1 and #forwarded == 2)
env.geterrorhandler()(secret)
env.geterrorhandler()({})
assert(ns.GetErrorCount() == 1)
local report = ns.CreateReport()
contains(report, "Occurrences: 2")
contains(report, "Stack:\n[Fixture/Example.lua]:12: in function 'Run'")

local reloaded = loadAddon({saved = env.BuddyReportDB})
assert(reloaded.GetErrorCount() == 1)
contains(reloaded.CreateReport(), "Occurrences: 2")

env.SlashCmdList.BUDDYREPORT()
local editBox, scrollFrame, buttons
buttons = {}
for _, frame in ipairs(frames) do
    if frame.kind == "EditBox" then editBox = frame end
    if frame.kind == "ScrollFrame" then scrollFrame = frame end
    if frame.kind == "Button" and not frame.template then buttons[#buttons + 1] = frame end
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

local forever, foreverEnv, foreverFire = loadAddon({forever = true, popups = true, noErrorHeight = true})
foreverFire("Forever test")
foreverEnv.debugstack = function() error("unavailable stack") end
foreverFire("Stack API failure")
contains(forever.CreateReport(), "World of Warcraft Forever 1.60.1 (build 70938, interface 16001)")
contains(forever.CreateReport(), "Client locale: deDE")
contains(forever.CreateReport(), "Message: Stack API failure\nStack:\n(unavailable)")
contains(forever.CreateReport(), "Blizzard Lua error popups: on")

local bug, bugEnv, _, bugCallbacks = loadAddon({forever = true, blocked = true})
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
contains(bug.CreateReport(), "Occurrences: 2")
contains(bug.CreateReport(), "Stack:\nBugGrabber stack")
bugEnv.BugGrabber.IsPaused = function() return true end
assert(bug.GetCaptureMode() == "unavailable")
print("BuddyReport Lua tests passed (simulated Retail and Forever).")
