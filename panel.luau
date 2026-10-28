--!nonstrict
-- Panel: pick effect, speed, direction and colours. Every change is applied
-- immediately; "Reapply" re-sends the current effect to relight the keyboard.

local aura = require("./aura.luau")

local state = nil
local errorText = nil
local mode = nil
local settings = nil

local function indexOf(list, value)
  for i, v in ipairs(list) do
    if v == value then
      return i - 1
    end
  end
  return 0
end

local function labels(list)
  local out = {}
  for i, v in ipairs(list) do
    out[i] = aura.label(v)
  end
  return out
end

local function section(title, control)
  return ui.column({ gap = 6 }, {
    ui.label({ text = title, fontWeight = "medium", color = "on_surface_variant" }),
    control,
  })
end

local function colourRow(field)
  return ui.row({ gap = 10, align = "center" }, {
    ui.box({ width = 28, height = 28, radius = 6, fill = settings[field], border = "outline_variant", borderWidth = 1 }),
    ui.label({ text = settings[field], color = "on_surface", flexGrow = 1 }),
    ui.button({
      text = "Pick",
      controlSize = "sm",
      onClick = function()
        noctalia.openColorPicker(settings[field], function(colour)
          if colour then
            settings[field] = colour:sub(1, 7):lower()
            aura.apply(mode, settings)
            render()
          end
        end)
      end,
    }),
  })
end

function render()
  if not state then
    panel.render(ui.column({ gap = 8, padding = 16 }, {
      ui.label({ text = "ASUS Aura", fontSize = 16, fontWeight = "bold", color = "primary" }),
      ui.label({ text = errorText or "Unavailable", color = "error", maxWidth = 268 }),
    }))
    return
  end

  local spec = aura.MODES[mode]
  local children = {
    ui.label({ text = "Keyboard Lighting", fontSize = 16, fontWeight = "bold", color = "primary" }),
    section("Effect", ui.select({
      options = labels(state.modes),
      selectedIndex = indexOf(state.modes, mode),
      onChange = function(index)
        mode = state.modes[(tonumber(index) or 0) + 1]
        settings = state.settings[mode]
        aura.apply(mode, settings)
        render()
      end,
    })),
  }

  if spec.speed then
    table.insert(children, section("Speed", ui.select({
      options = aura.SPEEDS,
      selectedIndex = indexOf(aura.SPEEDS, settings.speed),
      onChange = function(index)
        settings.speed = aura.SPEEDS[(tonumber(index) or 0) + 1]
        aura.apply(mode, settings)
        render()
      end,
    })))
  end

  if spec.direction then
    table.insert(children, section("Direction", ui.select({
      options = aura.DIRECTIONS,
      selectedIndex = indexOf(aura.DIRECTIONS, settings.direction),
      onChange = function(index)
        settings.direction = aura.DIRECTIONS[(tonumber(index) or 0) + 1]
        aura.apply(mode, settings)
        render()
      end,
    })))
  end

  if spec.colour then
    table.insert(children, section(spec.colour2 and "Colour 1" or "Colour", colourRow("colour1")))
  end
  if spec.colour2 then
    table.insert(children, section("Colour 2", colourRow("colour2")))
  end

  table.insert(children, ui.row({ justify = "end" }, {
    ui.button({
      text = "Reapply",
      glyph = "refresh",
      variant = "primary",
      tooltip = "Re-send the effect to relight the keyboard",
      onClick = function()
        aura.apply(mode, settings)
      end,
    }),
  }))

  panel.render(ui.column({ gap = 12, padding = 16 }, children))
end

function onOpen(_context)
  local err
  state, err = aura.read()
  errorText = err
  if state then
    mode = state.settings[state.current] and state.current or state.modes[1]
    settings = mode and state.settings[mode]
    if not mode then
      state = nil
      errorText = "asusd reports no supported effects"
    end
  end
  render()
end
