--- binreader.lua
--- Simple module for reading 16/32-bit signed/unsigned integers from a byte string.
--- Works with CC: Tweaked (Lua 5.2 + bit32).
--- @module binreader

local BinStack = require("binstack")
local bit32 = bit32
local M = {}

--- Get byte at position (1-based) or 0 if out of range.
--- @param s string
--- @param i integer
--- @return integer
local function b(s, i)
  return string.byte(s, i) or 0
end

--- Read unsigned 16-bit little-endian from string.
--- @param s string
--- @param i integer? start index (1-based). Defaults to 1.
--- @return integer
function M.u16_le(s, i) i = i or 1; return bit32.bor(b(s,i), bit32.lshift(b(s,i+1), 8)) end

--- Read unsigned 16-bit big-endian from string.
--- @param s string
--- @param i integer? start index (1-based). Defaults to 1.
--- @return integer
function M.u16_be(s, i) i = i or 1; return bit32.bor(bit32.lshift(b(s,i), 8), b(s,i+1)) end

--- Read signed 16-bit little-endian from string.
--- @param s string
--- @param i integer? start index (1-based). Defaults to 1.
--- @return integer
function M.s16_le(s, i)
  i = i or 1
  local v = M.u16_le(s, i)
  if v >= 0x8000 then return v - 0x10000 end
  return v
end

--- Read signed 16-bit big-endian from string.
--- @param s string
--- @param i integer? start index (1-based). Defaults to 1.
--- @return integer
function M.s16_be(s, i)
  i = i or 1
  local v = M.u16_be(s, i)
  if v >= 0x8000 then return v - 0x10000 end
  return v
end

--- Read unsigned 32-bit little-endian from string.
--- @param s string
--- @param i integer? start index (1-based). Defaults to 1.
--- @return integer
function M.u32_le(s, i)
  i = i or 1
  return bit32.bor(
    b(s,i),
    bit32.lshift(b(s,i+1), 8),
    bit32.lshift(b(s,i+2), 16),
    bit32.lshift(b(s,i+3), 24)
  )
end

--- Read unsigned 32-bit big-endian from string.
--- @param s string
--- @param i integer? start index (1-based). Defaults to 1.
--- @return integer
function M.u32_be(s, i)
  i = i or 1
  return bit32.bor(
    bit32.lshift(b(s,i), 24),
    bit32.lshift(b(s,i+1), 16),
    bit32.lshift(b(s,i+2), 8),
    b(s,i+3)
  )
end

--- Read signed 32-bit little-endian from string.
--- @param s string
--- @param i integer? start index (1-based). Defaults to 1.
--- @return integer
function M.s32_le(s, i)
  i = i or 1
  local v = M.u32_le(s, i)
  if v >= 0x80000000 then return v - 0x100000000 end
  return v
end

--- Read signed 32-bit big-endian from string.
--- @param s string
--- @param i integer? start index (1-based). Defaults to 1.
--- @return integer
function M.s32_be(s, i)
  i = i or 1
  local v = M.u32_be(s, i)
  if v >= 0x80000000 then return v - 0x100000000 end
  return v
end

--- Read unsigned 24-bit big-endian from string.
--- @param s string
--- @param i integer? start index (1-based). Defaults to 1.
--- @return integer
function M.u24_be(s, i)
  i = i or 1
  local b1 = string.byte(s, i) or 0
  local b2 = string.byte(s, i+1) or 0
  local b3 = string.byte(s, i+2) or 0
  return (b1 * 0x10000) + (b2 * 0x100) + b3
end

--- Read signed 24-bit big-endian from string (two's complement).
--- @param s string
--- @param i integer? start index (1-based). Defaults to 1.
--- @return integer
function M.s24_be(s, i)
  i = i or 1
  local v = M.u24_be(s, i)
  if v >= 0x800000 then return v - 0x1000000 end
  return v
end
--- all of the above is modified LLM output

-- --- @param s ccTweaked.fs.BinaryReadHandle
-- --- @param i integer
-- --- @return integer|nil
-- local function btest8(s, i)
--   bit32.btest(string.byte(, 1), 0x80)
-- end

--- Read that evil uint14 for PitchWheel events
--- @param s string
--- @return integer
function M.pitch(s)
  return bit32.band(string.byte(s, 1), 0x0F) + bit32.rshift(bit32.band(string.byte(s, 2), 0xF0), 1)
end

--- Read midi variable-length value from ReadHandle.
--- @param s BinStack
--- @return integer
function M.varlen(s)
  -- find out long the value is
  local len = 1
  while bit32.btest(string.byte(s.read(1), 1), 0x80) do -- bit32.band(b, 0x80) == 0x80
    len = len + 1
  end
  -- reset
  s.seek("cur", -1 * len)
  -- read value
  local b = string.byte(s.read(1), 1)
  local val = 0
  local i = 1
  while i < len do
    val = val + bit32.lshift(bit32.bxor(b, 0x80), 7 * (len - i))
    b = string.byte(s.read(1), 1)
    i = i + 1
  end
  val = val + bit32.lshift(b, 7 * (len - i))
  return val
end

--- Module table
--- @type table<string, fun(...) : any>
return M
