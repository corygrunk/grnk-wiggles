-- GRNK wiggles
-- envelopes for crow


local scope = {0,0,0,0}
local rate = {0.1,0.1,2,1}
local level = {1,1,8,8}
local type = {'AR','AR','LFO+','LFO'}
local selected = 1
local startup = true

function init()
  crow.input[1].mode('change',1,0.2,'rising')
  crow.input[2].mode('change',1,0.2,'rising')

  crow.output[1].receive = function(v) out(1,v) end
  crow.output[2].receive = function(v) out(2,v) end
  crow.output[3].receive = function(v) out(3,v) end
  crow.output[4].receive = function(v) out(4,v) end
  
  rt = metro.init() -- RATE
  rt.time = 0.05 
  rt.event = function()
    crow.output[1].query()
    crow.output[2].query()
    crow.output[3].query()
    crow.output[4].query()
    redraw()
  end
  rt:start()

  clock.run(redraw_clock)
  screen_dirty = true
end

function out(i,v)
  scope[i] = v
end

crow.input[1].change = function()
  crow.output[1]()
end

crow.input[2].change = function()
  crow.output[2]()
end


function start_wiggling() -- Manully startup the LFOs
  crow.output[1].action = "ar(dyn{rate="..rate[1].."},dyn{level="..level[1].."},8)"
  crow.output[1]()
  crow.output[2].action = "ar(dyn{rate="..rate[2].."},dyn{level="..level[2].."},8)"
  crow.output[2]()
  crow.output[3].action = "loop{ to( dyn{level="..level[3].."}, dyn{rate="..rate[3].."}), to(0, dyn{rate="..rate[3].."})}"
  crow.output[3]()
  crow.output[4].action = "lfo(dyn{rate="..rate[4].."},dyn{level="..level[4].."})"
  crow.output[4]()
end


function redraw_clock()
  while true do
    clock.sleep(1/15)
    if screen_dirty then
      redraw()
      screen_dirty = false
    end
  end
end

function redraw()
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)
  screen.clear()

  if startup then
    screen.move(60,30)
    screen.text_center('Press any key')
    screen.move(60,40)
    screen.text_center('to start wiggling')
  else
    for i = 1,4 do
      if selected == i then screen.level(15) else screen.level(3) end
      screen.move(10+(i-1)*33,8)
      screen.text_center(type[i])
      if type[i] == 'LFO+' then
        screen.move(10+(i-1)*33,40)
        screen.line_rel(0,scope[i]*-3.7)
      elseif type[i] == 'AR' then
        screen.move(10+(i-1)*33,40)
        screen.line_rel(0,scope[i]*-3.7)
      else
        screen.move(10+(i-1)*33,26)
        screen.line_rel(0,scope[i]*-2)
      end
      screen.stroke()
      screen.move(10+(i-1)*33,50)
      screen.text_center(string.format('%.1f',rate[i]))
      screen.move(10+(i-1)*33,60)
      screen.text_center(string.format('%.1f',level[i]))
    end
  end

  screen.update()
  screen_dirty = false
end

function enc(n,d)
  if n == 1 then
    selected = util.clamp(selected + d,1,4)
  elseif n == 2 then
    rate[selected] = util.clamp(rate[selected] + d/10,0.01,10)
    crow.output[selected].dyn.rate = rate[selected]
  elseif n == 3 then
    level[selected] = util.clamp(level[selected] + d/10,0.01,8)
    crow.output[selected].dyn.level = level[selected]
  end
  screen_dirty = true
end

function key(n,z)
  if startup and z==1 then
    start_wiggling()
    startup = false
  else
    if n==2 and z==1 then
      print('key 2')
    elseif n==3 and z==1 then
      print('key 3')
    end
  end
  screen_dirty = true
end


-- UTILITY TO RESTART SCRIPT FROM MAIDEN
function r()
  norns.script.load(norns.state.script)
end
