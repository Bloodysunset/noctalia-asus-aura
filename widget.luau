--!nonstrict
-- Bar widget: keyboard glyph. Click opens the panel, right-click reapplies
-- the current effect. A jump in wall-clock time between ticks means the
-- machine was asleep, so the effect is reapplied once the keyboard is back.

local aura = require("./aura.luau")

local TICK_MS = 5000
local SLEEP_GAP_SECONDS = 20
local RESUME_DELAY_SECONDS = 3

local lastTick = os.time()

function update()
  noctalia.setUpdateInterval(TICK_MS)
  barWidget.setGlyph("keyboard")

  local state = aura.read()
  if state and state.current then
    barWidget.setTooltip("Keyboard: " .. aura.label(state.current))
  end

  local now = os.time()
  if now - lastTick > SLEEP_GAP_SECONDS then
    aura.reapply(RESUME_DELAY_SECONDS)
  end
  lastTick = now
end

function onClick()
  noctalia.togglePanel("bloodysunset/asus_aura:panel")
end

function onRightClick()
  aura.reapply()
end
