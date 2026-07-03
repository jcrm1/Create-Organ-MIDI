-- midi file info from https://ccrma.stanford.edu/~craig/14q/midifile/MidiFileFormat.html
-- and https://midimusic.github.io/tech/midispec.html
-- and http://midi.teragonaudio.com/tech/midispec.htm

local bin = require("binreader")
local Events = require("midi_events")
local BinStack = require("binstack")
local bit32 = bit32
local setNote = require("organ")

local orig_print = print

local log = fs.open("/log.txt", "a")
if not log then
  print("Unable to open log file")
  return
end
log.writeLine("-----------")

local function print(...)
  orig_print(...)
  local res = ""
  for _, v in ipairs(table.pack(...)) do
    res = res .. tostring(v) .. " "
  end
  log.writeLine(res)
end

--- Get the high nibble of a single byte
--- @param b integer
--- @return integer
local function highnib(b)
  return bit32.rshift(b, 4)
end
--- Get the low nibble of a single byte
--- @param b integer
--- @return integer
local function lownib(b)
  return bit32.band(b, 0x0F)
end

-- local function

---@type ccTweaked.fs.BinaryReadHandle
---@diagnostic disable-next-line: assign-type-mismatch
local mid_file = fs.open("/sm64-merged.mid", "rb")
if not mid_file then
  print("failed to open midi file")
  return
end

local file_data = mid_file.readAll()
if file_data == nil then
  print("failed to read midi file")
  return
end
mid_file.close()
local file_len = string.len(file_data)

print(file_len)
---@type integer[]
local reversed_tbl_file_data = {}
for i = 1, file_len, 1 do
  reversed_tbl_file_data[i] = string.byte(file_data, file_len - i + 1)
end
print(# reversed_tbl_file_data)
local mid = BinStack.new()
mid.replaceData(reversed_tbl_file_data)

local header_mthd = mid.read(4)
if header_mthd ~= "MThd" then
  print("midi file does not have MThd", header_mthd, "|")
  return
end

local header_len_str = mid.read(4)
if not header_len_str then
  print("no header len")
  return
end
local header_len = bin.u32_be(header_len_str)

local format_str = mid.read(2)
if not format_str then
  print("no format")
  return
end
local format = bin.u16_be(format_str)

local num_tracks_str = mid.read(2)
if not num_tracks_str then
  print("no num tracks")
  return
end
local num_tracks = bin.u16_be(num_tracks_str)

local time_division_str = mid.read(2)
if not time_division_str then
  print("no time division")
  return
end
local time_division = bin.s16_be(time_division_str)
if time_division < 0 then
  print("SMPTE time division is unsupported")
  return
end
print("time division is " .. time_division)

---@type Timeline[]
local timelines = {}

for i = 1, num_tracks, 1 do
  print("reading track " .. i)

  local track_mtrk = mid.read(4)
  if track_mtrk ~= "MTrk" then
    print("midi file does not have MTrk")
    return
  end

  local track_length_str = mid.read(4)
  if not track_length_str then
    print("no track length")
    return
  end
  --- we pretty much ignore this in favor of the end-of-track event
  local track_length = bin.u32_be(track_length_str)
  print(track_length .. " bytes in the track")
  local timeline = Events.Timeline()
  ---@type nil|integer
  local last_status = nil -- running status
  local i = -1
  while true do
    i = i + 1
    -- print("Event", i)
    local delta = bin.varlen(mid)
    local b_str = mid.read(1)
    if b_str == nil then
      print("read nil from file?")
      return
    end
    local b = string.byte(b_str, 1)
    if bit32.band(b, 0x80) ~= 0x80 then
      -- missing the status byte. this means we push b and use running status.
      if not last_status then
        print("Tried to use running status before reading a status byte")
        return
      end
      mid.push(b)
      b = last_status
      -- print("Running Status", b)
    end
    if b == 0xF7 or b == 0xF0 then
      -- sysex event
      local len = bin.varlen(mid)
      mid.seek("cur", len)
      print("sysex event")
      -- done!
    elseif b == 0xFF then
      -- meta event
      local type1 = string.byte(mid.read(1), 1)
      if type1 == 0x00 then
        local type2 = string.byte(mid.read(1), 1)
        if type2 == 0x02 then
          -- SequenceNumber 1 arg
          mid.seek("cur", 2)
        elseif type2 == 0x00 then
          -- SequenceNumber 0
        end
      elseif type1 >= 0x1 and type1 <= 0x7 then
        -- Text Event, Copyright Event, etc.
        print("TextEvent", type1)
        local len = bin.varlen(mid)
        print(len, mid.read(len))
      elseif type1 == 0x20 then
        local type2 = string.byte(mid.read(1), 1)
        if type2 == 0x01 then
          -- ChangeChannel arg
          local cc_str = mid.read(1)
          if not cc_str then
            print("invalid file err 1")
            return
          end
          Events.append(timeline, Events.ChangeChannel(delta, string.byte(cc_str, 1)))
        end
      elseif type1 == 0x2F then
        local type2 = string.byte(mid.read(1), 1)
        if type2 == 0x00 then
          -- EndOfTrack
          Events.append(timeline, Events.EndOfTrack(delta))
          break
        end
      elseif type1 == 0x51 then
        local type2 = string.byte(mid.read(1), 1)
        if type2 == 0x03 then
          -- SetTempo
          local tempo_str = mid.read(3)
          if not tempo_str then
            print("invalid file err 2")
            return
          end
          local tempo = bin.u24_be(tempo_str)
          Events.append(timeline, Events.SetTempo(delta, tempo))
        end
      elseif type1 == 0x54 then
        -- smpte offset
        local type2 = string.byte(mid.read(1), 1)
        if type2 == 0x05 then
          mid.seek("cur", 5)
        end
      elseif type1 == 0x58 then
        local type2 = string.byte(mid.read(1), 1)
        if type2 == 0x04 then
          local numerator_str = mid.read(1)
          local denominator_str = mid.read(1)
          local clocks_str = mid.read(1)
          local bb_str = mid.read(1)
          if not numerator_str then
            print("invalid file err 3")
            return
          elseif not denominator_str then
            print("invalid file err 4")
            return
          elseif not clocks_str then
            print("invalid file err 5")
            return
          elseif not bb_str then
            print("invalid file err 6")
            return
          end
          local numerator = string.byte(numerator_str, 1)
          local denominator = string.byte(denominator_str, 1)
          local clocks = string.byte(clocks_str, 1)
          local bb = string.byte(bb_str, 1)
          Events.append(timeline, Events.TimeSignature(delta, numerator, denominator, clocks, bb))
        end
      elseif type1 == 0x59 then
        local type2 = string.byte(mid.read(1), 1)
        if type2 == 0x02 then
          local accidentals_str = mid.read(1)
          local ismajor_str = mid.read(1)
          if not accidentals_str then
            print("invalid file err 7")
            return
          elseif not ismajor_str then
            print("invalid file err 8")
            return
          end
          local accidentals = string.byte(accidentals_str, 1)
          local ismajor_num = string.byte(ismajor_str, 1)
          local ismajor = ismajor_num == 0
          Events.append(timeline, Events.KeySignature(delta, accidentals, ismajor))
        end
      elseif type1 == 0x7F then
        -- Sequencer-Specific Meta Event
        local len = bin.varlen(mid)
        mid.seek("cur", len)
      else
        print("Unsupported meta event", type1)
        local length = string.byte(mid.read(1), 1)
        mid.seek("cur", length)
      end
    else
      local high_status = highnib(b)
      local low_status = lownib(b)
      if high_status == 0x8 then
        -- Note off
        local note_str = mid.read(1)
        local velocity_str = mid.read(1)
        if not note_str then
          print("invalid file err 9")
          return
        elseif not velocity_str then
          print("invalid file err 10")
          return
        end
        local note = string.byte(note_str, 1)
        local velocity = string.byte(velocity_str, 1)
        Events.append(timeline, Events.NoteOff(delta, low_status, note, velocity))
      elseif high_status == 0x9 then
        -- Note on
        local note_str = mid.read(1)
        local velocity_str = mid.read(1)
        if not note_str then
          print("invalid file err 11")
          return
        elseif not velocity_str then
          print("invalid file err 12")
          return
        end
        local note = string.byte(note_str, 1)
        local velocity = string.byte(velocity_str, 1)
        Events.append(timeline, Events.NoteOn(delta, low_status, note, velocity))
      elseif high_status == 0xA then
        -- Aftertouch
        local note_str = mid.read(1)
        local pressure_str = mid.read(1)
        if not note_str then
          print("invalid file err 13")
          return
        elseif not pressure_str then
          print("invalid file err 14")
          return
        end
        local note = string.byte(note_str, 1)
        local pressure = string.byte(pressure_str, 1)
        Events.append(timeline, Events.AfterTouch(delta, low_status, note, pressure))
      elseif high_status == 0xB then
        -- Control change
        print("ControlChange")
        local controller_str = mid.read(1)
        local value_str = mid.read(1)
        if not controller_str then
          print("invalid file err 15")
          return
        elseif not value_str then
          print("invalid file err 16")
          return
        end
        local controller = string.byte(controller_str, 1)
        local value = string.byte(value_str, 1)
        Events.append(timeline, Events.ControlChange(delta, low_status, controller, value))
      elseif high_status == 0xC then
        -- Program (patch) change
        local program_str = mid.read(1)
        if not program_str then
          print("invalid file err 17")
          return
        end
        local program = string.byte(program_str, 1)
        Events.append(timeline, Events.ProgramChange(delta, low_status, program))
      elseif high_status == 0xD then
        -- Channel pressure
        local pressure_str = mid.read(1)
        if not pressure_str then
          print("invalid file err 18")
          return
        end
        local pressure = string.byte(pressure_str, 1)
        Events.append(timeline, Events.ChannelPressure(delta, low_status, pressure))
      elseif high_status == 0xE then
        -- Pitch wheel
        local pitch_str = mid.read(2)
        if not pitch_str then
          print("invalid file err 19")
          return
        end
        local pitch = bin.pitch(pitch_str)
        Events.append(timeline, Events.PitchWheel(delta, low_status, pitch))
      else
        print("HHHHH", b)
        return
      end -- switch on high_status
    end -- switch on b
    last_status = b
  end
  timelines[#timelines+1] = timeline
end

for i = 1, # timelines, 1 do
  print("Timeline", i, "length of", timelines[i].length)
end

--- Notes
--- This program is only compatible with ticks-per-quarter time mode. 
--- Example from docs above: If ticks-per-quarter is 96, then the time interval of an eigth note between two events is 48.
--- SetTempo provides the number of microseconds per quarter. So, we can calculate a number of microseconds-per-tick.
--- microseconds-per-tick = microseconds-per-quarter * (ticks-per-quarter^{-1})
for i = 1, # timelines, 1 do
  print("Starting playback of timeline", i)
  local tl = timelines[i]
  local seconds_per_tick = 0
  for j = 1, tl.length - 1, 1 do
    local e = Events.poll(tl)
    local real_delta = e.delta * seconds_per_tick
    -- sleep(real_delta)
    -- if 0 < real_delta and real_delta < 0.025 then
    --   print("RD", real_delta)
    -- end
    if real_delta > 0.025 then
      sleep(real_delta)
    end
    if e.type == Events.EVENT_TYPES.ChangeChannel then
      ---@type ChangeChannel
      ---@diagnostic disable-next-line: assign-type-mismatch
      local event = e
      print("ChangeChannel", e.channel)
      print("ChangeChannel unsupported")
      return
    elseif e.type == Events.EVENT_TYPES.EndOfTrack then
      ---@type EndOfTrack
      ---@diagnostic disable-next-line: assign-type-mismatch
      local event = e
      print("EndOfTrack")
    elseif e.type == Events.EVENT_TYPES.SetTempo then
      ---@type SetTempo
      ---@diagnostic disable-next-line: assign-type-mismatch
      local event = e
      print("SetTempo", event.tempo)
      seconds_per_tick = event.tempo * math.pow(time_division, -1) / math.pow(10, 6)
    elseif e.type == Events.EVENT_TYPES.TimeSignature then
      ---@type TimeSignature
      ---@diagnostic disable-next-line: assign-type-mismatch
      local event = e
      print("TimeSignature", event.numerator, event.denominator, event.clocks_per_click, event.bb)
    elseif e.type == Events.EVENT_TYPES.KeySignature then
      ---@type KeySignature
      ---@diagnostic disable-next-line: assign-type-mismatch
      local event = e
      print("KeySignature", event.accidentals, event.ismajor)
    elseif e.type == Events.EVENT_TYPES.NoteOff then
      ---@type NoteOff
      ---@diagnostic disable-next-line: assign-type-mismatch
      local event = e
      setNote(event.channel, event.note, false)
      -- print("NoteOff", event.channel, event.note, event.velocity)
    elseif e.type == Events.EVENT_TYPES.NoteOn then
      ---@type NoteOn
      ---@diagnostic disable-next-line: assign-type-mismatch
      local event = e
      setNote(event.channel, event.note, true)
      -- print("NoteOn", event.channel, event.note, event.velocity)
    elseif e.type == Events.EVENT_TYPES.AfterTouch then
      ---@type AfterTouch
      ---@diagnostic disable-next-line: assign-type-mismatch
      local event = e
      print("AfterTouch", event.channel, event.note, event.pressure)
    elseif e.type == Events.EVENT_TYPES.ControlChange then
      ---@type ControlChange
      ---@diagnostic disable-next-line: assign-type-mismatch
      local event = e
      print("ControlChange", event.channel, event.controller, event.value)
    elseif e.type == Events.EVENT_TYPES.ProgramChange then
      ---@type ProgramChange
      ---@diagnostic disable-next-line: assign-type-mismatch
      local event = e
      print("ProgramChange", event.channel, event.program)
    elseif e.type == Events.EVENT_TYPES.ChannelPressure then
      ---@type ChannelPressure
      ---@diagnostic disable-next-line: assign-type-mismatch
      local event = e
      print("ChannelPressure", event.channel, event.pressure)
    elseif e.type == Events.EVENT_TYPES.PitchWheel then
      ---@type PitchWheel
      ---@diagnostic disable-next-line: assign-type-mismatch
      local event = e
      print("PitchWheel", event.channel, event.modifier)
    end
  end
end
-- local pretty = require("cc.pretty")
-- log.writeLine(pretty.render(pretty.pretty(setNote(1, -1, true))))
log.close()
