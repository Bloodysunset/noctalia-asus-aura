--!nonstrict
-- Shared asusd/asusctl helpers for the widget and the panel.
--
-- State is read from asusd's own config (/etc/asusd/aura_<pid>.ron), which
-- asusd rewrites whenever an effect is applied, so it is always current.

local M = {}

-- asusd mode name -> asusctl subcommand and the arguments it needs.
-- `colour` is the flag asusctl expects for the first colour (it varies by effect).
M.MODES = {
  Static       = { cli = "static",        colour = "-c" },
  Breathe      = { cli = "breathe",       colour = "--colour", colour2 = true, speed = true },
  RainbowCycle = { cli = "rainbow-cycle", speed = true },
  RainbowWave  = { cli = "rainbow-wave",  speed = true, direction = true },
  Star         = { cli = "stars",         colour = "--colour", colour2 = true, speed = true },
  Rain         = { cli = "rain",          speed = true },
  Highlight    = { cli = "highlight",     colour = "-c", speed = true },
  Laser        = { cli = "laser",         colour = "-c", speed = true },
  Ripple       = { cli = "ripple",        colour = "-c", speed = true },
  Pulse        = { cli = "pulse",         colour = "-c" },
  Comet        = { cli = "comet",         colour = "-c" },
  Flash        = { cli = "flash",         colour = "-c" },
}

M.SPEEDS = { "Low", "Med", "High" }
M.DIRECTIONS = { "Left", "Right", "Up", "Down" }

-- "RainbowWave" -> "Rainbow Wave"
function M.label(mode)
  return (mode:gsub("(%l)(%u)", "%1 %2"))
end

local function configPath()
  local entries = noctalia.listDir("/etc/asusd")
  for _, name in ipairs(entries or {}) do
    if name:match("^aura_.*%.ron$") then
      return "/etc/asusd/" .. name
    end
  end
  return nil
end

local function parseColour(block, field)
  local r, g, b = block:match(field .. ":%s*%(%s*r:%s*(%d+),%s*g:%s*(%d+),%s*b:%s*(%d+)")
  if not r then
    return "#ffffff"
  end
  return string.format("#%02x%02x%02x", tonumber(r), tonumber(g), tonumber(b))
end

-- Returns { current = "RainbowWave", modes = { "Static", ... }, settings = { [mode] = {...} } }
-- or nil, err.
function M.read()
  local path = configPath()
  if not path then
    return nil, "no /etc/asusd/aura_*.ron found (is asusd running?)"
  end
  local text, err = noctalia.readFile(path)
  if not text then
    return nil, err
  end

  local state = { current = text:match("current_mode:%s*(%w+)"), modes = {}, settings = {} }
  local builtins = text:match("builtins:%s*(%b{})") or ""

  -- Each builtin is "Name: ( ... )" at the top level of the builtins map.
  for name, block in builtins:gmatch("(%u%w*):%s*(%b())") do
    if M.MODES[name] then
      table.insert(state.modes, name)
      state.settings[name] = {
        speed = block:match("speed:%s*(%w+)") or "Med",
        direction = block:match("direction:%s*(%w+)") or "Right",
        colour1 = parseColour(block, "colour1"),
        colour2 = parseColour(block, "colour2"),
      }
    end
  end
  return state
end

function M.argv(mode, s)
  local spec = M.MODES[mode]
  local argv = { "asusctl", "aura", "effect", spec.cli }
  local function add(flag, value)
    table.insert(argv, flag)
    table.insert(argv, value)
  end
  if spec.colour then add(spec.colour, (s.colour1:gsub("^#", ""))) end
  if spec.colour2 then add("--colour2", (s.colour2:gsub("^#", ""))) end
  if spec.speed then add("--speed", s.speed:lower()) end
  if spec.direction then add("--direction", s.direction:lower()) end
  return argv
end

function M.apply(mode, s, delaySeconds)
  local argv = M.argv(mode, s)
  if delaySeconds and delaySeconds > 0 then
    -- All values come from fixed lists or hex digits, so plain joining is safe.
    argv = { "sh", "-c", "sleep " .. delaySeconds .. "; " .. table.concat(argv, " ") }
  end
  noctalia.runAsync(argv, function(result)
    if result.exitCode ~= 0 then
      noctalia.notifyError("ASUS Aura", result.stderr ~= "" and result.stderr or result.stdout)
    end
  end, 15000)
end

-- Re-send whatever asusd currently has saved; wakes an unlit keyboard.
function M.reapply(delaySeconds)
  local state, err = M.read()
  if not state or not state.current or not state.settings[state.current] then
    noctalia.notifyError("ASUS Aura", err or "could not read the current effect")
    return
  end
  M.apply(state.current, state.settings[state.current], delaySeconds)
end

return M
