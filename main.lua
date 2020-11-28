-- This will be the entry point into the program

-- Import modules
local config = require("config");
local chest_manager = require("chest_manager");
local stack = require("stack");

local user_chest = peripheral.wrap(config.getUserChest());

function isValidChest(chest_name)
  if     chest_name == "minecraft:chest"             then return true
  elseif chest_name == "minecraft:ironchest_crystal" then return true
  else return false end
end

function handleInsert()
  local max_input = user_chest.size();
  print("Enter a slot to insert from.");
  print(string.format("1 - %d, all, or cancel", max_input));
  io.stdout:write("> ");
  local input = io.stdin:read();
  local input_number = tonumber(input);

  if input == "all" then
    local i = 1;
    for i = 1,max_input,1 do
      chest_manager.insert(i);
    end
  elseif input == "cancel" then
    return
  elseif input_number ~= nil then
    chest_manager.insert(input_number);
  else
    print("invalid input, returning to menu");
  end
end

function handleHelp()
  print("insert    -- Insert items into storage");
  print("help      -- Get help");
  print("freespace -- Get slots remaining");
end

function handleGetFreeSlots()
  print(string.format("Free Slots: %d", chest_manager.getFreeSlots()));
  print(string.format("Total Slots: %d", chest_manager.getTotalSlots()));
end

local selection = nil;

function handleList()
  local item_names = chest_manager.getItemNames();
  local num_items = stack.size(item_names);
  table.sort(item_names);
  print(string.format("There are %d items", num_items))
  for i, item_name in ipairs(item_names) do
    local item_count = chest_manager.countItem(item_name);
    if item_count > 0 then
      print(string.format("%s - %d", item_name, item_count));
      io.stdout:write("> ");
      local input = io.stdin:read();
      if input == "select" then
        selection = item_name;
        handleGetItem();
        break
      elseif input == "getitem" then
        handleGetItem();
        break
      end
    end
  end
end

function handleGetItem()
  local item_name;
  if selection == nil then
    io.stdout:write("Enter Item Name\n> ");
    item_name = io.stdin:read();
  else
    item_name = selection;
    selection = nil;
  end

  if chest_manager.contains(item_name) == false then
    print(string.format("Item %s not in inventory", item_name));
    return
  end

  local num_of_item = chest_manager.countItem(item_name);
  local num_to_fetch = nil;
  while num_to_fetch == nil do
    io.stdout:write(string.format("Enter 0 - %d, 0 is cancel\n> ", num_of_item));
    num_to_fetch = tonumber(io.stdin:read());
  end
  
  if num_to_fetch == 0 then return end
  chest_manager.getItem(item_name, num_to_fetch);
end

local active = true;
while active do
  io.stdout:write("> ");
  local command = io.stdin:read();
  -- print(string.format("You typed: %s", command))

  -- Commands to parse in the future
  if command == "quit" then 
    active = false;
  elseif command == "insert" then
    handleInsert();
  elseif command == "help" then
    handleHelp();
  elseif command == "freespace" then
    handleGetFreeSlots();
  elseif command == "list" then
    handleList();
  elseif command == "getitem" then
    handleGetItem();
  elseif command == "defrag" then
    chest_manager.defrag();
  end
end
