local mash      = {"cmd", "alt", "ctrl"}
local shift_mash      = {"cmd", "alt", "ctrl", "shift"}
hsreload_keys = {{"cmd", "alt", "ctrl"}, "R"}
hslock_keys = {{"cmd", "alt", "ctrl"}, "L"}

hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall.use_syncinstall = true
Install=spoon.SpoonInstall

local wm=hs.webview.windowMasks
Install:andUse("PopupTranslateSelection",
  {
    config = {
      popup_style = wm.utility|wm.HUD|wm.titled|
      wm.closable|wm.resizable,
    },
    hotkeys = {
      translate_to_en = { mash, "e" },
      translate_to_vi = { mash, "v" }
    }
  }
)

hspoon_list = {
    -- "AClock",
    -- "ClipShow",
    "CountDown",
    "FnMate",
    "HSaria2",
    "KSheet",
    "SpeedMenu",
    "WinWin",
}

function moveWindowToDisplay(d)
  return function()
    local displays = hs.screen.allScreens()
    local win = hs.window.focusedWindow()
    win:moveToScreen(displays[d], false, true)
  end
end

function moveWindowToNextDisplay()
    local app = hs.window.focusedWindow()
    app:moveToScreen(app:screen():next(), false, true)
    -- app:maximize()
end

hs.hotkey.bind(mash, "1", moveWindowToDisplay(1))
hs.hotkey.bind(mash, "2", moveWindowToDisplay(2))
hs.hotkey.bind(mash, "tab", moveWindowToNextDisplay)

local caffeine = hs.menubar.new()

function spotifyNext()
    hs.spotify.next()
end

function displayCurrentTrack()
    hs.spotify.displayCurrentTrack()
end

hs.hotkey.bind(mash, 'space', displayCurrentTrack)
hs.hotkey.bind('alt', 'm', displayCurrentTrack)
hs.hotkey.bind('alt', 'p', hs.spotify.playpause)
hs.hotkey.bind('alt', 'n', hs.spotify.next)
hs.hotkey.bind('alt', '=', hs.spotify.volumeUp)
hs.hotkey.bind('alt', '-', hs.spotify.volumeDown)

local function updateCaffeineDisplay(state)
    local result
    if state then
        caffeine:setIcon("caffeine-active.png")
        -- caffeine:setTitle("AWAKE")
        hs.alert("Caffeine enabled", 1)
    else
        caffeine:setIcon("caffeine-inactive.png")
        -- caffeine:setTitle("SLEEPY")
        hs.alert("Caffeine disabled", 1)
    end
end

function toggleCaffeine()
    updateCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
end

function removeCaffeine()
    caffeine:delete()
    caffeine = nil
end

hs.hotkey.bind(mash, "c", toggleCaffeine)

-- Toggle fullscreen
local pn    = { fn = {} }

function pn.toggleFullScreen()
    local win = hs.window.focusedWindow()
    if not win then return end
    win:toggleFullScreen()
end

hs.hotkey.bind(mash, "Return", pn.toggleFullScreen)

-- Reconnect to current Wifi
function ssidChangedCallback()
    local ssid = hs.wifi.currentNetwork()
    if ssid then
      hs.alert.show("Network connected: " .. ssid)
    end
end

hs.wifi.watcher.new(ssidChangedCallback):start()

hs.hotkey.bind(mash, "d", function()
  local ssid = hs.wifi.currentNetwork()
  if not ssid then return end

  hs.alert.show("Reconnecting to: " .. ssid)
  hs.execute("networksetup -setairportpower en0 off")
  hs.execute("networksetup -setairportpower en0 on")
end)


-- Battery
local previousPowerSource = hs.battery.powerSource()

function minutesToHours(minutes)
  if minutes <= 0 then
    return "0:00";
  else
    hours = string.format("%d", math.floor(minutes / 60))
    mins = string.format("%02.f", math.floor(minutes - (hours * 60)))
    return string.format("%s:%s", hours, mins)
  end
end

function showBatteryStatus()
  local message

  if hs.battery.isCharging() then
    local pct = hs.battery.percentage()
    local untilFull = hs.battery.timeToFullCharge()
    message = "Charging:"

    if untilFull == -1 then
      message = string.format("%s %.0f%% (calculating...)", message, pct);
    else
      local watts = hs.battery.watts()
      message = string.format("%s %.0f%% (%s remaining @ %.1fW)", message, pct, minutesToHours(untilFull), watts)
    end
  elseif hs.battery.powerSource() == "Battery Power" then
    local pct = hs.battery.percentage()
    local untilEmpty = hs.battery.timeRemaining()
    message = "Battery:"

    if untilEmpty == -1 then
      message = string.format("%s %.0f%% (calculating...)", message, pct)
    else
      local watts = hs.battery.watts()
      message = string.format("%s %.0f%% (%s remaining @ %.1fW)", message, pct, minutesToHours(untilEmpty), watts)
    end
  else
    message = "Fully charged"
  end

  hs.alert.show(message)
end

function batteryChangedCallback()
  local powerSource = hs.battery.powerSource()

  if powerSource ~= previousPowerSource then
    showBatteryStatus()
    previousPowerSource = powerSource;
  end
end

--hs.hotkey.bind(mash, "b", showBatteryStatus)

function showWifiNetwork()
    SSID = hs.wifi.currentNetwork()
    if SSID == nil then
        SSID = "Disconnected"
    end
    hs.alert.show("*" .. SSID .. "*")
end

hs.hotkey.bind(mash, "w", showWifiNetwork)

function pingResult(object, message, seqnum, error)
    if message == "didFinish" then
        avg = tonumber(string.match(object:summary(), '/(%d+.%d+)/'))
        if avg == 0.0 then
            hs.alert.show("No network")
        elseif avg < 200.0 then
            hs.alert.show("Network good (" .. avg .. "ms)")
        elseif avg < 500.0 then
            hs.alert.show("Network poor(" .. avg .. "ms)")
        else
            hs.alert.show("Network bad(" .. avg .. "ms)")
        end
    end
end

function ping()
  hs.alert.show("Pinging ...")
  hs.network.ping.ping("google.com", 5, 1, 1.0, "any", pingResult)
end
hs.hotkey.bind(mash, "p", ping)

-- Show date time and battery
hs.hotkey.bind("alt", "T", function()
  local seconds = 3
  local message = os.date("%I:%M%p") .. "\n" .. os.date("%a %b %d") .. "\nBattery: " ..
     hs.battery.percentage() .. "%"
  hs.alert.show(message, seconds)
end)

--------------------------------
-- START VIM CONFIG
--------------------------------
--local VimMode = hs.loadSpoon("VimMode")
--local vim = VimMode:new()

---- Configure apps you do *not* want Vim mode enabled in
---- For example, you don't want this plugin overriding your control of Terminal
---- vim
--vim
  --:disableForApp('Code')
  --:disableForApp('zoom.us')
  --:disableForApp('iTerm')
  --:disableForApp('iTerm2')
  --:disableForApp('Terminal')

---- If you want the screen to dim (a la Flux) when you enter normal mode
---- flip this to true.
--vim:shouldDimScreenInNormalMode(false)

---- If you want to show an on-screen alert when you enter normal mode, set
---- this to true
--vim:shouldShowAlertInNormalMode(true)

---- You can configure your on-screen alert font
--vim:setAlertFont("Courier New")

---- Enter normal mode by typing a key sequence
--vim:enterWithSequence('jk')

---- if you want to bind a single key to entering vim, remove the
---- :enterWithSequence('jk') line above and uncomment the bindHotKeys line
---- below:
----
---- To customize the hot key you want, see the mods and key parameters at:
----   https://www.hammerspoon.org/docs/hs.hotkey.html#bind
----
---- vim:bindHotKeys({ enter = { {'ctrl'}, ';' } })

--------------------------------
-- END VIM CONFIG
--------------------------------

hs.alert.show("Hammerspoon started!")
