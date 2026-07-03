--- binstack.lua
--- Simple module providing a stack structure.
--- Works with CC: Tweaked (Lua 5.2 + bit32).
--- @module binstack
---@alias Byte integer  -- expected range: 0-255

---@alias SeekWhence "set"|"cur"|"end"

---@class BinStack
---@field push fun(byte: Byte)
---@field peek fun(): Byte|nil
---@field poll fun(): Byte|nil
---@field read fun(n: integer): string
---@field size fun(): integer
---@field isEmpty fun(): boolean
---@field replaceData fun(newData: Byte[])
---@field seek fun(whence: SeekWhence, offset: integer)

local BinStack = {}

---@return BinStack
function BinStack.new()
  --- Private state (captured by closures)
  ---@type Byte[]
  local data = {}

  local top = 0
  local initial_top = 0

  local function checkByte(byte)
    assert(type(byte) == "number", "byte must be a number")
    assert(byte >= 0 and byte <= 255 and byte % 1 == 0,
      "byte must be integer 0-255")
  end

  ---@type BinStack
  ---@diagnostic disable-next-line: missing-fields
  local obj = {}

  ---@param newData Byte[]
  function obj.replaceData(newData)
    data = newData
    top = # newData
    initial_top = top
  end

  ---@param byte Byte
  function obj.push(byte)
    checkByte(byte)

    top = top + 1
    data[top] = byte
  end

  ---@return Byte|nil
  function obj.peek()
    if top == 0 then
      return nil
    end
    return data[top]
  end

  ---@return Byte|nil
  function obj.poll()
    if top == 0 then
      return nil
    end

    local b = data[top]
    data[top] = nil
    top = top - 1
    return b
  end

  ---@param whence SeekWhence
  ---@param offset integer
  function obj.seek(whence, offset)
    if whence == "set" then
      top = initial_top - offset
    elseif whence == "cur" then
      top = top - offset
    elseif whence == "end" then
      top = 0 - offset
    end
  end

  ---@param n integer
  ---@return string
  function obj.read(n)
    if n <= 0 or top == 0 then
      return ""
    end

    local count = math.min(n, top)

    ---@type string[]
    local chars = {}

    for i = 1, count do
      chars[i] = string.char(data[top])
      top = top - 1
    end

    return table.concat(chars)
  end

  ---@return integer
  function obj.size()
    return top
  end

  ---@return boolean
  function obj.isEmpty()
    return top == 0
  end

  return obj
end

return BinStack
