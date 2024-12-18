-- GRNK wiggles
-- envelopes for crow

local scope = {0,0,0,0}
local rate = {1,1,1,1}
local level = {8,8,8,8}
local attack = {0.01,0.01,0.01,0.01}
local decay = {0.5,0.5,0.5,0.5}
local types_env = {'AR','LFO'}
local type_switch = 1 -- THIS IS A TERRIBLE NAME - I'm using this to switch between AR and LFO
local type = {types_env[1],types_env[2],types_env[2],'CLK'}

local counter = 0

local selected = 1

local clock_on = false
local tempo = 0
local alt_mode = false

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

  for i = 1,3 do
    if type[i] == 'AR' then
      crow.output[i].action = "ar(dyn{attack="..attack[i].."},dyn{decay="..decay[i].."},dyn{level="..level[i].."},'expo')"
    else
      crow.output[i].action = "loop{ to( dyn{level="..level[i].."}, dyn{rate="..rate[i].."}), to(0, dyn{rate="..rate[i].."})}"
      crow.output[i]()
    end
  end
  crow.output[4].action = "pulse()"

  tempo = clock.get_tempo()
  clock.run(clk)
  clock.run(redraw_clock)
  screen_dirty = true
end

function out(i,v)
  scope[i] = v
end

crow.input[1].change = function()
  if type[1] == 'AR' then
    crow.output[1]()
  end
end

crow.input[2].change = function()
  if type[2] == 'AR' then
    crow.output[2]()
  end
end

function clk() -- draw the tempo square
  while true do
    tempo = clock.get_tempo()
    clock.sync(1/2)
    if counter % 8 == 0 then
      if type[3] == 'AR' then
        crow.output[3]()
      end
    end
    counter = counter + 1
    if clock_on then clock_on = false else clock_on = true end
    screen_dirty = true
  end
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
  screen.clear()

  for i = 1,4 do
    screen.line_width(1)
    if selected == i then screen.level(15) else screen.level(3) end
    -- bipolar lfo
    screen.move(10+(i-1)*33,8)
    screen.text_center(type[i])
    if alt_mode == true and selected == i and type[i] == 'AR' then
      screen.move(10+(i-1)*33,40)
      screen.text_center(string.format('%.2f',level[i]))
    end
    if type[i] == 'LFO' then
      screen.move(10+(i-1)*33,40)
      screen.line_rel(0,scope[i]*-3.5)
    elseif type[i] == 'AR' then
      screen.move(10+(i-1)*33,40)
      screen.line_rel(0,scope[i]*-3.5)
    elseif type[i] == 'CLK' then
      screen.line_width(6)
      screen.move(10+(i-1)*33,27)
      if clock_on then screen.line_rel(0,6) else screen.line_rel(0,0) end
      -- screen.line_rel(0,scope[i])
    else
      screen.move(10+(i-1)*33,26)
      screen.line_rel(0,scope[i]*-2)
    end
    screen.stroke()

    if type[i] == 'CLK' then
      screen.move(10+(i-1)*33,60)
      screen.text_center(tempo)
    else
      if type[i] == 'AR' then
        screen.move(10+(i-1)*33,50)
        screen.text_center(string.format('%.2f',attack[i]))
        screen.move(10+(i-1)*33,60)
        screen.text_center(string.format('%.2f',decay[i]))
      else -- LFO
        screen.move(10+(i-1)*33,50)
        screen.text_center(string.format('%.2f',rate[i]))
        screen.move(10+(i-1)*33,60)
        screen.text_center(string.format('%.2f',level[i]))
      end
    end
  end

  screen.update()
  screen_dirty = false
end

function enc(n,d)
  if n == 1 then
    selected = util.clamp(selected + d,1,3)
  elseif n == 2 and alt_mode == false and type[selected] ~= 'AR' then -- NOT AR meaning LFO
    rate[selected] = util.clamp(rate[selected] + d/10,0.01,10)
    crow.output[selected].dyn.rate = rate[selected]
  elseif n == 2 and alt_mode == false then
    attack[selected] = util.clamp(attack[selected] + d/10,0.01,10) -- AR ATTACK
    crow.output[selected].dyn.attack = attack[selected]
  elseif n == 2 and alt_mode == true then
    level[selected] = util.clamp(level[selected] + d/10,0.01,8) -- AR LEVEL
    crow.output[selected].dyn.level = level[selected]
  elseif n == 3 and alt_mode == false and type[selected] ~= 'AR' then -- NOT AR meaning LFO
    level[selected] = util.clamp(level[selected] + d/10,0.01,8)
    crow.output[selected].dyn.level = level[selected]
  elseif n == 3 and alt_mode == false then
    decay[selected] = util.clamp(decay[selected] + d/10,0.01,10) -- AR DECAY
    crow.output[selected].dyn.decay = decay[selected]
  elseif n == 3 and alt_mode == true then
    type_switch = util.clamp(type_switch + d,1,2) -- TYPE OF ENV
    type[selected] = types_env[type_switch]
    if type[selected] == 'LFO' then
      crow.output[selected].action = "loop{ to( dyn{level="..level[selected].."}, dyn{rate="..rate[selected].."}), to(0, dyn{rate="..rate[selected].."})}"
      crow.output[selected]()
    else
      crow.output[selected].action = "ar(dyn{attack="..attack[selected].."},dyn{decay="..decay[selected].."},dyn{level="..level[selected].."},'expo')"
    end
  end
  screen_dirty = true
end

function key(n,z)
  if n == 1 and z == 1 then
    alt_mode = true
  elseif n == 1 and z == 0 then
    alt_mode = false
  elseif n==2 and z==1 and type[selected] == 'AR' then
    crow.output[1]()
  elseif n==3 and z==1 and type[selected] == 'AR' then
    crow.output[2]()
  end
  screen_dirty = true
end


-- UTILITY TO RESTART SCRIPT FROM MAIDEN
function r()
  norns.script.load(norns.state.script)
end
