-- HideRepairPacks data.lua
-- Define startup prototypes.


-- Indicator that appears when repair packs are hidden.
local indicator_sprite = {
  type = "sprite",
  name = "hide-repair-packs-no-repair-indicator",
  filename = "__HideRepairPacks__/thumbnail.png",
  width = 64,
  height = 64,
};

data:extend{
  indicator_sprite,
};


-- EOF
