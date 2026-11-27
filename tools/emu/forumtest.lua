-- The evening, played by a bot (tools/test_forum.sh), one day a run (DAY):
-- from the menu, the forum; open the release thread, download the slop ROM,
-- break it (steering under the ball, as breaktest.lua), on to the review.
-- The review: day 3 picks the last phrase in every slot (left: they wrap),
-- the constructive ones; other days take the first. Post it, see the
-- thread (Arthur's review and the reply), back to the list, log off.
-- Prints "result posted kind back_at_menu".
-- RAM: sCTRL $2107 (%01000011 the 40-column screens, %01010000 160A),
-- pady $E6, bally $E9, combo $ED, glitch $F8, lostt $2208, padlen $220A, rev_done $2709, rev_kind $270C.
local fields = {}
for tag, port in pairs(manager:machine():ioport().ports) do
  for name, field in pairs(port.fields) do fields[name] = field end
end
local function m() return manager:machine().devices[":maincpu"].spaces["program"] end
local U, D, L, R, A, B = "P1 Up", "P1 Down", "P1 Left", "P1 Right", "P1 Button 1", "P1 Button 2"
local day = tonumber(os.getenv("DAY") or "1")
local MENU = {"WAIT", D, D, D}
for i = 2, day do table.insert(MENU, R) end
table.insert(MENU, A)
local REVIEW = day == 3 and {"WAIT", L, D, L, D, L, "SNAP", A} or {"WAIT", "SNAP", A}
local queue, f, phase, t0, gl = {}, 0, "boot", 0, nil
local function push(list) for _, a in ipairs(list) do table.insert(queue, a) end end
local cur, hold, sw = nil, 0, 0
local function snap() manager:machine().screens[":screen"]:snapshot() end
emu.register_frame_done(function()
  f = f + 1
  local mm = m()
  local held = {}
  local ctrl = mm:read_u8(0x2107)
  local idle = #queue == 0 and cur == nil
  if phase == "boot" and f == 200 then push(MENU); phase = "forum"
  elseif phase == "forum" and idle and ctrl == 0x43 then
    push({"WAIT", "SNAP", A, "WAIT", "SNAP", A}); phase = "download"
  elseif phase == "download" and idle and ctrl == 0x50 then
    push({"WAIT", "WAIT", A}); phase = "play"; t0 = f
  elseif phase == "play" and idle and f > t0 + 10 then
    local pady, bally = mm:read_u8(0xE6), mm:read_u8(0xE9)
    if not gl then
      local want = bally - 11
      if pady < want - 1 then held[D] = true elseif pady > want + 1 then held[U] = true end
      -- day 3 crashes by the left difficulty switch: flip it (after 4 hits,
      -- so the score's gone past 9 too)
      if day == 3 and mm:read_u8(0xED) >= 16 and f % 20 == 0 then sw = 1 - sw end
      local crashed = mm:read_u8(0xF8) ~= 0 or (day == 2 and mm:read_u8(0x2208) ~= 0)
        or (day == 3 and mm:read_u8(0x220A) > 160)
      if crashed then gl = f; print(string.format("day %d: the slop ROM crashed", day)) end
    elseif f == gl + 300 then push({A}); phase = "review"
    end
  elseif phase == "review" and idle and ctrl == 0x43 then
    push(REVIEW); phase = "posted"; t0 = f
  elseif phase == "posted" and idle and f > t0 + 20 then
    print(string.format("day %d: posted, %d kind", day, mm:read_u8(0x270C + day - 1)))
    push({"WAIT", "SNAP", D, "WAIT", "SNAP", B, "WAIT", "SNAP", B}); phase = "leave"
  elseif phase == "leave" and idle then
    push({"WAIT", "WAIT"}); phase = "done"
  end
  if cur == nil and #queue > 0 then cur = table.remove(queue, 1); hold = 0 end
  if cur then
    hold = hold + 1
    if cur == "SNAP" then snap(); cur = nil
    elseif cur == "WAIT" then if hold > 30 then cur = nil end
    else
      if hold <= 3 then held[cur] = true end
      if hold >= 8 then cur = nil end
    end
  end
  for name, field in pairs(fields) do
    if name:match("^P1 ") then field:set_value(held[name] and 1 or 0) end
  end
  fields["Left Difficulty Switch"]:set_value(sw)
  if f > 12000 then phase = "done"; print("timed out in " .. phase) end
  if phase == "done" and #queue == 0 and cur == nil then
    print(string.format("result %d %d %d", mm:read_u8(0x2709 + day - 1), mm:read_u8(0x270C + day - 1),
      ctrl == 0x50 and 1 or 0))
    manager:machine():exit()
  end
end)
