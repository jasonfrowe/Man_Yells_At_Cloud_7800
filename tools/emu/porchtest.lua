-- The porch, played by a bot (tools/test_porch.sh). From the menu: the
-- porch, night 3. Then:
--   1. mashing: button 1 eight times a second; Arthur must get dizzy
--   2. pacing: one yell on every beat, aimed at the soft spot; he must
--      not get dizzy, and the Cloud must break (CALM full) in under 40 s
--   3. the rain: screenshots of the rain and the Cloud's two pages
-- Prints "result dizzy_frame paced_dizzy rain_frames hits".
-- RAM (build/work/myac.bas.symbol.txt): cloudx $E6, spotx $E7, aim $E8,
-- bp $E9, calm $EA, dizzyt $EB; mus_frame $2581.
local fields = {}
for tag, port in pairs(manager:machine():ioport().ports) do
  for name, field in pairs(port.fields) do fields[name] = field end
end
local function m() return manager:machine().devices[":maincpu"].spaces["program"] end
local f, phase, t0 = 0, "menu", 0
local mashdizzy, paceddizzy, rainf, hits, lastcalm, maxbp = -1, 0, -1, 0, 0, 0
local shots = {}
local AIMDX = {[0] = 0, 1, 1, 2, 2, 3}
local AIMDY = {[0] = 4, 4, 3, 3, 2, 2}
emu.register_frame_done(function()
  f = f + 1
  local mm = m()
  local held = {}
  local cloudx, spotx, aim = mm:read_u8(0xE6), mm:read_u8(0xE7), mm:read_u8(0xE8)
  local bp, calm, dizzy = mm:read_u8(0xE9), mm:read_u8(0xEA), mm:read_u8(0xEB)
  local beat = mm:read_u8(0x2581) & 31
  if phase == "menu" then
    if f >= 220 and f < 224 then held["P1 Down"] = true end
    if (f >= 232 and f < 236) or (f >= 244 and f < 248) then held["P1 Right"] = true end
    if f >= 260 and f < 264 then held["P1 Button 1"] = true end
    if f == 300 then phase = "mash"; t0 = f end
  elseif phase == "mash" then
    if (f % 8) < 2 then held["P1 Button 1"] = true end
    if dizzy > 0 and mashdizzy < 0 then mashdizzy = f - t0; print(string.format("mashing: dizzy after %.1f s (bp %d)", mashdizzy / 60, bp)) end
    if f - t0 > 600 or (mashdizzy >= 0 and dizzy == 0) then phase = "pace"; t0 = f; lastcalm = calm end
  elseif phase == "pace" then
    -- aim where a yell from (24, 104) reaches y 70 nearest the soft spot
    local want, best, bd = cloudx + spotx + 4, 0, 1e9
    for a = 0, 5 do
      local x = 24 + AIMDX[a] * (34 / AIMDY[a])
      if math.abs(x - want) < bd then bd, best = math.abs(x - want), a end
    end
    if f % 6 < 2 then
      if aim < best then held["P1 Right"] = true elseif aim > best then held["P1 Left"] = true end
    end
    if beat == 0 then held["P1 Button 1"] = true end
    if dizzy > 0 then paceddizzy = 1 end
    if bp > maxbp then maxbp = bp end
    if calm > lastcalm then hits = hits + 1 end
    lastcalm = calm
    if calm >= 128 then
      rainf = f - t0; phase = "rain"; t0 = f
      print(string.format("pacing: the Cloud broke after %.1f s, %d hits, most bp %d, dizzy %d", rainf / 60, hits, maxbp, paceddizzy))
    end
    if f - t0 > 2400 then print(string.format("pacing: no rain after 40 s (calm %d)", calm)); phase = "done" end
  elseif phase == "rain" then
    if f - t0 == 150 or f - t0 == 330 or f - t0 == 640 then manager:machine().screens[":screen"]:snapshot() end
    if f - t0 > 650 then phase = "done" end
  end
  if phase == "pace" and (f - t0 == 300) then manager:machine().screens[":screen"]:snapshot() end
  for name, field in pairs(fields) do
    if name:match("^P1 ") then field:set_value(held[name] and 1 or 0) end
  end
  if phase == "done" then
    print(string.format("result %d %d %d %d", mashdizzy, paceddizzy, rainf, hits))
    manager:machine():exit()
  end
end)
