-- SUPER PADDLE BALL DELUXE: break it. Starts the game, then steers the
-- paddle under the ball; every hit doubles the combo until the one-byte
-- score and combo overflow. Prints each score change, takes screenshots
-- (just after the 4th hit: the zone bugs; the glitch; the crash; the
-- review), and prints "result" with the frames it took and seenbugs.
-- tools/test_break.sh
--
-- RAM (build/work/myac.bas.symbol.txt): pady $E6, ballx $E8, bally $E9,
-- balldx $EA, score $EC, combo $ED, glitch $F8, seenbugs $0172.
local fields = {}
for tag, port in pairs(manager:machine():ioport().ports) do
  for name, field in pairs(port.fields) do fields[name] = field end
end
local function m() return manager:machine().devices[":maincpu"].spaces["program"] end
local f, start, gl, lastscore, hits, hit4 = 0, 300, nil, -1, 0, nil
local edge = os.getenv("EDGE") or "middle"
emu.register_frame_done(function()
  f = f + 1
  local mm = m()
  local held = {}
  -- the menu's first item (SUPER PADDLE BALL), then the slop title
  if f >= 230 and f < 234 then held["P1 Button 1"] = true end
  if f >= start and f < start + 4 then held["P1 Button 1"] = true end
  if f > start + 10 and not gl then
    local pady, bally = mm:read_u8(0xE6), mm:read_u8(0xE9)
    -- the ball's line 6 meets the paddle's line 4 (top), 17 or 30 (bottom)
    local want = bally - 11
    if edge == "top" then want = bally + 2 elseif edge == "bottom" then want = bally - 24 end
    if pady < want - 1 then held["P1 Down"] = true elseif pady > want + 1 then held["P1 Up"] = true end
    local score = mm:read_u8(0xEC)
    if score ~= lastscore then
      print(string.format("frame %d: score %d combo %d", f, score, mm:read_u8(0xED)))
      if lastscore >= 0 then hits = hits + 1 end
      if hits == 4 then hit4 = f end
      lastscore = score
    end
    if mm:read_u8(0xF8) ~= 0 then
      gl = f
      print(string.format("frame %d: glitch (score wrapped to %d)", f, score))
    end
  end
  if gl and f >= gl + 300 and f < gl + 304 then held["P1 Button 1"] = true end
  for name, field in pairs(fields) do
    if name:match("^P1 ") then field:set_value(held[name] and 1 or 0) end
  end
  if (hit4 and f == hit4 + 4) or (gl and (f == gl + 40 or f == gl + 260 or f == gl + 330)) then
    manager:machine().screens[":screen"]:snapshot()
  end
  if gl and f == gl + 340 then
    print(string.format("result %d %d", gl - start, mm:read_u8(0x0172)))
    manager:machine():exit()
  end
  if f > 20000 then print("result -1"); manager:machine():exit() end
end)
