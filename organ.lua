-- we have C3, C4, C5
-- F#5 through G4 0: bottom 1: left
-- F#4 through G3 0: front 1: back
-- F#3 through G2 0: top 1: right
-- F#2 through F#1 0: low 1: low
local mask_0_low = 0
local mask_1_low = 0

local mask_0_top = 0
local mask_0_front = 0
local mask_0_bottom = 0
local mask_1_right = 0
local mask_1_back = 0
local mask_1_left = 0
local note_map = {
  [66] = 1,
  [65] = 2,
  [64] = 4,
  [63] = 8,
  [62] = 16,
  [61] = 32,
  [60] = 64,
  [59] = 128,
  [58] = 256,
  [57] = 512,
  [56] = 1024,
  [55] = 2048,
  [54] = 1,
  [53] = 2,
  [52] = 4,
  [51] = 8,
  [50] = 16,
  [49] = 32,
  [48] = 64,
  [47] = 128,
  [46] = 256,
  [45] = 512,
  [44] = 1024,
  [43] = 2048,
  [42] = 1,
  [41] = 2,
  [40] = 4,
  [39] = 8,
  [38] = 16,
  [37] = 32,
  [36] = 64,
  [35] = 128,
  [34] = 256,
  [33] = 512,
  [32] = 1024,
  [31] = 2048,
  [30] = 1,
  [29] = 2,
  [28] = 4,
  [27] = 8,
  [26] = 16,
  [25] = 32,
  [24] = 64,
  [23] = 128,
  [22] = 256,
  [21] = 512,
  [20] = 1024,
  [19] = 2048,
  [18] = 4096,
  [67] = 32768,
  [68] = 16384,
  [69] = 8192,
  [70] = 4096,
  [71] = 32768,
  [72] = 16384,
  [73] = 8192,
  [74] = 4096,
  [75] = 32768,
  [76] = 16384,
  [77] = 8192,
  [78] = 4096,
}
local note_map_disable = {}
for k, v in pairs(note_map) do
  note_map_disable[k] = bit32.bnot(v)
end
local invalid_notes = {}
local function use(note)
  if invalid_notes[note] then
    invalid_notes[note] = invalid_notes[note] + 1
  else
    invalid_notes[note] = 1
  end
end
---@type ccTweaked.peripheral.Modem
local modem = peripheral.find("modem") or error("No modem attached", 0)
---@param channel integer
---@param note integer
---@param enable boolean
local function setNote(channel, note, enable)
  if channel == 0 then
    if note >= 18 then
      if note <= 30 then
        -- top
        if enable then
          mask_0_low = bit32.bor(mask_0_low, note_map[note])
        else
          mask_0_low = bit32.band(mask_0_low, note_map_disable[note])
        end
        modem.transmit(13, 1, mask_0_low)
      elseif note <= 42 then
        -- top
        if enable then
          mask_0_top = bit32.bor(mask_0_top, note_map[note])
        else
          mask_0_top = bit32.band(mask_0_top, note_map_disable[note])
        end
        redstone.setBundledOutput("top", mask_0_top)
      elseif note <= 54 then
        -- front
        if enable then
          mask_0_front = bit32.bor(mask_0_front, note_map[note])
        else
          mask_0_front = bit32.band(mask_0_front, note_map_disable[note])
        end
        redstone.setBundledOutput("front", mask_0_front)
      elseif note <= 66 then
        -- bottom
        if enable then
          mask_0_bottom = bit32.bor(mask_0_bottom, note_map[note])
        else
          mask_0_bottom = bit32.band(mask_0_bottom, note_map_disable[note])
        end
        redstone.setBundledOutput("bottom", mask_0_bottom)
      elseif note <= 70 then
        -- top 2
        if enable then
          mask_0_top = bit32.bor(mask_0_top, note_map[note])
        else
          mask_0_top = bit32.band(mask_0_top, note_map_disable[note])
        end
        redstone.setBundledOutput("top", mask_0_top)
      elseif note <= 74 then
        -- front 2
        if enable then
          mask_0_front = bit32.bor(mask_0_front, note_map[note])
        else
          mask_0_front = bit32.band(mask_0_front, note_map_disable[note])
        end
        redstone.setBundledOutput("front", mask_0_front)
      elseif note <= 78 then
        -- bottom 2
        if enable then
          mask_0_bottom = bit32.bor(mask_0_bottom, note_map[note])
        else
          mask_0_bottom = bit32.band(mask_0_bottom, note_map_disable[note])
        end
        redstone.setBundledOutput("bottom", mask_0_bottom)
      else
        -- use(note)
      end
    else
      -- use(note)
    end
  elseif channel == 1 then
    if note >= 18 then
      if note <= 30 then
        -- top
        if enable then
          mask_1_low = bit32.bor(mask_1_low, note_map[note])
        else
          mask_1_low = bit32.band(mask_1_low, note_map_disable[note])
        end
        modem.transmit(14, 1, mask_0_low)
      elseif note <= 42 then
        -- right
        if enable then
          mask_1_right = bit32.bor(mask_1_right, note_map[note])
        else
          mask_1_right = bit32.band(mask_1_right, note_map_disable[note])
        end
        redstone.setBundledOutput("left", mask_1_right)
      elseif note <= 54 then
        -- back
        if enable then
          mask_1_back = bit32.bor(mask_1_back, note_map[note])
        else
          mask_1_back = bit32.band(mask_1_back, note_map_disable[note])
        end
        redstone.setBundledOutput("back", mask_1_back)
      elseif note <= 66 then
        -- left
        if enable then
          mask_1_left = bit32.bor(mask_1_left, note_map[note])
        else
          mask_1_left = bit32.band(mask_1_left, note_map_disable[note])
        end
        redstone.setBundledOutput("right", mask_1_left)
      elseif note <= 70 then
        -- right 2
        if enable then
          mask_1_right = bit32.bor(mask_1_right, note_map[note])
        else
          mask_1_right = bit32.band(mask_1_right, note_map_disable[note])
        end
        redstone.setBundledOutput("left", mask_1_right)
      elseif note <= 74 then
        -- back 2
        if enable then
          mask_1_back = bit32.bor(mask_1_back, note_map[note])
        else
          mask_1_back = bit32.band(mask_1_back, note_map_disable[note])
        end
        redstone.setBundledOutput("back", mask_1_back)
      elseif note <= 78 then
        -- left 2
        if enable then
          mask_1_left = bit32.bor(mask_1_left, note_map[note])
        else
          mask_1_left = bit32.band(mask_1_left, note_map_disable[note])
        end
        redstone.setBundledOutput("right", mask_1_left)
      else
        -- use(note)
      end
    else
      -- use(note)
    end
  end
  -- return invalid_notes
end

return setNote