-- ~/.hammerspoon/power_wattage.lua
--
-- Menubar readout for the power flowing into the Mac.
--
-- Source of truth is the battery controller's PowerTelemetryData block, which
-- reports the power the AC adapter actually delivers after USB-PD negotiation
-- (SystemPowerIn, in mW). AdapterDetails.Watts is only the charger's rating, so
-- it is used as a fallback for machines that do not expose PowerTelemetryData.
--
-- Display modes (persisted in hs.settings):
--   input   - measured power in from the adapter (default)
--   adapter - charger rating (e.g. 45 W)
--   battery - power flowing into/out of the battery pack

local M = {}

local IOREG = "/usr/sbin/ioreg"
local REFRESH_SECONDS = 2

local MODE_LABELS = {
    input = "Power in (measured)",
    adapter = "Adapter rating",
    battery = "Battery power",
}

local mode = "input"
local menubarItem, timer, lastTitle

-------------------------------------------------------------------------------
-- ioreg parsing helpers
-------------------------------------------------------------------------------

local function raw(blob, name)
    return blob and blob:match('"' .. name .. '"%s*=%s*(-?%d+)') or nil
end

local function num(blob, name)
    local v = raw(blob, name)
    return v and tonumber(v) or nil
end

local function str(blob, name)
    return blob and blob:match('"' .. name .. '"%s*=%s*"([^"]*)"') or nil
end

-- Top level ioreg values are bare ("Yes"/"10"/"pd charger"), not inline dicts.
local function flag(value)
    return value == "Yes"
end

-- Current macOS keeps the charge flag inside ChargerData as a number instead of
-- a top level "IsCharging" = Yes/No.
local function chargingState(top)
    if top.IsCharging then return flag(top.IsCharging) end
    local charger = top.ChargerData
    return charger ~= nil and charger:match('"IsCharging"%s*=%s*1') ~= nil
end

local function digits(value)
    return value and value:match("^(-?%d+)") or nil
end

-- ioreg prints negative 64 bit values as their unsigned two's complement, e.g.
-- -9259 mW comes out as 18446744073709542357. tonumber() converts such a value
-- to a float and drops the low bits (18446744073709550918 - 2^64 evaluates to
-- 0 instead of -698), so the wrap is undone on the decimal string itself.
local TWO_POW_64 = "18446744073709551616"
local MAX_INT64 = 9223372036854775807

-- a - b for non-negative decimal strings with a >= b, exact at any length.
local function decimalSubtract(a, b)
    b = string.rep("0", #a - #b) .. b
    local out, borrow = {}, 0
    for i = #a, 1, -1 do
        local d = tonumber(a:sub(i, i)) - tonumber(b:sub(i, i)) - borrow
        if d < 0 then d, borrow = d + 10, 1 else borrow = 0 end
        out[i] = d
    end
    local result = table.concat(out):gsub("^0+", "")
    return result == "" and "0" or result
end

--- Exact signed number from a decimal string that may hold a 64 bit wrap-around.
local function signed(text)
    if not text then return nil end
    local negative = text:sub(1, 1) == "-"
    local body = negative and text:sub(2) or text
    if #body > 20 then return nil end

    local v = tonumber(body)
    if not v then return nil end
    if v > MAX_INT64 then                      -- unsigned wrap: v - 2^64
        local magnitude = tonumber(decimalSubtract(TWO_POW_64, body))
        return magnitude and -magnitude or nil
    end
    return negative and -v or v
end

-------------------------------------------------------------------------------
-- state
-------------------------------------------------------------------------------

--- M.read() -> table|nil
--- Live power state. Millivolt/milliamp inputs are kept raw; watts are W.
function M.read()
    local out = hs.execute(IOREG .. " -rn AppleSmartBattery -w0")
    if not out or out == "" then return nil end

    -- Every property line starts with the tree text ioreg draws ("  |   " on
    -- current macOS, plain indentation on older releases), so the marker belongs
    -- to the prefix. Nested dicts are printed inline on one line, which is why
    -- only top level keys ever start a line.
    local top = {}
    for line in out:gmatch("[^\r\n]+") do
        local key, value = line:match('^[%s|]*"([%w_]+)"%s*=%s*(.*)$')
        if key and value and not top[key] then top[key] = value end
    end

    -- AppleRawExternalConnected is the older spelling; prefer the plain key.
    local external = top.ExternalConnected or top.AppleRawExternalConnected
    if not external then return nil end

    local tel, adapter = top.PowerTelemetryData, top.AdapterDetails

    local percent = hs.battery.percentage() or tonumber(digits(top.CurrentCapacity))

    local info = {
        external = flag(external),
        charging = chargingState(top),
        percent = percent,
        adapterWatts = num(adapter, "Watts"),
        adapterVoltage = num(adapter, "AdapterVoltage"), -- mV
        adapterCurrent = num(adapter, "Current"),        -- mA
        adapterName = str(adapter, "Description"),
        inputVoltage = num(tel, "SystemVoltageIn"),      -- mV
        inputCurrent = num(tel, "SystemCurrentIn"),      -- mA
        packVoltage = tonumber(digits(top.Voltage)),       -- mV
        packAmperage = signed(digits(top.InstantAmperage) or digits(top.Amperage)),
    }

    local pin = num(tel, "SystemPowerIn")
    if pin then info.inputPower = pin / 1000 end
    local load = num(tel, "SystemLoad")
    if load then info.systemLoad = load / 1000 end
    local bp = signed(raw(tel, "BatteryPower"))
    if bp then info.batteryPower = bp / 1000 end

    -- Fallback: no telemetry block at all (older Intel Macs), or the controller
    -- reports 0 while it has nothing measured yet.
    if (not info.batteryPower or info.batteryPower == 0) and info.packVoltage and info.packAmperage then
        info.batteryPower = (info.packVoltage * info.packAmperage) / 1000000
    end

    return info
end

-------------------------------------------------------------------------------
-- formatting
-------------------------------------------------------------------------------

local function watts(w)
    if not w then return "--" end
    if math.abs(w) >= 10 then return string.format("%.0f W", w) end
    return string.format("%.1f W", w)
end

local function titleWatts(w)
    if not w then return "--" end
    if math.abs(w) >= 10 then return string.format("%.0fW", w) end
    return string.format("%.1fW", w)
end

--- Value + icon for the menubar title.
local function display(info)
    if not info.external then
        local w = info.batteryPower and -math.abs(info.batteryPower) or nil
        return w, "🔋"
    end
    if mode == "adapter" then
        return info.adapterWatts, "⚡"
    elseif mode == "battery" then
        return info.batteryPower, "⚡"
    end
    return info.inputPower or info.adapterWatts, "⚡"
end

local function tooltip(info)
    local lines = {
        "Power in: " .. watts(info.inputPower),
        "Adapter: " .. (info.adapterWatts and string.format("%.0f W", info.adapterWatts) or "--")
            .. (info.adapterName and (" · " .. info.adapterName) or ""),
        "System load: " .. watts(info.systemLoad),
        "Battery: " .. (info.batteryPower and string.format("%+.1f W", info.batteryPower) or "--")
            .. (info.charging and " (charging)" or ""),
        string.format("Level: %d%%", info.percent or 0),
    }
    return table.concat(lines, "\n")
end

-------------------------------------------------------------------------------
-- menubar
-------------------------------------------------------------------------------

local function setMode(newMode)
    if not MODE_LABELS[newMode] then return end
    mode = newMode
    hs.settings.set("powerWattage.mode", mode)
    M.update()
end

function M.update()
    if not menubarItem then return end
    local info = M.read()
    if not info then
        if lastTitle ~= "⚡--" then
            menubarItem:setTitle("⚡--")
            lastTitle = "⚡--"
        end
        menubarItem:setTooltip("Battery / AC adapter data unavailable")
        return
    end

    local w, icon = display(info)
    local title = icon .. titleWatts(w)
    if title ~= lastTitle then
        menubarItem:setTitle(title)
        lastTitle = title
    end
    menubarItem:setTooltip(tooltip(info))
end

local function menu()
    local info = M.read()
    local items = {}

    if not info then
        items[#items + 1] = { title = "No battery data available", disabled = true }
    else
        items[#items + 1] = { title = "Power in: " .. watts(info.inputPower), disabled = true }
        items[#items + 1] = {
            title = "Adapter: " .. (info.adapterWatts and string.format("%.0f W", info.adapterWatts) or "--")
                .. (info.adapterName and (" · " .. info.adapterName) or ""),
            disabled = true,
        }
        items[#items + 1] = { title = "System load: " .. watts(info.systemLoad), disabled = true }
        items[#items + 1] = {
            title = "Battery: " .. (info.batteryPower and string.format("%+.1f W", info.batteryPower) or "--")
                .. (info.charging and " (charging)" or ""),
            disabled = true,
        }
        items[#items + 1] = { title = string.format("Level: %d%%", info.percent or 0), disabled = true }
    end

    items[#items + 1] = { title = "-" }

    local modeItems = {}
    for _, key in ipairs({ "input", "adapter", "battery" }) do
        modeItems[#modeItems + 1] = {
            title = MODE_LABELS[key],
            checked = (mode == key),
            fn = function() setMode(key) end,
        }
    end
    items[#items + 1] = { title = "Show", menu = modeItems }

    items[#items + 1] = { title = "-" }
    items[#items + 1] = { title = "Refresh now", fn = function() M.update() end }
    items[#items + 1] = { title = "Reload config", fn = function() hs.reload() end }
    return items
end

function M.start()
    mode = hs.settings.get("powerWattage.mode") or "input"
    if not MODE_LABELS[mode] then mode = "input" end

    menubarItem = hs.menubar.new()
    menubarItem:setMenu(menu)
    M.update()

    timer = hs.timer.new(REFRESH_SECONDS, M.update)
    timer:start()

    -- Repaint immediately on AC plug/unplug instead of waiting for the timer.
    local ok, watcher = pcall(hs.battery.watcher.new, M.update)
    if ok and watcher then watcher:start() end

    return menubarItem
end

return M
