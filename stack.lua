-- This is the Stack lua module to treat tables as if they are stacks

local stack = {};

function stack.newStack()
  local new_stack = {};
  new_stack["__size__"] = 0;
  return new_stack;
end

function stack.size(s)
  return s["__size__"];
end

function stack.push(s, item)
  local size = s["__size__"] + 1;
  s["__size__"] = size;
  s[size] = item;
end

function stack.pop(s)
  local size = s["__size__"];
  if size == 0 then return end
  local ret = s[size];
  s[size] = nil;
  s["__size__"] = size - 1;
  return ret;
end

return stack;
