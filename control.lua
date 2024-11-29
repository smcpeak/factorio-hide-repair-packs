-- HideRepairPacks control.lua
-- Actions that run while the user is playing the game.


-- --------------------------- Configuration ---------------------------
-- The variable values in this section are overwritten by configuration
-- settings during initialization and after re-reading updated
-- configuration values, but for ease of reference, the values here are
-- the same as the defaults in `settings.lua`.

-- How much to log, from among:
--   0: Nothing.
--   1: Only things that indicate a serious problem.  These suggest a
--      bug in this mod, but are recoverable.
--   2: Relatively infrequent things possibly of interest to the user,
--      particularly the moving of repair tools.
--   3: Details of the repair tool movements.
--   4: Individual algorithm steps only of interest to a developer.
local diagnostic_verbosity = 1;

-- Time between checks for nearby enemies.
local enemy_check_period_ticks = 60;

-- Maximum distance to a "nearby" enemy.
local nearby_enemy_radius = 80;


-- ------------------------------- Data --------------------------------
-- Map from player index to their current nearby-enemy state.  This is
-- populated as needed.  Its purpose is to optimize away unnecessary
-- updates.
local player_to_enemy_is_nearby = {};


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
  -- Note: Because the diagnostic verbosity is changed here, it is
  -- possible to see unpaired "begin" or "end" in the log.
  diag(4, "read_configuration_settings begin");

  diagnostic_verbosity =     settings.global["hide-repair-packs-diagnostic-verbosity"].value;
  enemy_check_period_ticks = settings.global["hide-repair-packs-enemy-check-period-ticks"].value;
  nearby_enemy_redius =      settings.global["hide-repair-packs-nearby-enemy-radius"].value;

  diag(4, "read_configuration_settings end");
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
      diag(4, "Adding indicator element.");
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
      diag(4, "Removing indicator element.");
      label.destroy();
    end;
  end;
end;


-- Move all of the repair packs that are in `src_inv` to `dest_inv`.
local function move_repair_packs(
  player,          -- LuaPlayer: Player whose inventory we are operating on.
  dest_inv,        -- LuaInventory: Destination inventory.
  dest_name,       -- string: Name of destination for diagnostics.
  src_inv,         -- LuaInventory: Source inventory.
  src_name)        -- string: Name of source for diagnostics.

  if (dest_inv == nil) then
    diag(4, "Missing " .. dest_name .. " inventory.");
    return;
  end;

  if (src_inv == nil) then
    diag(4, "Missing " .. src_name .. " inventory.");
    return;
  end;

  -- Total number of items moved.
  local total_move_count = 0;

  -- True if some attempted move could not be completed.
  local was_incomplete = false;

  -- Next candidate destination inventory slot.
  local dest_inv_slot_num = 1;

  -- Iterate over the source slots, examining the stacks therein.
  -- Operating at the slot granularity ensures we do not lose
  -- information about durability, freshness, etc., when moving items
  -- between inventories.
  for src_inv_slot_num = 1, #src_inv do
    -- Look for any repair tool, rather than just the repair-pack from
    -- the base game.
    local src_stack = src_inv[src_inv_slot_num];
    if (src_stack.count > 0 and
        prototypes.item[src_stack.name].type == "repair-tool") then
      local message =
        "Player " .. player.index ..
        ": " .. src_name ..
        " inventory slot " .. src_inv_slot_num ..
        " has " .. src_stack.count ..
        "x " .. src_stack.name ..
        ".";

      -- Look for an empty slot in the destination inventory.
      while (dest_inv_slot_num <= #dest_inv and
             dest_inv[dest_inv_slot_num].count > 0) do
        dest_inv_slot_num = dest_inv_slot_num + 1;
      end;

      if (dest_inv_slot_num <= #dest_inv) then
        -- Swap the stacks to effect a lossless, dup-less transfer.
        local dest_stack = dest_inv[dest_inv_slot_num];
        if (src_stack.swap_stack(dest_stack)) then
          diag(3, message ..
                  "  We swapped them with slot " .. dest_inv_slot_num ..
                  " of " .. dest_name .. " inventory.");
          total_move_count = total_move_count + dest_stack.count

        else
          diag(1, message ..
                  "  We failed to swap them with slot " .. dest_inv_slot_num ..
                  " of " .. dest_name .. " inventory.");
          was_incomplete = true;
          break;

        end;

      else
        diag(3, message ..
                "  However, there are no empty stacks in " .. dest_name ..
                " inventory.  (We stop examining more " .. src_name ..
                " stacks consequently.)");
        was_incomplete = true;
        break;

      end;
    end;
  end;

  if (total_move_count > 0 or was_incomplete) then
    local inc_message = "";
    if (was_incomplete) then
      inc_message = "  However, some tools could not be moved.";
      if (diagnostic_verbosity < 3) then
        inc_message = inc_message ..
                      "  Increase the logging verbosity to 3 to see details.";
      end;
    end;

    diag(2, "Player " .. player.index ..
            ": Moved " .. total_move_count ..
            " repair tools from " .. src_name ..
            " to " .. dest_name ..
            " inventory." .. inc_message);
  end;
end;


-- Check for enemies near one player.
local function check_player(player)
  local character = player.valid and player.character
  if (character and character.valid) then
    -- Is an enemy nearby?
    local enemy_is_nearby = false;
    if (settings.get_player_settings(player.index)["hide-repair-packs-enable-mod"].value) then
      local enemy = character.surface.find_nearest_enemy{
        position = character.position,
        max_distance = nearby_enemy_redius,
        force = character.force,
      };
      enemy_is_nearby = (enemy ~= nil);
    else
      -- When the mod is "disabled" for a player, behave as though there
      -- are never enemies nearby.  (In contrast, simply returning at
      -- the top of this function leads to bugs where the status display
      -- remains if it was active at the time the mod was disabled.)
    end;

    -- Is this different from the last time we checked?
    local previous = player_to_enemy_is_nearby[player.index];
    if (previous == enemy_is_nearby) then
      -- No need to update anything.

    else
      diag(4, "enemy_is_nearby is different");
      set_status_label(player, enemy_is_nearby);

      main_inv = character.get_main_inventory();
      trash_inv = character.get_inventory(defines.inventory.character_trash);

      if (enemy_is_nearby) then
        move_repair_packs(player, trash_inv, "trash", main_inv, "main");
      else
        move_repair_packs(player, main_inv, "main", trash_inv, "trash");
      end;

      player_to_enemy_is_nearby[player.index] = enemy_is_nearby;
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
