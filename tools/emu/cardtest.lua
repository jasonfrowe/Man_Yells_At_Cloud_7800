-- The day job, played by a bot (tools/test_cards.sh), one day a run (DAY,
-- 1-3): from the menu, the day job, with the stick's right picking the day.
-- Day 1 first goes down to GO HOME and takes it (it must land back on the
-- menu, in 160A), comes back, then punches HELLO's rest by hand: L (LOAD 76
-- = 64 + 8 + 4), OUT, OUT, O (up to LOAD: LOAD 79 = 64 + 8 + 4 + 2 + 1), OUT, and runs.
-- Days 2 and 3: the Konami code (Cloud Assist). Each must match; then
-- button 1 goes home. Prints "result matched went_home back_at_menu".
-- RAM: cstate $226E (2 a result), ctimer $2270 (1 a match), crow $226A,
-- sCTRL $2107 (%01000011 the day job's 320A, %01010000 the menu's 160A).
local fields = {}
for tag, port in pairs(manager:machine():ioport().ports) do
  for name, field in pairs(port.fields) do fields[name] = field end
end
local function m() return manager:machine().devices[":maincpu"].spaces["program"] end
local U, D, L, R, A, B = "P1 Up", "P1 Down", "P1 Left", "P1 Right", "P1 Button 1", "P1 Button 2"
local day = tonumber(os.getenv("DAY") or "1")
local DAY1 = {R, R, R, R, A, D, D, D, D, D, A, D, D, D, A, D, A,
              R, U, U, U, U, U, A, R, A,
              R, U, U, U, U, A, D, D, D, D, D, A, D, D, D, A, D, A, D, A, D, A,
              R, U, U, U, U, U, U, U, A, "SNAP", B}
local KONAMI = {U, U, D, D, L, R, L, R, B, A, "WAIT", "SNAP"}
local MENU = {"WAIT", D, D}
for i = 2, day do table.insert(MENU, R) end
table.insert(MENU, A)
local queue, f, phase, matched, wenthome = {}, 0, "boot", 0, 0
local function push(list) for _, a in ipairs(list) do table.insert(queue, a) end end
local cur, hold, t0 = nil, 0, 0
emu.register_frame_done(function()
  f = f + 1
  local mm = m()
  local held = {}
  -- the title: PROTOTYPES (down, fire), for the menu
  if f >= 150 and f < 154 then held["P1 Down"] = true end
  if f >= 160 and f < 164 then held["P1 Button 1"] = true end
  local cstate, ctimer, ctrl = mm:read_u8(0x226E), mm:read_u8(0x2270), mm:read_u8(0x2107)
  local idle = #queue == 0 and cur == nil
  if phase == "boot" and f == 200 then push(MENU); phase = "enter"
  elseif phase == "enter" and idle and ctrl == 0x43 then
    t0 = f; phase = "inside"
  elseif phase == "inside" and f - t0 > 40 then
    if day == 1 and wenthome == 0 then
      push({D, D, D, D, D, D, D, D, D, D, D, D, "SNAP", A}); phase = "home"
    else
      push(day == 1 and DAY1 or KONAMI); phase = "job"
    end
  elseif phase == "home" and idle and ctrl == 0x50 then
    print("went home: the menu"); wenthome = 1
    push({"WAIT", A}); phase = "enter"
  elseif phase == "job" and idle and cstate == 2 then
    if ctimer == 1 then
      matched = 1
      print(string.format("day %d: it matches", day))
      manager:machine().screens[":screen"]:snapshot()
    else
      print(string.format("day %d: no match (or a jam)", day))
    end
    push({"WAIT", A}); phase = "end"; t0 = f
  elseif phase == "end" and f - t0 > 90 then phase = "done" end
  -- one action at a time: held 3 frames, then 5 off
  if cur == nil and #queue > 0 then cur = table.remove(queue, 1); hold = 0 end
  if cur then
    hold = hold + 1
    if cur == "SNAP" then manager:machine().screens[":screen"]:snapshot(); cur = nil
    elseif cur == "WAIT" then if hold > 30 then cur = nil end
    else
      if hold <= 3 then held[cur] = true end
      if hold >= 8 then cur = nil end
    end
  end
  for name, field in pairs(fields) do
    if name:match("^P1 ") then field:set_value(held[name] and 1 or 0) end
  end
  if f > 8000 then phase = "done" end
  if phase == "done" then
    print(string.format("result %d %d %d", matched, wenthome, ctrl == 0x50 and 1 or 0))
    manager:machine():exit()
  end
end)
