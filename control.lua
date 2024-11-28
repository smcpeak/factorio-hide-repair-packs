-- HideRepairPacks control.lua
-- Actions that run while the user is playing the game.


-- --------------------------- Configuration ---------------------------
-- The variable values in this section are overwritten by
-- configuration settings during initialization.

-- How much to log, from among:
--   0: Nothing.
--   1: Only things that indicate a serious problem.  These suggest a
--      bug in the RoboTank mod, but are recoverable.
--   2: Relatively infrequent things possibly of interest to the user,
--      such as changes to the formation of tanks, tanks complaining
--      about being stuck, loading ammo, etc.
--   3: Changes to internal data structures.
--   4: Details of algorithms.
local diagnostic_verbosity = 1;

-- Ticks between nearby enemy checks.
local enemy_check_period_ticks = 60;


-- ----------------------------- Functions -----------------------------
-- Log 'str' if we are at verbosity 'v' or higher.
local function diag(v, str)
  if (v <= diagnostic_verbosity) then
    log(str);
  end;
end;


-- Re-read the configuration settings.
--
-- Below, this is done once on startup, then afterward in response to
-- the on_runtime_mod_setting_changed event.
local function read_configuration_settings()
  diag(3, "read_configuration_settings started");
  enemy_check_period_ticks = settings.global["hide-repair-packs-enemy-check-period-ticks"].value;
  diagnostic_verbosity = settings.global["hide-repair-packs-diagnostic-verbosity"].value;
  diag(3, "read_configuration_settings finished");
end;


-- Get or create the status label.
local function get_status_label(player)
  gui_element = player.gui.top;
  local label = gui_element["hrp_status"];
  if (label == nil) then
    -- This creates a simple text label in the top-left corner.
    label = gui_element.add{type="label", name="hrp_status", caption=""}
  end;
  return label;
end;


-- Move all of the repair packs that are in `src_inv` to `dest_inv`.
local function move_repair_packs(
  player,          -- LuaPlayer: Player whose inventory we are operating on.
  dest_inv,        -- LuaInventory: Destination.
  dest_name,       -- string: Name of destination for diagnostics.
  src_inv,         -- LuaInventory: Source.
  src_name)        -- string: Name of source for diagnostics.

  local item_name = "repair-pack";

  if (dest_inv == nil) then
    diag(4, "    Missing " .. dest_name .. " inventory.");
    return;
  end;

  if (src_inv == nil) then
    diag(4, "    Missing " .. src_name .. " inventory.");
    return;
  end;

  local ct = src_inv.get_item_count(item_name);
  if (ct > 0) then
    local num_inserted = dest_inv.insert(
      {name=item_name, count=ct});
    if (num_inserted > 0) then
      local num_removed = src_inv.remove(
        {name=item_name, count=num_inserted});

      diag(2, "Player " .. player.index ..
              " (" .. player.name ..
              ") has " .. ct ..
              " repair packs in " .. src_name ..
              " inventory.  Added " .. num_inserted ..
              " packs to " .. dest_name ..
              ", removed " .. num_removed ..
              " packs from " .. src_name .. ".");

      if (num_removed ~= num_inserted) then
        diag(1, "Bug: We duplicated items!");
      end;
    else
      diag(4, "    Failed to add repair packs to " .. dest_name .. ".");
    end;
  else
    diag(4, "    No repair packs in " .. src_name .. " inventory.");
  end;
end;


-- Check for enemies near one player.
local function check_player(player)
  local character = player.valid and player.character
  if (character and character.valid) then
    diag(4, "    x: " .. character.position.x);
    diag(4, "    y: " .. character.position.y);
    diag(4, "    surface: " .. character.surface.name);

    local label = get_status_label(player);

    local enemy_is_nearby = false;
    enemy = character.surface.find_nearest_enemy{
      position = character.position,
      max_distance = 100,
      force = character.force,
    };
    if (enemy ~= nil) then
      enemy_is_nearby = true;
      label.caption =
        "HideRepairPacks: Enemies nearby, repair packs hidden (in trash).";
    else
      label.caption = "";
    end;

    main_inv = character.get_main_inventory();
    trash_inv = character.get_inventory(defines.inventory.character_trash);

    if (enemy_is_nearby) then
      move_repair_packs(player, trash_inv, "trash", main_inv, "main");
    else
      move_repair_packs(player, main_inv, "main", trash_inv, "trash");
    end;

  else
    diag(4, "    No character.");
  end;
end;


-- Check for enemies near all players.
local function check_all_players()
  diag(4, "Checking all players for nearby enemies.");
  for index, player in pairs(game.players) do
    diag(4, "  Player " .. index .. " exists.")
    check_player(player);
  end;
end;


-- -------------------------- Event handlers ---------------------------
script.on_event(defines.events.on_tick, function(e)
  -- Possibly check for nearby enemies.
  if ((e.tick % enemy_check_period_ticks) == 0) then
    check_all_players()
  end;
end);


script.on_event(defines.events.on_runtime_mod_setting_changed,
  read_configuration_settings);


-- -------------------------- Initialization ---------------------------
read_configuration_settings();


-- EOF
