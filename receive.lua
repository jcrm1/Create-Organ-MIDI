local channel, message
while true do
  _, _, channel, _, message, _ = os.pullEvent("modem_message")
  if channel == 13 then
    redstone.setBundledOutput("bottom", message)
    print("got msg 13")
  elseif channel == 14 then
    redstone.setBundledOutput("left", message)
    print("got msg 14")
  end
end
