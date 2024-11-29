-- HideRepairPacks control.lua
-- Actions that run while the user is playing the game.


-- --------------------------- Configuration ---------------------------
-- The variable values in this section are overwritten by
-- configuration settings during initialization, but the values here are
-- the same as the defaults in `settings.lua`.

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

-- Time between checks for nearby enemies.
local enemy_check_period_ticks = 60;

-- Maximum distance to a "nearby" enemy.
local nearby_enemy_radius = 80;



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
  diag(3, "read_configuration_settings begin");

  diagnostic_verbosity =     settings.global["hide-repair-packs-diagnostic-verbosity"].value;
  enemy_check_period_ticks = settings.global["hide-repair-packs-enemy-check-period-ticks"].value;
  nearby_enemy_redius =      settings.global["hide-repair-packs-nearby-enemy-radius"].value;

  diag(3, "read_configuration_settings end");
end;


-- Update the status label.
local function set_status_label(
  player,          -- LuaPlayer: Player whose GUI we want to update.
  enemy_is_nearby) -- boolean: True if enemies present.

  local label_name = "hide-repair-packs-status";
  gui_element = player.gui.top;
  local label = gui_element[label_name];

  if (settings.get_player_settings(player.index)["hide-repair-packs-show-enemy-indicator"].value) then
    if (label == nil) then
      -- This creates a simple text label in the top-left corner.
      diag(2, "Adding indicator element.");
      label = gui_element.add{
        type = "label",
        name = label_name,
        caption = ""};
    end;

    if (enemy_is_nearby) then
      label.caption = "HideRepairPacks: Enemies near, repair packs stashed.";
    else
      -- Assumption: An empty label will reserve the space, whereas
      -- removing it entirely would cause other elements to jump around
      -- when the label is later re-added.
      label.caption = "";
    end;

  else
    if (label ~= nil) then
      -- Remove the indicator.
      diag(2, "Removing indicator.");
      label.destroy();
    end;
  end;
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
    diag(4, "Missing " .. dest_name .. " inventory.");
    return;
  end;

  if (src_inv == nil) then
    diag(4, "Missing " .. src_name .. " inventory.");
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
      diag(4, "Failed to add repair packs to " .. dest_name .. ".");
    end;
  end;
end;


-- Check for enemies near one player.
local function check_player(player)
  local character = player.valid and player.character
  if (character and character.valid) then
    local enemy = character.surface.find_nearest_enemy{
      position = character.position,
      max_distance = nearby_enemy_redius,
      force = character.force,
    };
    local enemy_is_nearby = (enemy ~= nil);
    set_status_label(player, enemy_is_nearby);

    main_inv = character.get_main_inventory();
    trash_inv = character.get_inventory(defines.inventory.character_trash);

    if (enemy_is_nearby) then
      move_repair_packs(player, trash_inv, "trash", main_inv, "main");
    else
      move_repair_packs(player, main_inv, "main", trash_inv, "trash");
    end;
  end;
end;


-- Check for enemies near all players.
local function check_all_players()
  for index, player in pairs(game.players) do
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
