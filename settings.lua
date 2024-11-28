-- HideRepairPacks settings.lua
-- Configuration settings.


data:extend({
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

  -- Time between checks for nearby enemies.
  {
    type = "int-setting",
    name = "hide-repair-packs-enemy-check-period-ticks",
    setting_type = "runtime-global",
    default_value = 60,
    minimum_value = 1,
    maximum_value = 300,
  },
});


-- EOF
