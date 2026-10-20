# Hammerspoon Configuration Instructions

This is a Hammerspoon configuration repository for macOS automation using Lua.

## Project Structure

- **`init.lua`**: Main entry point that loads configuration and initializes Spoons
- **`Spoons/`**: Directory containing Spoon modules (Hammerspoon plugins)
  - Each `.spoon` is a package directory with its own `init.lua`
  - Built-in Spoons: AClock, BingDaily, CircleClock, ClipShow, CountDown, HCalendar, HSaria2, HSearch, KSheet, ModalMgr, SpeedMenu, WinWin, FnMate, etc.
- **`private/config.lua`**: User configuration file (gitignored, created from `config-example.lua`)
- **`modes/`**: Additional mode configurations (battery, music)
- **`hs/`**: Helper modules

## Architecture

### Modal Environment System

The configuration is built around **ModalMgr.spoon**, which provides a modal-based keybinding system (similar to vim modes):

1. **Modal Supervisor**: Central controller (`spoon.ModalMgr.supervisor`) that manages all modal environments
2. **Modal Environments**: Separate keybinding contexts (e.g., `appM`, `resizeM`, `clipshowM`)
3. **Activation Flow**: 
   - Press hotkey (e.g., `alt+R`) → Enter modal environment → Modal-specific keys active
   - Press `escape` or `Q` → Exit modal → Return to supervisor

### Configuration Loading Priority

1. Check `~/.config/hammerspoon/private/config.lua` (XDG-style)
2. Fallback to `~/.hammerspoon/private/config.lua` (classic location)
3. If neither exists, use defaults from `init.lua`

### Key Configuration Variables

All configurable variables in `private/config.lua`:

- **`hspoon_list`**: Table of Spoon names to load (defines which features are enabled)
- **`hsapp_list`**: Application launcher mappings (`{key = 'f', name = 'Finder'}`)
- **Keybinding variables**: Pattern `hs<feature>_keys = {"modifier", "key"}`
  - Set to `{"", ""}` or `{{}, ""}` to disable a keybinding
- **`hsaria2_host` / `hsaria2_secret`**: aria2 RPC configuration

## Spoon Development

### Spoon Structure

Each Spoon is a directory ending in `.spoon/`:
```
SpoonName.spoon/
├── init.lua        # Main module file (required)
└── docs.json       # API documentation (optional)
```

### Spoon Template

```lua
local obj = {}
obj.__index = obj

-- Metadata
obj.name = "SpoonName"
obj.version = "1.0"
obj.author = "author <email>"
obj.homepage = "https://github.com/..."
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Configuration variables
obj.configVar = defaultValue

-- Public methods
function obj:methodName()
    -- implementation
end

return obj
```

### Loading Spoons

Spoons are loaded via:
1. Add to `hspoon_list` in `private/config.lua`
2. `hs.loadSpoon("SpoonName")` in `init.lua`
3. Access via `spoon.SpoonName`

## Key Conventions

### Modal Environment Pattern

When creating modal environments:

1. Create new modal: `spoon.ModalMgr:new("modalName")`
2. Get modal reference: `local cmodal = spoon.ModalMgr.modal_list["modalName"]`
3. Bind keys: `cmodal:bind(modifier, key, description, pressedFn, releasedFn, repeatFn)`
4. Always bind `escape` and `Q` to deactivate
5. Optionally bind `tab` to toggle cheatsheet
6. Register with supervisor using `hsfeature_keys` variable pattern

### Keybinding Registration

Two types of keybindings:

1. **Modal-specific**: Inside modal environment (no modifier needed)
   ```lua
   cmodal:bind('', 'H', 'Lefthalf of Screen', function() ... end)
   ```

2. **Global/Supervisor**: Registered with modal supervisor
   ```lua
   spoon.ModalMgr.supervisor:bind({"alt"}, "R", "Enter resizeM", function() ... end)
   ```

### Variable Naming Pattern

Configuration variables follow strict naming:
- `hs<feature>_<type>` format (e.g., `hsreload_keys`, `hsaria2_host`)
- Keys variables: `hs<modal>M_keys` for modal environments
- Check if configured: `hsvar = hsvar or defaultValue`

### Conditional Spoon Loading

Always check Spoon existence before use:
```lua
if spoon.SpoonName then
    -- configure and use Spoon
end
```

## Reloading Configuration

- **Keybinding**: `cmd+shift+ctrl+R` (default, configured via `hsreload_keys`)
- **Programmatic**: `hs.reload()`
- **Console**: `alt+Z` to toggle Hammerspoon console

## Performance Settings

Animation and alert durations are set to 0 for instant response:
```lua
hs.hotkey.alertDuration = 0
hs.hints.showTitleThresh = 0
hs.window.animationDuration = 0
```

## Common Modifier Keys

- **`alt`**: Primary modifier for most features (⌥)
- **`cmd`**: Command key (⌘)
- **`ctrl`**: Control key
- **`shift`**: Shift key
- Modifiers as table: `{"cmd", "shift", "ctrl"}`

## Helpful Resources

- [Hammerspoon API Docs](http://www.hammerspoon.org/docs/)
- [Learn Lua in Y minutes](http://learnxinyminutes.com/docs/lua/)
- [Spoon Development Guide](https://github.com/Hammerspoon/hammerspoon/blob/master/SPOONS.md)
