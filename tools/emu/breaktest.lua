-- SUPER PADDLE BALL DELUXE: break it. Starts the game, then steers the
-- paddle so the ball lands on its top edge every time, which doubles the
-- combo until the one-byte score overflows. Prints each score change, takes
-- screenshots of the glitch and the crash, and prints "result" with the
-- frames it took. tools/test_break.sh
--
-- RAM (build/work/myac.bas.symbol.txt): pady $E6, ballx $E8, bally $E9,
-- balldx $EA, score $EC, combo $ED, glitch $F8.
local fields = {}
for tag, port in pairs(manager:machine():ioport().ports) do
  for name, field in pairs(port.fields) do fields[name] = field end
end
local function m() return manager:machine().devices[":maincpu"].spaces["program"] end
local f, start, gl, lastscore = 0, 200, nil, -1
local edge = os.getenv("EDGE") or "top"
emu.register_frame_done(function()
  f = f + 1
  local mm = m()
  local held = {}
  if f >= start and f < start + 4 then held["P1 Button 1"] = true end
  if f > start + 10 and not gl then
    local pady, bally = mm:read_u8(0xE6), mm:read_u8(0xE9)
    -- the ball's line 6 meets the paddle's line 4 (top) or 30 (bottom)
    local want = (edge == "top") and (bally + 2) or (bally - 24)
    if pady < want - 1 then held["P1 Down"] = true elseif pady > want + 1 then held["P1 Up"] = true end
    local score = mm:read_u8(0xEC)
    if score ~= lastscore then
      print(string.format("frame %d: score %d combo %d", f, score, mm:read_u8(0xED)))
      lastscore = score
    end
    if mm:read_u8(0xF8) ~= 0 then
      gl = f
      print(string.format("frame %d: glitch (score wrapped to %d)", f, score))
    end
  end
  for name, field in pairs(fields) do
    if name:match("^P1 ") then field:set_value(held[name] and 1 or 0) end
  end
  if gl and (f == gl + 40 or f == gl + 260) then manager:machine().screens[":screen"]:snapshot() end
  if gl and f == gl + 300 then
    print(string.format("result %d", gl - start))
    manager:machine():exit()
  end
  if f > 20000 then print("result -1"); manager:machine():exit() end
end)
