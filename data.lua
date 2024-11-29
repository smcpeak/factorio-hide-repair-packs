-- HideRepairPacks data.lua
-- Define startup prototypes.


-- Indicator that appears when repair packs are hidden.
--
-- It is the same image as the thumbnail image for the mod, but scaled
-- down just a bit from 64x64, which I thought was obnoxiously large
-- onscreen, to 48x48.  I also tried 32x32 but that seemed too small.
--
local indicator_sprite = {
  type = "sprite",
  name = "hide-repair-packs-no-repair-indicator",
  filename = "__HideRepairPacks__/graphics/sprites/indicator.png",
  width = 48,
  height = 48,
};


data:extend{
  indicator_sprite,
};


-- EOF
