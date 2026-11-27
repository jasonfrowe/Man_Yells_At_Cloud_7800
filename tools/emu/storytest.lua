-- The story, played by a bot (tools/test_story.sh): the title's STORY, then
-- every step in turn (src/myac.bas storystep) until the mirror opens:
--   a cutscene   button 1 now and then (finish a page, turn it)
--   the day job  Cloud Assist (the Konami code), then button 1 at the match
--   the evening  log off (button 2): the forum has its own test
--   the porch    yell on the beat until the rain, through its pages
--   the storm    wait for the words, then button 1
-- A screenshot a little after each step starts. Prints each step, and
-- "result <last step reached> <frames>".
-- RAM: chap $2715, mus_frame $2581, sCTRL $2107.
local fields = {}
for tag, port in pairs(manager:machine():ioport().ports) do
  for name, field in pairs(port.fields) do fields[name] = field end
end
local function m() return manager:machine().devices[":maincpu"].spaces["program"] end
local function snap() manager:machine().screens[":screen"]:snapshot() end
-- each step's kind (storystep): 1 cut, 2 job, 3 forum, 4 porch, 5 storm, 6 mirror
local KIND = {1, 2, 1, 3, 1, 4, 1, 2, 1, 3, 1, 4, 1, 2, 1, 3, 1, 4, 5, 1, 6, 1, 7}
local NAME = {"cutscene", "day job", "evening", "porch", "storm", "mirror", "end"}
local KONAMI = {"P1 Up", "P1 Up", "P1 Down", "P1 Down", "P1 Left", "P1 Right", "P1 Left", "P1 Right",
                "P1 Button 2", "P1 Button 1"}
local f, t0, chap, started = 0, 0, -1, false
emu.register_frame_done(function()
  f = f + 1
  local mm = m()
  local held = {}
  if not started then
    -- the title: STORY is first
    if f >= 160 and f < 164 then held["P1 Button 1"] = true end
    if f == 150 then snap() end
    if f > 170 then started = true end
  else
    local c = mm:read_u8(0x2715)
    if c ~= chap then
      chap = c; t0 = f
      print(string.format("frame %d: step %d, %s", f, c, NAME[KIND[c + 1]] or "?"))
    end
    local k, dt = KIND[chap + 1], f - t0
    if dt == 45 then snap() end
    if k == 1 then
      if dt > 20 and dt % 16 < 3 then held["P1 Button 1"] = true end
    elseif k == 2 then
      local i = (dt - 60) // 12 + 1
      if dt >= 60 and i <= #KONAMI and (dt - 60) % 12 < 4 then held[KONAMI[i]] = true end
      if dt > 600 and dt % 30 < 3 then held["P1 Button 1"] = true end
    elseif k == 3 then
      if dt > 60 and dt % 30 < 3 then held["P1 Button 2"] = true end
    elseif k == 4 then
      if (mm:read_u8(0x2581) & 31) == 0 then held["P1 Button 1"] = true end
      if dt == 600 then snap() end
    elseif k == 5 then
      if dt == 400 or dt == 800 or dt == 1050 then snap() end
      if os.getenv("STORMSNAPS") and dt >= 450 and dt < 560 then snap() end
      if dt > 1060 and dt % 30 < 3 then held["P1 Button 1"] = true end
    elseif k == 6 then
      if dt == 120 then
        snap()
        print(string.format("result %d %d", chap, f))
        manager:machine():exit()
      end
    end
    if dt > 6000 then
      print(string.format("result %d %d (stuck)", chap, f))
      manager:machine():exit()
    end
  end
  for name, field in pairs(fields) do
    if name:match("^P1 ") then field:set_value(held[name] and 1 or 0) end
  end
end)
