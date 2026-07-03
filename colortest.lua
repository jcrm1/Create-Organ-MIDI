local function run(side)
  local mask = 1
  for i = 1, 17, 1 do
    redstone.setBundledOutput(side, mask)
    mask = bit32.lshift(mask, 1)
    sleep(0.05)
  end
end
run("bottom")
run("front")
run("top")
run("left")
run("back")
run("right")
