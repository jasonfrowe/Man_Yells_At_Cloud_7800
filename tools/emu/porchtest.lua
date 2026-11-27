-- The porch, played by a bot (tools/test_porch.sh). From the menu: the
-- porch, night 3. Then:
--   1. mashing: a yell every 8 frames; TOO FAST, and Arthur must get dizzy
--   2. off the beat: a yell a beat, a quarter beat late (the aim off the
--      Cloud): every one must miss, CALM must drain, and he must end up
--      exhausted (in the rocking chair)
--   3. on the beat: a yell as the swing crosses the Cloud's middle; he must
--      not get dizzy, and the Cloud must break in under 40 s
--   4. the rain: screenshots of the rain, the Cloud's second page, and
--      Arthur's answer
-- Prints "result mash_dizzy offbeat_calm onbeat_dizzy rain_frames".
-- RAM (build/work/myac.bas.symbol.txt): bp $E9, calm $EA, dizzyt $EB;
-- mus_frame $2581.
local fields = {}
for tag, port in pairs(manager:machine():ioport().ports) do
  for name, field in pairs(port.fields) do fields[name] = field end
end
local function m() return manager:machine().devices[":maincpu"].spaces["program"] end
local f, phase, t0 = 0, "menu", 0
local mashdizzy, offcalm, ondizzy, rainf, maxbp, offdizzy = -1, -1, 0, -1, 0, -1
emu.register_frame_done(function()
  f = f + 1
  local mm = m()
  local held = {}
  -- the title: PROTOTYPES (down, fire), for the menu
  if f >= 150 and f < 154 then held["P1 Down"] = true end
  if f >= 160 and f < 164 then held["P1 Button 1"] = true end
  local bp, calm, dizzy = mm:read_u8(0xE9), mm:read_u8(0xEA), mm:read_u8(0xEB)
  local beat = mm:read_u8(0x2581) & 31
  if phase == "menu" then
    if f >= 220 and f < 224 then held["P1 Down"] = true end
    if (f >= 232 and f < 236) or (f >= 244 and f < 248) then held["P1 Right"] = true end
    if f >= 260 and f < 264 then held["P1 Button 1"] = true end
    if f == 300 then phase = "mash"; t0 = f end
  elseif phase == "mash" then
    if (f % 8) < 2 then held["P1 Button 1"] = true end
    if dizzy > 0 and mashdizzy < 0 then
      mashdizzy = f - t0
      print(string.format("mashing: dizzy after %.1f s", mashdizzy / 60))
    end
    if f - t0 > 600 or (mashdizzy >= 0 and dizzy == 0) then
      phase = "off"; t0 = f
      mm:write_u8(0xEA, 40)                     -- some CALM to lose
    end
  elseif phase == "off" then
    if beat == 8 then held["P1 Button 1"] = true end
    if dizzy > 0 and offdizzy < 0 then
      offdizzy = f - t0
      print(string.format("off the beat: exhausted after %.1f s", offdizzy / 60))
    end
    if f - t0 == 480 then
      offcalm = calm
      print(string.format("off the beat: CALM 40 -> %d after 8 s", calm))
      phase = "on"; t0 = f
      mm:write_u8(0xEA, 0); mm:write_u8(0xE9, 0)
    end
  elseif phase == "on" then
    -- the swing crosses the middle at mus_frame 0 and 32; the yell lands
    -- 16 frames later, but it's aimed when it's thrown
    if beat == 0 then held["P1 Button 1"] = true end
    if dizzy > 0 then ondizzy = 1 end
    if bp > maxbp then maxbp = bp end
    if f - t0 == 300 then manager:machine().screens[":screen"]:snapshot() end
    if calm >= 128 then
      rainf = f - t0; phase = "rain"; t0 = f
      print(string.format("on the beat: the Cloud broke after %.1f s, most bp %d, dizzy %d", rainf / 60, maxbp, ondizzy))
    end
    if f - t0 > 2400 then print(string.format("on the beat: no rain after 40 s (calm %d)", calm)); phase = "done" end
  elseif phase == "rain" then
    if f - t0 == 150 or f - t0 == 420 or f - t0 == 720 then manager:machine().screens[":screen"]:snapshot() end
    if f - t0 > 730 then phase = "done" end
  end
  for name, field in pairs(fields) do
    if name:match("^P1 ") then field:set_value(held[name] and 1 or 0) end
  end
  if phase == "done" then
    if offdizzy < 0 then offcalm = 99 end
    print(string.format("result %d %d %d %d", mashdizzy, offcalm, ondizzy, rainf))
    manager:machine():exit()
  end
end)
