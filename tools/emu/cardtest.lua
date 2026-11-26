-- The day job, played by a bot (tools/test_cards.sh). From the menu, the
-- day job. Job 1 (HI) by hand: the cursor to column 3, punch LOAD and 73
-- (64 + 8 + 1), column 4 OUT, run: it must match. Jobs 2 and 3 with the
-- Konami code (Cloud Assist): each must match. Then the shift's over, and
-- back to the menu. Screenshots: job 1's card punched, its match, job 2
-- running, the end. Prints "result jobs_matched back_at_menu".
-- RAM: cstate $226E (2 a result), ctimer $2270 (1 a match), cjob $226F.
local fields = {}
for tag, port in pairs(manager:machine():ioport().ports) do
  for name, field in pairs(port.fields) do fields[name] = field end
end
local function m() return manager:machine().devices[":maincpu"].spaces["program"] end
local U, D, L, R, A, B = "P1 Up", "P1 Down", "P1 Left", "P1 Right", "P1 Button 1", "P1 Button 2"
local JOB1 = {R, R, A, D, D, D, D, D, A, D, D, D, A, D, D, D, A, R, U, U, U, U, U, U, U, A, "SNAP", B}
local KONAMI = {U, U, D, D, L, R, L, R, B, A}
local queue, f, t0, phase, matched = {}, 0, 0, "menu", 0
local function push(list) for _, a in ipairs(list) do table.insert(queue, a) end end
local cur, hold = nil, 0
emu.register_frame_done(function()
  f = f + 1
  local mm = m()
  local held = {}
  local cstate, ctimer, cjob = mm:read_u8(0x226E), mm:read_u8(0x2270), mm:read_u8(0x226F)
  if phase == "menu" then
    if (f >= 220 and f < 224) or (f >= 235 and f < 239) then held[D] = true end
    if f >= 260 and f < 264 then held[A] = true end
    if f == 320 then phase = "job"; push(JOB1) end
  elseif phase == "job" then
    if #queue == 0 and cur == nil then
      if cstate == 2 then
        if ctimer == 1 then
          matched = matched + 1
          print(string.format("job %d: it matches", cjob + 1))
          manager:machine().screens[":screen"]:snapshot()
          push({"WAIT", A})
          if cjob < 2 then push(KONAMI); push({"WAIT", "WAIT", "WAIT", "SNAP"}) end
        elseif ctimer == 3 then
          print("the shift's over"); push({"WAIT", "SNAP", A}); phase = "end"; t0 = f
        else
          print(string.format("job %d: no match (or a jam)", cjob + 1)); phase = "done"
        end
      end
    end
  elseif phase == "end" then
    if f - t0 > 120 then phase = "done" end
  end
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
  if f > 6000 then phase = "done" end
  if phase == "done" then
    -- back at the menu: 160A again (CTRL's read mode bits 0-1 = 0)
    print(string.format("result %d %d", matched, (mm:read_u8(0x2254) == 2 and 1 or 0)))
    manager:machine():exit()
  end
end)
