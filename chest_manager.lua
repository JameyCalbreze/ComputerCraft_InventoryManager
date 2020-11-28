-- This is the chest manager module

-- Import modules
local config = require("config");
local stack = require("stack");

-- Init this module
local chest_manager = {};

-- Static strings and variables
local user_chest_string = config.getUserChest();
local user_chest = peripheral.wrap(user_chest_string);
local modem = peripheral.wrap(config.getModemLocation());

-- Private attributes
local chests = {};
local total_slots = 0;
local free_slot_stack = stack.newStack(); -- Each of these items holds { name of the chest, slot number }
local item_stack_map = {}; -- Item name -> stack({ name of the chest, slot number })
local item_count_map = {};

-- Register a chest into the system
function chest_manager.register(chest)
  local chest_name = peripheral.getName(chest);
  print(string.format("Processing %s", chest_name));
  if chest_name == user_chest_string then return end
  
  local size_of_chest = chest.size();
  local i;
  for i = 1, size_of_chest, 1 do
    local current_item = chest.getItemMeta(i); -- Get information about each item
    if current_item == nil then
      stack.push(free_slot_stack, { chest_name, i });
    else
      registerItemIntoMap(chest_name, i, current_item);
    end
    total_slots = total_slots + 1;
  end
  chests[chest_name] = chest;
end

function chest_manager.getFreeSlots()
  return stack.size(free_slot_stack);
end

function chest_manager.getTotalSlots()
  return total_slots;
end

function chest_manager.insert(user_chest_slot)
  -- Step 1 check to see what item we have
  local item_meta = user_chest.getItemMeta(user_chest_slot);
  if item_meta == nil then return end
  local item_name = item_meta["displayName"];

  -- The item isn't nil so now we can insert it into the chest
  local location_to_insert = stack.pop(free_slot_stack);

  -- This operation can fail it seems
  -- If the number moved isn't zero we'll mark the slot as used
  local count_moved = user_chest.pushItems(location_to_insert[1], user_chest_slot, 64, location_to_insert[2]);
  print(string.format("Inserted %d of %s", count_moved, item_name));

  if count_moved ~= 0 then
    -- Register that the item has moved
    if item_stack_map[item_name] == nil then
      initItem(item_name);
    end
    stack.push(item_stack_map[item_name], location_to_insert); -- mark the free slot as used by the item
    item_count_map[item_name] = item_count_map[item_name] + item_meta["count"]; -- increment count;
  else
    stack.push(free_slot_stack, location_to_insert); -- If the operation fails put the free location back into the stack
  end
end

function chest_manager.getItemNames()
  local item_names = stack.newStack();
  for item_name, item_stack in pairs(item_stack_map) do
    stack.push(item_names, item_name);
  end
  return item_names;
end

function chest_manager.contains(item_name)
  local item_stack = item_stack_map[item_name];
  if item_stack == nil then
    return false;
  elseif stack.size(item_stack) == 0 then
    return false;
  else
    return true;
  end
end

function chest_manager.countItem(item_name)
  if item_count_map[item_name] == nil then
    return 0;
  else
    return item_count_map[item_name];
  end
end

function chest_manager.getItem(item_name, count)
  local num_fetched = 0;
  local current_slot = getNextFreeUserChestSlot(1);
  local item_stack = item_stack_map[item_name];

  while (num_fetched ~= count) and (current_slot <= user_chest.size()) do
    local item_location = stack.pop(item_stack); -- Pop item location out of item_stack
    local chest = chests[item_location[1]]; -- Get the chest object
    local num_in_slot = chest.getItemMeta(item_location[2])["count"];
    local remaining = count - num_fetched;
    if remaining >= num_in_slot then
      chest.pushItems(user_chest_string, item_location[2], num_in_slot, current_slot); -- Move all of slot
      print(string.format("Got %d of %s", num_in_slot, item_name));
      stack.push(free_slot_stack, item_location); -- Mark slot free
      num_fetched = num_fetched + num_in_slot; -- increment num_fetched
    else
      chest.pushItems(user_chest_string, item_location[2], remaining, current_slot); -- Move partial
      print(string.format("Got %d of %s", remaining, item_name));
      stack.push(item_stack, item_location); -- Push slot back onto item stack
      num_fetched = count; -- This is logically deducible
    end
    current_slot = getNextFreeUserChestSlot(current_slot);
  end

  item_count_map[item_name] = item_count_map[item_name] - num_fetched; -- decrement count of item in inventory
end

function chest_manager.defrag()
  for item_name, item_stack in pairs(item_stack_map) do
    if stack.size(item_stack) > 1 then
      local item_max_count = chests[item_stack[1][1]].getItemMeta(item_stack[1][2])["maxCount"] -- First entry in the stack, chest name, get max count of item
      local index = 1;
      while index < stack.size(item_stack) do
        local fill_location = item_stack[index];
        local drain_location = item_stack[stack.size(item_stack)];
        chests[drain_location[1]].pushItems(fill_location[1], drain_location[2], item_max_count, fill_location[2]);
        if chests[drain_location[1]].getItemMeta(drain_location[2]) == nil then
          local location_freed = stack.pop(item_stack);
          stack.push(free_slot_stack, location_freed);
        end
        index = index + 1;
      end
    end 
  end
end

-- private methods
function initItem(item_name)
  item_stack_map[item_name] = stack.newStack();
  item_count_map[item_name] = 0;
end

function registerItemIntoMap(chest_name, slot, item)
  local item_name = item["displayName"];

  if item_stack_map[item_name] == nil then
    initItem(item_name);
  end

  stack.push(item_stack_map[item_name], { chest_name, slot });
  item_count_map[item_name] = item_count_map[item_name] + item["count"];
end

function getNextFreeUserChestSlot(current_slot)
  local max_num = user_chest.size();
  while current_slot <= max_num do
    if user_chest.getItemMeta(current_slot) == nil then
      return current_slot;
    end
    current_slot = current_slot + 1;
  end
  return current_slot;
end

-- Init Logic
function init()
  local chests = {peripheral.find("minecraft:chest")};
  local num_chests = #chests;
  for i, chest in ipairs(chests) do
    io.stdout:write(string.format("%d,%d ", i, num_chests));
    chest_manager.register(chest);
  end
end

init();

return chest_manager;
