--- midi_events.lua
--- Module for storing and polling midi events.
--- Works with CC: Tweaked (Lua 5.2).
--- @module midi_events

local M = {}

---@enum EventType
M.EVENT_TYPES = {
	ChangeChannel = 0,
	EndOfTrack = 1,
	SetTempo = 2,
	TimeSignature = 3,
	KeySignature = 4,
  NoteOff = 5,
  NoteOn = 6,
  AfterTouch = 7,
  ControlChange = 8,
  ProgramChange = 9,
  ChannelPressure = 10,
  PitchWheel = 11,
}

-- ---@enum EventMask
-- local EVENT_MASKS = {
--   NoteOff = 0x80,
--   NoteOn = 0x90,
--   Aftertouch = 0xA0,

-- }

--- @enum BitMask
M.MASKS = {
  Bit0 = 0x1,
  Bit1 = 0x2,
  Bit2 = 0x4,
  Bit3 = 0x8,
  Bit4 = 0x16,
  Bit5 = 0x32,
  Bit6 = 0x64,
  Bit7 = 0x128
}

---@class Event
---@field type EventType
---@field delta integer

---@class MetaEvent: Event

---@class MidiEvent: Event
---@field channel integer

---@class ChangeChannel: MetaEvent
---@field channel integer

---@class EndOfTrack: MetaEvent

---@class SetTempo: MetaEvent
---@field tempo integer

---@class TimeSignature: MetaEvent
---@field numerator integer
---@field denominator integer
---@field clocks_per_click integer
---@field bb integer

---@class KeySignature: MetaEvent
---@field accidentals integer
---@field ismajor boolean

---@class NoteOff: MidiEvent
---@field note integer
---@field velocity integer

---@class NoteOn: MidiEvent
---@field note integer
---@field velocity integer

---@class AfterTouch: MidiEvent
---@field note integer
---@field pressure integer

---@class ControlChange: MidiEvent
---@field controller integer
---@field value integer

---@class ProgramChange: MidiEvent
---@field program integer

---@class ChannelPressure: MidiEvent
---@field pressure integer

---@class PitchWheel: MidiEvent
---@field modifier integer

---@alias GenericEvent ChangeChannel|EndOfTrack|SetTempo|TimeSignature|KeySignature|NoteOff|NoteOn|AfterTouch|ControlChange|ProgramChange|ChannelPressure|PitchWheel

---@param delta integer
---@param channel integer
---@return ChangeChannel
function M.ChangeChannel(delta, channel)
  ---@type ChangeChannel
  return { delta = delta, type = M.EVENT_TYPES.ChangeChannel, channel = channel }
end

---@param delta integer
---@return EndOfTrack
function M.EndOfTrack(delta)
  ---@type EndOfTrack
  return { delta = delta, type = M.EVENT_TYPES.EndOfTrack }
end

---@param delta integer
---@param tempo integer
---@return SetTempo
function M.SetTempo(delta, tempo)
  ---@type SetTempo
  return { delta = delta, type = M.EVENT_TYPES.SetTempo, tempo = tempo }
end

---@param delta integer
---@param numerator integer
---@param denominator integer
---@param clocks_per_click integer
---@param bb integer
---@return TimeSignature
function M.TimeSignature(delta, numerator, denominator, clocks_per_click, bb)
  ---@type TimeSignature
  return {
    delta = delta,
    type = M.EVENT_TYPES.TimeSignature,
    numerator = numerator,
    denominator = denominator,
    clocks_per_click = clocks_per_click,
    bb = bb
  }
end

---@param delta integer
---@param accidentals integer
---@param ismajor boolean
---@return KeySignature
function M.KeySignature(delta, accidentals, ismajor)
  ---@type KeySignature
  return {
    delta = delta,
    type = M.EVENT_TYPES.KeySignature,
    accidentals = accidentals,
    ismajor = ismajor
  }
end

---@param delta integer
---@param channel integer
---@param note integer
---@param velocity integer
---@return NoteOff
function M.NoteOff(delta, channel, note, velocity)
  ---@type NoteOff
  return {
    delta = delta,
    channel = channel,
    type = M.EVENT_TYPES.NoteOff,
    note = note,
    velocity = velocity
  }
end

---@param delta integer
---@param channel integer
---@param note integer
---@param velocity integer
---@return NoteOn
function M.NoteOn(delta, channel, note, velocity)
  ---@type NoteOn
  return {
    delta = delta,
    channel = channel,
    type = M.EVENT_TYPES.NoteOn,
    note = note,
    velocity = velocity
  }
end

---@param delta integer
---@param channel integer
---@param note integer
---@param pressure integer
---@return AfterTouch
function M.AfterTouch(delta, channel, note, pressure)
  ---@type AfterTouch
  return {
    delta = delta,
    channel = channel,
    type = M.EVENT_TYPES.AfterTouch,
    note = note,
    pressure = pressure
  }
end

---@param delta integer
---@param channel integer
---@param controller integer
---@param value integer
---@return ControlChange
function M.ControlChange(delta, channel, controller, value)
  ---@type ControlChange
  return {
    delta = delta,
    channel = channel,
    type = M.EVENT_TYPES.ControlChange,
    controller = controller,
    value = value
  }
end

---@param delta integer
---@param channel integer
---@param program integer
---@return ProgramChange
function M.ProgramChange(delta, channel, program)
  ---@type ProgramChange
  return {
    delta = delta,
    channel = channel,
    type = M.EVENT_TYPES.ProgramChange,
    program = program
  }
end

---@param delta integer
---@param channel integer
---@param pressure integer
---@return ChannelPressure
function M.ChannelPressure(delta, channel, pressure)
  ---@type ChannelPressure
  return {
    delta = delta,
    channel = channel,
    type = M.EVENT_TYPES.ChannelPressure,
    pressure = pressure
  }
end

---@param delta integer
---@param channel integer
---@param modifier integer
---@return PitchWheel
function M.PitchWheel(delta, channel, modifier)
  ---@type PitchWheel
  return {
    delta = delta,
    channel = channel,
    type = M.EVENT_TYPES.PitchWheel,
    modifier = modifier
  }
end

---@class Timeline
---@field length integer
---@field events table<integer, GenericEvent>
---@field pointer integer

---@return Timeline
function M.Timeline()
  return { length = 0, events = {}, pointer = 1 }
end

---@param t Timeline
---@param e GenericEvent
function M.append(t, e)
  t.events[t.length] = e
  t.length = t.length + 1
end

---@param t Timeline
---@return GenericEvent
function M.poll(t)
  t.pointer = t.pointer + 1
  return t.events[t.pointer - 1]
end

--- Module table
return M
