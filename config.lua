-- This is the config lua module.
-- This will contain all of the parameters set by the user.

-- Parameters
local modem_location = "right";
local user_chest = "minecraft:chest_14";

local config = {};

function config.getModemLocation()
  return modem_location;
end

function config.getUserChest()
  return user_chest;
end

return config;
