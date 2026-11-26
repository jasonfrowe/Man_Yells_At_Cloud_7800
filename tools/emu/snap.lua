-- Take screenshots at the frames listed in SNAP_FRAMES (comma separated),
-- then exit after the last one. Used by tools/snap.sh.
--
-- POKES (optional): "frame:addr:value,..." (hex addr/value) writes memory
--   at those frames, e.g. "300:2502:0C" to solo POKEY 2 in the music mask.
-- INPUTS (optional): "from-to:Field Name;..." holds a control down over a
--   frame range, e.g. "300-305:P1 Button 1;400-900:P1 Right".
-- WAVELOG (optional): energy held full; prints each change of game state or
--   song with the pirate slots (tools/test_waves.sh).
-- AUTOPLAY (optional, a frame): from then on, aim at the nearest rock and
--   fire (deep space, space.asm's tables). Prints the wave, score and
--   energy every 600 frames.
local frames = {}
local last = 0
for n in string.gmatch(os.getenv("SNAP_FRAMES") or "120", "%d+") do
  frames[tonumber(n)] = true
  if tonumber(n) > last then last = tonumber(n) end
end
local pokes = {}
for fr, a, v in string.gmatch(os.getenv("POKES") or "", "(%d+):(%x+):(%x+)") do
  table.insert(pokes, {tonumber(fr), tonumber(a, 16), tonumber(v, 16)})
end
local inputs = {}
for a, b, name in string.gmatch(os.getenv("INPUTS") or "", "(%d+)-(%d+):([^;]+)") do
  table.insert(inputs, {tonumber(a), tonumber(b), name})
end
local autoplay = tonumber(os.getenv("AUTOPLAY") or "")
-- AUTOFIGHTER (optional, a frame): from then on, launch the fighter and fly
-- it at the nearest pirate (or pod), firing when lined up. Logs kills.
local autofighter = tonumber(os.getenv("AUTOFIGHTER") or "")
-- AUTOPLANET (optional, a frame): on a planet, fly over the nearest creature,
-- go down, beam it up, climb into the Ark. Logs the planet's state.
local autoplanet = tonumber(os.getenv("AUTOPLANET") or "")

local fields = {}
for tag, port in pairs(manager:machine():ioport().ports) do
  for name, field in pairs(port.fields) do fields[name] = field end
end

local function mem() return manager:machine().devices[":maincpu"].spaces["program"] end

-- the nearest rock's direction (0 up, clockwise) from the Ark's centre
local DIRS = {}
local function aim()
  local m = mem()
  local best, bd = nil, 1e9
  for i = 0, 9 do
    local t = m:read_u8(0x2300 + i)
    if t >= 1 and t <= 3 then
      local dx = (m:read_u8(0x230A + i) + 4 - 80) * 2
      local dy = m:read_u8(0x231E + i) + 6 - 95
      local d = dx * dx + dy * dy
      if d < bd then bd, best = d, {dx, dy} end
    end
  end
  for i = 0, 5 do                               -- pirates and missiles
    local t = m:read_u8(0x2460 + i)
    if t >= 1 and t <= 3 then
      local dx = (m:read_u8(0x2466 + i) - 80) * 2
      local dy = m:read_u8(0x2472 + i) - 95
      local d = dx * dx + dy * dy
      if d < bd then bd, best = d, {dx, dy} end
    end
  end
  if not best then return nil end
  local a = math.atan(best[1], -best[2])       -- 0 = up, clockwise
  return math.floor((a / (2 * math.pi) * 8 + 8.5)) % 8
end
local DIRF = {
  [0] = {"P1 Up"}, {"P1 Up", "P1 Right"}, {"P1 Right"}, {"P1 Down", "P1 Right"},
  {"P1 Down"}, {"P1 Down", "P1 Left"}, {"P1 Left"}, {"P1 Up", "P1 Left"},
}

local f = 0
emu.register_frame_done(function()
  f = f + 1
  for _, p in ipairs(pokes) do
    if p[1] == f then mem():write_u8(p[2], p[3]) end
  end
  local held = {}
  for _, i in ipairs(inputs) do
    if f >= i[1] and f <= i[2] then held[i[3]] = true end
  end
  if autoplay and f >= autoplay then
    local d = aim()
    if d then
      for _, n in ipairs(DIRF[d]) do held[n] = true end
      held["P1 Button 1"] = (f % 2) == 0
    end
    -- the game loop's pace: frames in which it ran (60 a second = full speed)
    local t = mem():read_u8(0x239F)
    if t ~= lastticks then ran = (ran or 0) + 1 end
    lastticks = t
    local live = 0
    for i = 0, 9 do if mem():read_u8(0x2300 + i) > 0 then live = live + 1 end end
    maxlive = math.max(maxlive or 0, live)
    if f % 600 == 0 then
      local m = mem()
      print(string.format("frame %d: wave %d score %02X%02X%02X energy %d state %d; loop ran %d/600 frames, most rocks %d",
        f, m:read_u8(0x238A), m:read_u8(0x2387), m:read_u8(0x2388), m:read_u8(0x2389),
        m:read_u8(0x2386), m:read_u8(0x238C), ran or 0, maxlive))
      ran, maxlive = 0, 0
    end
  end
  if autofighter and f >= autofighter then
    local m = mem()
    local st = m:read_u8(0x2400)
    if st == 0 and m:read_u8(0x240C) >= 40 and f % 20 == 0 then held["P1 Button 2"] = true end
    if st == 1 then
      local fx, fy, ah = m:read_u8(0x2401), m:read_u8(0x2403), m:read_u8(0x240A)
      local best, bd, ispod
      for i = 0, 5 do
        local t = m:read_u8(0x2460 + i)
        if t >= 1 and t <= 3 then
          local dx, dy = (m:read_u8(0x2466 + i) - fx) * 2, m:read_u8(0x2472 + i) - fy
          local d = dx * dx + dy * dy
          if not bd or d < bd then bd, best, ispod = d, {dx, dy}, false end
        end
      end
      for i = 0, 1 do
        if m:read_u8(0x24AE + i) > 0 then
          local dx, dy = (m:read_u8(0x24B0 + i) - fx) * 2, m:read_u8(0x24B4 + i) - fy
          local d = dx * dx + dy * dy
          if not bd or d < bd then bd, best, ispod = d, {dx, dy}, true end
        end
      end
      if best then
        -- point the stick at it (8 ways), fire when the nose is round
        local d = math.floor((math.atan(best[1], -best[2]) / (2 * math.pi) * 8 + 8.5)) % 8
        if bd > 300 or ispod then for _, n in ipairs(DIRF[d]) do held[n] = true end end
        local want = (0xC0 + d * 0x20) % 256
        local diff = (want - ah + 128) % 256 - 128
        if not ispod and math.abs(diff) < 20 then held["P1 Button 1"] = true
          for _, n in ipairs(DIRF[d]) do held[n] = true end end
      end
    end
    if f % 600 == 0 then
      local m2 = mem()
      print(string.format("frame %d: fighter state %d tether %d; Ark energy %d; pirates %d; score %02X%02X%02X",
        f, st, m2:read_u8(0x240C), m2:read_u8(0x2386), m2:read_u8(0x24E9),
        m2:read_u8(0x2387), m2:read_u8(0x2388), m2:read_u8(0x2389)))
    end
  end
  if autoplanet and f >= autoplanet then
    local m = mem()
    local wx = m:read_u8(0x2700) + 256 * m:read_u8(0x2701)
    local sy, hold, st = m:read_u8(0x2707), m:read_u8(0x270A), m:read_u8(0x2709)
    local function toward(tx)
      local dx = (tx - wx + 512) % 1024 - 512
      if dx > 2 then held["P1 Right"] = true elseif dx < -2 then held["P1 Left"] = true end
      return dx
    end
    if hold > 0 or m:read_u8(0x2716) == m:read_u8(0x2717) then
      -- home: to the Ark's spot, then up into it
      -- up the tube to the top, then let go of up: docked
      if math.abs(toward(512)) <= 6 and sy > 58 then held["P1 Up"] = true end
    else
      local best, bd, by, bstun
      for i = 0, 3 do
        local t, cs = m:read_u8(0x2720 + i), m:read_u8(0x2740 + i)
        if t > 0 and cs ~= 4 and cs ~= 3 then
          local cx = m:read_u8(0x2724 + i) + 256 * m:read_u8(0x2728 + i) + 4
          local dx = (cx - wx + 512) % 1024 - 512
          if not bd or math.abs(dx) < math.abs(bd) then
            bd, best, by, bstun = dx, i, m:read_u8(0x2730 + i), m:read_u8(0x2748 + i)
          end
        end
      end
      if best then
        if st == 0 then held["P1 Down"] = true
        elseif m:read_u8(0x2740 + best) == 2 then held["P1 Button 1"] = true   -- lifting: hold on
        else
          if math.abs(bd) > 3 then toward((wx + bd) % 1024) end
          if math.abs(bd) < 40 and sy < by - 14 and sy >= 72 then held["P1 Down"] = true end
        if math.abs(bd) < 40 and sy < 104 then held["P1 Down"] = true end   -- low enough to beam
        if sy < 72 then held["P1 Down"] = true end                        -- out of the tube
          if math.abs(bd) <= 3 then
            held["P1 Button 1"] = true                                    -- the beam
          end
        end
      end
    end
    if f % 300 == 0 then
      print(string.format("frame %d: planet state %d, time %d, caught %d/%d, hold %d, shuttle y %d, Ark energy %d",
        f, m:read_u8(0x2714), m:read_u8(0x2712), m:read_u8(0x2716), m:read_u8(0x2717), hold, sy, m:read_u8(0x2386)))
    end
  end
  for name, field in pairs(fields) do
    if name:match("^P1 ") or name == "Select" then field:set_value(held[name] and 1 or 0) end
  end
  if os.getenv("NOPLANET") then mem():write_u8(0x23EF, 1) end
  if os.getenv("NOPLANET") or os.getenv("AUTOPLAY") or os.getenv("TESTMODE") then mem():write_u8(0x259F, 1) end
  if os.getenv("WAVELOG") and f > 330 then
    local m = mem()
    m:write_u8(0x2386, 96)
    local st, song = m:read_u8(0x238C), m:read_u8(0x24FF)
    if st ~= (laststate or -1) or song ~= (lastsong or -1) then
      local p = ""
      for i = 0, 5 do p = p .. m:read_u8(0x2460 + i) .. " " end
      print(string.format("frame %d: wave %d state %d song %d | pirate slots %s| pr_live %d pending %d/%d window %d rocks %d left %d",
        f, m:read_u8(0x238A), st, song, p, m:read_u8(0x24E9), m:read_u8(0x24C1), m:read_u8(0x24C2),
        m:read_u8(0x24F0), m:read_u8(0x2394), m:read_u8(0x238E)))
      laststate, lastsong = st, song
    end
  end
  if frames[f] then manager:machine().screens[":screen"]:snapshot() end
  if f > last then manager:machine():exit() end
end)
