-- HideRepairPacks settings.lua
-- Configuration settings.


data:extend({
  -- Maximum distance to a "nearby" enemy.
  {
    type = "int-setting",
    name = "hide-repair-packs-nearby-enemy-radius",
    setting_type = "runtime-global",
    default_value = 80,
    minimum_value = 10,
    maximum_value = 300,
  },

  -- Whether to display an indicator when enemies are near.
  {
    type = "bool-setting",
    name = "hide-repair-packs-show-enemy-indicator",
    setting_type = "runtime-per-user",
    default_value = true,
  },

  -- Time between checks for nearby enemies.
  {
    type = "int-setting",
    name = "hide-repair-packs-enemy-check-period-ticks",
    setting_type = "runtime-global",
    default_value = 60,
    minimum_value = 1,
    maximum_value = 300,
  },

  -- Diagnostic log verbosity level.  See 'diagnostic_verbosity' in
  -- control.lua.
  {
    type = "int-setting",
    name = "hide-repair-packs-diagnostic-verbosity",
    setting_type = "runtime-global",
    default_value = 1,
    minimum_value = 0,
    maximum_value = 4,
  },
});


-- EOF
