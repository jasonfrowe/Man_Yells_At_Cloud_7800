-- The mirror, played by a bot (tools/test_mirror.sh): the menu's fifth item;
-- the intro; through the living room's TV to the hub; talk pixelkid into
-- joining; player 2 joins (joystick 2's fire) and takes pixelkid to one
-- plate while Arthur stands on the other: the door opens; through a TV to
-- Hal's arcade, and the rally, both paddles steered, to 20.
-- Prints "result kmode door cards".
-- RAM (src/mirror.bas, src/asm/mirror.asm): ax $2200 kx $2201 ay $2202
-- ky $2203 room $2209 talk pages left $220E kmode $221A hits $2268
-- hy $2269 rpady $226A rby $226C cards $2710 door $2711
local fields = {}
for tag, port in pairs(manager:machine():ioport().ports) do
  for name, field in pairs(port.fields) do fields[name] = field end
end
local function m() return manager:machine().devices[":maincpu"].spaces["program"] end
local function snap() manager:machine().screens[":screen"]:snapshot() end
-- the plan: one step at a time
local plan = {
  {"wait", 200}, {"press", "P1 Down"}, {"press", "P1 Down"}, {"press", "P1 Down"}, {"press", "P1 Down"},
  {"snap"}, {"press", "P1 Button 1"}, {"wait", 30}, {"snap"}, {"talk"}, {"snap"},
  -- the living room's TV (column 8, row 3): stand below it, face it
  {"x", 0, 96}, {"y", 0, 60}, {"x", 0, 64}, {"press", "P1 Up"}, {"press", "P1 Button 1"}, {"wait", 20},
  {"room", 1}, {"snap"}, {"talk"},
  -- pixelkid, hiding at (8, 92) between the racks
  {"y", 0, 92}, {"x", 0, 16}, {"press", "P1 Left"}, {"press", "P1 Button 1"}, {"wait", 10}, {"snap"}, {"talk"},
  {"kmode", 1}, {"snap"},
  -- player 2
  {"press", "P2 Button 1"}, {"wait", 10}, {"talk"}, {"kmode", 3},
  -- pixelkid to the plate at (3, 9), Arthur to the one at (13, 4)
  {"x", 1, 24}, {"y", 1, 140}, {"x", 0, 104}, {"y", 0, 66}, {"wait", 10}, {"snap"}, {"talk"}, {"door"}, {"snap"},
  -- Hal's TV (column 8, row 2)
  {"y", 0, 44}, {"x", 0, 64}, {"press", "P1 Up"}, {"press", "P1 Button 1"}, {"wait", 20}, {"room", 3}, {"snap"},
  {"y", 0, 92}, {"press", "P1 Up"}, {"press", "P1 Button 1"}, {"wait", 10}, {"snap"}, {"talk"},
  {"rally"}, {"wait", 20}, {"snap"}, {"talk"}, {"snap"},
  -- back to the hub, then Sue's room and Maria's
  {"y", 0, 140}, {"press", "P1 Down"}, {"press", "P1 Button 1"}, {"wait", 20}, {"room", 1},
  {"x", 0, 32}, {"press", "P1 Up"}, {"press", "P1 Button 1"}, {"wait", 20}, {"room", 2},
  {"y", 0, 92}, {"press", "P1 Up"}, {"press", "P1 Button 1"}, {"wait", 10}, {"snap"}, {"talk"},
  {"y", 0, 140}, {"press", "P1 Down"}, {"press", "P1 Button 1"}, {"wait", 20}, {"room", 1},
  {"x", 0, 96}, {"press", "P1 Up"}, {"press", "P1 Button 1"}, {"wait", 20}, {"room", 4},
  {"y", 0, 102}, {"press", "P1 Up"}, {"press", "P1 Button 1"}, {"wait", 10}, {"snap"}, {"talk"}, {"snap"},
  {"done"},
}
local step, f, t0, hold, quiet = 1, 0, 0, 0, 0
local AX = {[0] = 0x2200, [1] = 0x2201}
local AY = {[0] = 0x2202, [1] = 0x2203}
emu.register_frame_done(function()
  f = f + 1
  local mm = m()
  local held = {}
  local s = plan[step]
  local nextstep = false
  if s[1] == "wait" then
    if f - t0 >= s[2] then nextstep = true end
  elseif s[1] == "press" then
    if f - t0 < 4 then held[s[2]] = true elseif f - t0 > 10 then nextstep = true end
  elseif s[1] == "snap" then snap(); nextstep = true
  elseif s[1] == "talk" then
    -- press button 1 until the talk's done
    -- (talks can follow one another: done once none's started for 40 frames)
    if mm:read_u8(0x220E) == 0 then quiet = quiet + 1 else quiet = 0 end
    if quiet > 40 and f - t0 > 20 then nextstep = true
    elseif quiet == 0 and (f - t0) % 16 < 3 then held["P1 Button 1"] = true end
  elseif s[1] == "x" or s[1] == "y" then
    local who, want = s[2], s[3]
    local p = who == 0 and "P1 " or "P2 "
    local v = mm:read_u8(s[1] == "x" and AX[who] or AY[who])
    if v == want then nextstep = true
    elseif s[1] == "x" then held[p .. (v < want and "Right" or "Left")] = true
    else held[p .. (v < want and "Down" or "Up")] = true end
    if f - t0 > 600 then print(string.format("stuck: step %d at %d (want %d)", step, v, want)); s = {"done"} ; step = #plan end
  elseif s[1] == "room" then
    if mm:read_u8(0x2209) == s[2] then nextstep = true end
  elseif s[1] == "kmode" then
    if mm:read_u8(0x221A) == s[2] then nextstep = true end
  elseif s[1] == "door" then
    if mm:read_u8(0x2711) == 1 then nextstep = true end
  elseif s[1] == "rally" then
    local rby, rp, hy = mm:read_u8(0x226C), mm:read_u8(0x226A), mm:read_u8(0x2269)
    local want = rby - 11
    if rp < want - 2 then held["P1 Down"] = true elseif rp > want + 2 then held["P1 Up"] = true end
    if hy < want - 2 then held["P2 Down"] = true elseif hy > want + 2 then held["P2 Up"] = true end
    if (mm:read_u8(0x2710) & 2) ~= 0 or mm:read_u8(0x220E) ~= 0 then nextstep = true end
    if f - t0 == 400 then snap() end
  elseif s[1] == "done" then
    print(string.format("result %d %d %d", mm:read_u8(0x221A), mm:read_u8(0x2711), mm:read_u8(0x2710)))
    manager:machine():exit()
  end
  if f - t0 > 3000 and s[1] ~= "done" then print("timed out at step " .. step); step = #plan; t0 = f end
  if nextstep then
    print(string.format("frame %d: step %d %s done", f, step, s[1]))
    step = step + 1; t0 = f; quiet = 0
  end
  for name, field in pairs(fields) do
    if name:match("^P[12] ") then field:set_value(held[name] and 1 or 0) end
  end
end)
