-- GRNK wiggles
-- envelopes for crow


local scope = {0,0,0,0}
local rate = {2,3,4,1}
local level = {2,3,4,3}
local type = {'LFO','LFO','LFO','AR'}
local selected = 1
local startup = true

function init()
  crow.input[1].mode('change',1,0.2,'rising')

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
  crow.output[4]()
end


function start_wiggling() -- Manully startup the LFOs
  crow.output[1].action = "lfo(dyn{rate="..rate[1].."},dyn{level="..level[1].."})"
  crow.output[1]()
  crow.output[2].action = "lfo(dyn{rate="..rate[2].."},dyn{level="..level[2].."})"
  crow.output[2]()
  crow.output[3].action = "lfo(dyn{rate="..rate[3].."},dyn{level="..level[3].."})"
  crow.output[3]()
  crow.output[4].action = "ar(0.01,dyn{rate="..rate[4].."},dyn{level="..level[4].."})"
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
    if selected == 1 then screen.level(15) else screen.level(3) end
    screen.move(10,8)
    screen.text_center(type[1])
    screen.move(10,30)
    screen.line_rel(0,scope[1]*-4)
    screen.stroke()
    screen.move(10,60)
    screen.text_center(string.format('%.1f',rate[1]))
  
    if selected == 2 then screen.level(15) else screen.level(3) end
    screen.move(45,8)
    screen.text_center(type[2])
    screen.move(45,30)
    screen.line_rel(0,scope[2]*-4)
    screen.stroke()
    screen.move(45,60)
    screen.text_center(string.format('%.1f',rate[2]))
  
    if selected == 3 then screen.level(15) else screen.level(3) end
    screen.move(77,8)
    screen.text_center(type[3])
    screen.move(77,30)
    screen.line_rel(0,scope[3]*-4)
    screen.stroke()
    screen.move(77,60)
    screen.text_center(string.format('%.1f',rate[3]))
  
    if selected == 4 then screen.level(15) else screen.level(3) end
    screen.move(110,8)
    screen.text_center(type[4])
    if type[4] == 'LFO' then
      screen.move(110,30)
      screen.line_rel(0,scope[4]*-4)
      screen.stroke()
    elseif type[4] == 'AR' then
      screen.move(110,49)
      screen.line_rel(0,scope[4]*-8)
      screen.stroke()
    end
    screen.move(110,60)
    screen.text_center(string.format('%.1f',rate[4]))
  end

  screen.update()
  screen_dirty = false
end

function enc(n,d)
  if n == 1 then
    selected = util.clamp(selected + d,1,4)
  elseif n == 2 then
    rate[selected] = util.clamp(rate[selected] + d/10,0.1,10)
    crow.output[selected].dyn.rate = rate[selected]
  elseif n == 3 then
    level[selected] = util.clamp(level[selected] + d/10,0.1,5)
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
      crow.output[selected]()
    elseif n==3 and z==1 then
      crow.output[selected]()
    end
  end
  screen_dirty = true
end


-- UTILITY TO RESTART SCRIPT FROM MAIDEN
function r()
  norns.script.load(norns.state.script)
end
