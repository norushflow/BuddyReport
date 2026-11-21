local addonName, ns = ...
local MAX_ERRORS, MAX_MESSAGE, MAX_STACK = 50, 1024, 4096
local MAX_COUNT = 2147483647
local DEFAULT_MINIMAP_ANGLE = math.rad(-175)
local errors, byMessage = {}, {}
local ownHandler, handlingError, bugGrabberCallbackRegistered
local isSecret = issecretvalue or function() return false end

local function readableString(value)
    return not isSecret(value) and type(value) == "string"
end

local function truncate(value, limit)
    if #value <= limit then return value end
    local suffix = "\n[truncated]"
    local last = limit - #suffix
    while value:byte(last + 1) >= 128 and value:byte(last + 1) < 192 do
        last = last - 1
    end
    return value:sub(1, last) .. suffix
end

local function sanitize(value, limit)
    if not readableString(value) then return "" end
    value = truncate(value, limit * 2):gsub("\r\n?", "\n")
    value = value:gsub("|[Kk][^|\n]*|[Kk]", "[redacted name]")
    value = value:gsub("|H[^\n]-|h[^\n]-|h", "[redacted link]")
    value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    value = value:gsub("([/\\][Uu]sers[/\\])[^/\\\n]+", "%1[redacted]")
    value = value:gsub("(/home/)[^/\n]+", "%1[redacted]")
    value = value:gsub("([Ww][Tt][Ff][/\\][Aa]ccount[/\\])[^\n\"'<>:]*", "%1[redacted path]")
    value = value:gsub("[%w._+%-]+@[%w.%-]+%.[%a%d]+", "[redacted email]")
    value = value:gsub("[%w_\128-\255%-]+#%d%d%d%d+", "[redacted BattleTag]")
    value = value:gsub("Player%-%d+%-%x+", "[redacted player ID]")

    if C_StringUtil and C_StringUtil.EscapeDecimalNonPrintables then
        value = C_StringUtil.EscapeDecimalNonPrintables(value)
    else
        value = value:gsub("[%z\1-\8\11\12\14-\31\127]", "?")
    end
    return truncate(value, limit)
end

local function fingerprint(message, stack)
    return message .. "\0" .. stack
end

local function storeError(message, stack, count)
    message = sanitize(message, MAX_MESSAGE)
    if message == "" then return end
    stack = sanitize(stack, MAX_STACK)
    local key = fingerprint(message, stack)
    local entry = byMessage[key]
    if entry then
        entry.count = math.min(entry.count + count, MAX_COUNT)
        return
    end
    if #errors == MAX_ERRORS then
        local oldest = table.remove(errors, 1)
        byMessage[fingerprint(oldest.message, oldest.stack)] = nil
    end
    entry = {message = message, stack = stack, count = count}
    byMessage[key] = entry
    errors[#errors + 1] = entry
end

local function loadSavedErrors()
    local db = type(BuddyReportDB) == "table" and BuddyReportDB or {}
    local saved = db.errors
    if type(saved) == "table" then
        for i = math.max(1, #saved - MAX_ERRORS + 1), #saved do
            local entry = saved[i]
            if type(entry) == "table" and type(entry.count) == "number" and entry.count >= 1 then
                storeError(entry.message, entry.stack, math.min(math.floor(entry.count), MAX_COUNT))
            end
        end
    end
    local angle = db.minimapAngle
    if type(angle) ~= "number" or not (angle >= -math.pi and angle <= math.pi) then
        angle = DEFAULT_MINIMAP_ANGLE
    end
    BuddyReportDB = {errors = errors, minimapAngle = angle}
end

local function saveError(message, stack)
    storeError(message, stack, 1)
    if ns.RefreshCount then ns.RefreshCount() end
end

local function getErrorStack()
    local level = 6
    if type(GetCallstackHeight) == "function" and type(GetErrorCallstackHeight) == "function" then
        local errorHeight = GetErrorCallstackHeight()
        if type(errorHeight) == "number" and errorHeight > 0 then
            level = math.max(1, GetCallstackHeight() - errorHeight + 1)
        end
    end
    return debugstack(level, 32, 0)
end

local function recordClientError(message)
    if not readableString(message) or message == "" then return end
    local stack
    if type(debugstack) == "function" then
        local ok, result = pcall(getErrorStack)
        if ok then stack = result end
    end
    saveError(message, stack)
end

local function currentHandler()
    if type(geterrorhandler) ~= "function" then return end
    local ok, handler = pcall(geterrorhandler)
    if ok and type(handler) == "function" then return handler end
end

local function installClientHandler()
    local previous = currentHandler()
    if not previous or type(seterrorhandler) ~= "function" then return end
    ownHandler = function(message, ...)
        if handlingError then return end
        handlingError = true
        pcall(recordClientError, message)
        local ok, result = pcall(previous, message, ...)
        handlingError = false
        if ok then return result end
    end
    pcall(seterrorhandler, ownHandler)
end

local function recordBugGrabberError(id)
    local entry = BugGrabber:GetErrorByID(id)
    if not entry or not readableString(entry.message) then return end
    if entry.message:find("^LUA_WARNING:") or entry.message:find("^%[ADDON_ACTION_") then return end
    saveError(entry.message, entry.stack)
end

local function connectBugGrabber()
    if not EventRegistry or type(EventRegistry.RegisterCallback) ~= "function" then return end
    -- Observe the optional public event even when BugGrabber is loaded on demand.
    bugGrabberCallbackRegistered = pcall(EventRegistry.RegisterCallback, EventRegistry, "BugGrabber.BugGrabbed", function(_, id)
        if not handlingError then pcall(recordBugGrabberError, id) end
    end, ns)
end

function ns.GetCaptureMode()
    if ownHandler and currentHandler() == ownHandler then return "client" end
    if bugGrabberCallbackRegistered and BugGrabber and type(BugGrabber.GetErrorByID) == "function" then
        if type(BugGrabber.IsPaused) == "function" then
            local ok, paused = pcall(BugGrabber.IsPaused, BugGrabber)
            if not ok or paused then return "unavailable" end
        end
        return "BugGrabber"
    end
    return "unavailable"
end

function ns.GetErrorCount()
    return #errors
end

function ns.ClearErrors()
    wipe(errors)
    wipe(byMessage)
    if ns.RefreshCount then ns.RefreshCount() end
end

local function addonState(index, character)
    local ok, state = pcall(C_AddOns.GetAddOnEnableState, index, character)
    if not ok or isSecret(state) then return "unknown" end
    if state == 0 then return "disabled" end
    if state == 1 then
        if character then return "enabled" end
        return "enabled for some characters"
    end
    if state == 2 then return "enabled" end
    return "unknown"
end

local function installedAddons()
    local ok, character = pcall(UnitGUID, "player")
    if not ok or not readableString(character) then character = nil end
    local list = {}
    for index = 1, C_AddOns.GetNumAddOns() do
        local name = C_AddOns.GetAddOnInfo(index)
        local version = sanitize(C_AddOns.GetAddOnMetadata(index, "Version"), 128)
        if version == "" then version = "unknown" end
        list[#list + 1] = ("%s | %s | %s"):format(sanitize(name, 128), version, addonState(index, character))
    end
    table.sort(list, function(a, b) return a:lower() < b:lower() end)
    return list
end

function ns.CreateReport()
    local version, build, _, interface = GetBuildInfo()
    local edition = "Retail"
    if interface == 16001 or version:match("^1%.60%.") then edition = "Forever" end
    local popupEnabled = C_CVar.GetCVarBool("scriptErrors")
    local lines = {
        "BuddyReport diagnostic report",
        "Generated (local time): " .. date("%Y-%m-%d %H:%M:%S"),
        ("World of Warcraft %s %s (build %s, interface %s)"):format(edition, version, build, interface),
        "Client locale: " .. GetLocale(),
        "BuddyReport version: " .. (C_AddOns.GetAddOnMetadata(addonName, "Version") or "unknown"),
        "Lua error capture: " .. ns.GetCaptureMode(),
        "Blizzard Lua error popups: " .. (popupEnabled and "on" or "off"),
        "",
        "Installed addons (name | version | enabled state)",
    }
    for _, addon in ipairs(installedAddons()) do lines[#lines + 1] = addon end
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("Saved errors (%d distinct)"):format(#errors)
    if #errors == 0 then lines[#lines + 1] = "No errors recorded." end
    for i = #errors, 1, -1 do
        local entry = errors[i]
        lines[#lines + 1] = ""
        lines[#lines + 1] = ("Error %d | Occurrences: %d"):format(#errors - i + 1, entry.count)
        lines[#lines + 1] = "Message: " .. entry.message
        lines[#lines + 1] = "Stack:"
        lines[#lines + 1] = entry.stack ~= "" and entry.stack or "(unavailable)"
    end
    return table.concat(lines, "\n")
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, addon, action)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent(event)
        ns.CreateMinimapButton()
        return
    end
    if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        local source = readableString(addon) and addon or "(unknown addon)"
        local operation = readableString(action) and action or "(unknown action)"
        saveError(("[%s] %s: %s"):format(event, source, operation))
        return
    end
    if addon ~= addonName then return end
    self:UnregisterEvent(event)
    loadSavedErrors()
    self:RegisterEvent("ADDON_ACTION_BLOCKED")
    self:RegisterEvent("ADDON_ACTION_FORBIDDEN")
    installClientHandler()
    connectBugGrabber()
    if EventRegistry and type(EventRegistry.RegisterCallback) == "function" then
        pcall(EventRegistry.RegisterCallback, EventRegistry, "BuddyReport.HandledError", function(_, source, message, stack)
            if readableString(source) and readableString(message) and message ~= "" then
                pcall(saveError, "[Handled Lua error] " .. source .. ": " .. message, stack)
            end
        end, ns)
    end
end)
