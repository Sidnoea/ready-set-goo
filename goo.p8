pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--ready, set, goo!
--by sidnoea and huntclaw
cartdata("ready_set_goo")

--animation stuff
function add_spr(name, anim)
  sprites[name] = {["a"]=anim, ["s"]=1}
end

function get_spr(name)
  local sprite = sprites[name]
  return sprite.a[sprite.s]
end

function inc_anim(sprite)
  sprite.s = (sprite.s%(#sprite.a))+1
end

bg = 0

--animations {frame1, frame2...}
slime_a = {0,0,2,2,4,4,6,6,4,4,2,2}
slime_die_a = {18,18,18,18,20,20,20,20,22,22,22,22,24,24,24,24,26,26,26,26}
fire_a = {32,32,32,33,33,33,34,34,34,35,35,35}
fire_die_a = {38,38,38,39,39,39,40,40,41,41,42,42,43,43,44,44}
mouth_a = {66,66,66,66,66,66,66,66,66,66,70,70,74,74,74,74,74,74,74,74,74,74,70,70}
mouth_die_a = {70,70,70,98,98,98,102,106,106,106,128,128,128,132,132,132}
lemon_die_a = {12,12,12,12,12,12,12,13,13,13,13,13,13,13}
rainbow_a = {49,49,51,51,53,53,55,55,57,57,59,59}
splat_a = {31,31,31,31,31,31}

sprites = {}
add_spr("slime", slime_a)
add_spr("fire", fire_a)
add_spr("mouth", mouth_a)
add_spr("rainbow", rainbow_a)

--add_spr("mouth_die", mouth_die_a)
--add_spr("lemon_die", lemon_die_a)

--hitbox stuff
function make_hit(x1, y1, x2, y2)
  return {["x1"]=x1, ["y1"]=y1, ["x2"]=x2, ["y2"]=y2}
end

function flip_hit(hit, height)
  --flips hitbox vertically
  local y1 = height-hit.y2-1
  local y2 = height-hit.y1-1
  return make_hit(hit.x1, y1, hit.x2, y2)
end

function make_rect(hit, x, y)
  local x1 = hit.x1+x
  local y1 = hit.y1+y
  local x2 = hit.x2+x
  local y2 = hit.y2+y
  return make_hit(x1, y1, x2, y2)
end

function get_rect(object)
  local n = object.n
  if n == "fire" or n == "fire2" then
    return make_rect(fire_h, object.x, object.y)
  elseif n == "lemon" then
    return make_rect(lemon_h, object.x, object.y)
  elseif n == "mouth" then
    local h
    local sprite = get_spr("mouth")
    if sprite == 66 then
      h = mouth_open_h
    elseif sprite == 70 then
      h = mouth_mid_h
    else
      h = mouth_close_h
    end
    if object.surface == "g" then
      return make_rect(h, object.x, object.y)
    else
      return make_rect(flip_hit(h, 16), object.x, object.y)
    end
  elseif n == "apple" then
    return make_rect(apple_h, object.x, object.y)
  elseif n == "banana" or n == "shield" then
    return make_rect(banana_h, object.x, object.y)
  elseif n == "rainbow" or n == "rapid" then
    return make_rect(bottle_h, object.x, object.y)
  elseif n == "orange" or n == "barrage" then
    return make_rect(orange_h, object.x, object.y)
  elseif n == "bullet" then
    return make_rect(bullet_h, object.x, object.y)
  end
end

function collide(r1, r2)
  if r1.x2 < r2.x1 or r1.x1 > r2.x2 or r1.y2 < r2.y1 or r1.y1 > r2.y2 then
    return false
  end
  return true
end

--hitboxes (x1, y1, x2, y2)
slime_h = make_hit(4,2,11,7)
slime_air_h = make_hit(4,0,11,7)
rainbow_h = make_hit(0,0,15,7)
lemon_h = make_hit(0,3,7,7)
mouth_open_h = make_hit(0,7,31,15)
mouth_mid_h = make_hit(1,1,30,15)
mouth_close_h = make_hit(6,0,25,15)
fire_h = make_hit(1,0,6,7)
apple_h = make_hit(0,0,7,7)
bullet_h = make_hit(1,5,6,7)
bottle_h = make_hit(0,0,7,7)
banana_h = make_hit(1,0,7,7)
orange_h = make_hit(0,0,7,7)

--constants
ground = 112
ceil = 64
edge = 128
enemy_rate = 1/24
apple_rate = 1/1000
banana_rate = 1/4000
rainbow_rate = 1/10000
rapid_rate = 1/4000
orange_rate = 1/4000
heights = {64,72,80,88,96,104,112} --fire heights
iframes = 60 --2 secs
rainbow_time = 300 --10 secs
rapid_time = 450 --15 secs
shield_time = 600 --20 secs
barrage_count = 10

--slime stuff
x = 8
y = ground
v = 0
hp = 3
surface = "g" --g, a, c
invuln = 0
rainbow = 0
rapid = 0
death_s = 1

function do_damage()
  invuln = iframes
  hp -= 1
  if hp <= 0 then
    mode = "dead"
    set_hiscores()
    music(20)
  else
    sfx(5)
  end
end

--bullet stuff
bullets = {}
b_cooldown = 0
splats = {}

function spawn_bullet()
  local x = x+10
  local y = y
  if surface == "g" then
    y = y-1
  elseif surface == "a" then
    y = y-2
  else
    y = y-4
  end
  local bullet = {["x"]=x, ["y"]=y, ["n"]="bullet"}
  add(bullets, bullet)
  b_cooldown = 4
  if rapid > 0 then
    sfx(1, -1, 2)
  else
    sfx(1)
  end
end

function spawn_splat(bullet, enemy)
  local r = get_rect(enemy)
  local splat = {["x"]=r.x1-8, ["y"]=bullet.y+2, ["s"]=1}
  add(splats, splat)
  sfx(2)
end

--status stuff
score = 0
mode = "title" --title, menu, play, dead
title_time = 0
dead_time = 0
song = "main" --main, rainbow

function get_speed()
  local speed = menu_choice
  if rainbow > 0 then
    speed *= 3
  end
  return speed
end

--menu stuff
menu_items = {"easy", "medium", "hard"}
menu_cursor = 1
menu_choice = 0

--high score stuff
function get_hiscores()
  local scores = {}
  local start = (menu_choice-1)*5
  for i = start,start+4 do
    add(scores, dget(i))
  end
  return scores
end

function set_hiscores()
  function sort(list)
    --reverse bubble sort (shut up)
    for i = #list-1,1,-1 do
      for j = 1,i do
        if list[j] < list[j+1] then
          local temp = list[j+1]
          list[j+1] = list[j]
          list[j] = temp
        end
      end
    end
  end
  
  local scores = get_hiscores()
  add(scores, flr(score))
  sort(scores)
  
  local start = (menu_choice-1)*5
  for i = 1,5 do
    dset(start+i-1, scores[i])
  end
end

--enemy/powerup stuff
cooldown = 0
enemy_types = {"fire", "fire2", "lemon", "mouth"}
enemies = {}
powerups = {}
shield = {["x"]=0, ["y"]=0, ["angle"]=0, ["time"]=0, ["n"]="shield"}
barrages = {}

function kill(enemy)
  enemy.a = false
  if killed[enemy.n] < 32767 then
    killed[enemy.n] += 1
  end
  sfx(7)
end

function do_heal()
  if hp < 3 then hp += 1 end
  sfx(6)
end

function do_rainbow()
  rainbow = rainbow_time
  surface = "a"
  v = 0
  invuln = rainbow_time+30
  song = "rainbow"
  music(21, 0, 2+4)
end

function do_shield()
  shield.time = shield_time
  shield.x = x+4 + 12*cos(shield.angle)
  shield.y = y + 12*sin(shield.angle)
  sfx(6)
end

function do_barrage()
  for i = 1,barrage_count do
    barrage = {}
    barrage.x = (i-1)*128/barrage_count
    barrage.y = ceil-16
    barrage.dx = 0
    barrage.dy = 0
    barrage.time = i*15
    barrage.flat = false
    barrage.flat_time = 15
    barrage.sound = false
    barrage.n = "barrage"
    add(barrages, barrage)
  end
  sfx(6)
end

function do_rapid()
  rapid = rapid_time
  sfx(6)
end

--stats
killed = {}
for enemy in all(enemy_types) do
  killed[enemy] = 0
end

powerup_types = {"apple", "orange", "banana", "rapid", "rainbow"}
assists = {}
for powerup in all(powerup_types) do
  assists[powerup] = 0
end

page = 0

--spawning objects
function spawn(name)
  function enemy_base()
    --common enemy properties
    enemy = {}
    enemy.x = edge
    enemy.a = true --alive
    enemy.s = 1 --counter for death animation
    enemy.n = name
    return enemy
  end
  
  function powerup_base()
    --common powerup properties
    powerup = {}
    powerup.x = edge
    powerup.y = ground
    powerup.n = name
    return powerup
  end
  
  if name == "lemon" then
    local lemon = enemy_base()
    lemon.y = ground
    lemon.death = lemon_die_a
    add(enemies, lemon)
    cooldown = 8
  elseif name == "mouth" then
    local mouth = enemy_base()
    if rnd(1) < 0.5 then
      mouth.surface = "g"
      mouth.y = ground-8
    else
      mouth.surface = "c"
      mouth.y = ceil
    end
    mouth.death = mouth_die_a
    add(enemies, mouth)
    cooldown = 32
  elseif name == "fire" then
    local fire = enemy_base()
    fire.y = heights[flr(rnd(#heights))+1]
    fire.death = fire_die_a
    add(enemies, fire)
    cooldown = 8
    sfx(3)
  elseif name == "fire2" then
    local fire2 = enemy_base()
    fire2.y = heights[flr(rnd(#heights))+1]
    if rnd(1) < 0.5 then
      fire2.d = "up"
    else
      fire2.d = "down"
    end
    fire2.death = fire_die_a
    add(enemies, fire2)
    cooldown = 8
  elseif name == "apple" or name == "banana" or name == "orange" or name == "rainbow" or name == "rapid" then
    local powerup = powerup_base()
    add(powerups, powerup)
    cooldown = 8
  end
end

function _draw()
  cls()
  
  --transparency
  palt(0, false)
  palt(15, true)
  
  --background
  map(0, 0, -bg, 0, 24, 16)
  
  --enemies
  local fire = get_spr("fire")
  local mouth = get_spr("mouth")
  for enemy in all(enemies) do
    if enemy.n == "lemon" then
      if enemy.a then
        spr(45, enemy.x, enemy.y)
      else
        spr(enemy.death[enemy.s], enemy.x, enemy.y)
      end
    elseif enemy.n == "fire" or enemy.n == "fire2" then
      if enemy.a then
        spr(fire, enemy.x, enemy.y)
      else
        spr(enemy.death[enemy.s], enemy.x, enemy.y)
      end
    elseif enemy.n == "mouth" then
      if enemy.a then
        if enemy.surface == "g" then
          spr(mouth, enemy.x, enemy.y, 4, 2)
        else
          spr(mouth, enemy.x, enemy.y, 4, 2, true, true)
        end
      else
        if enemy.surface == "g" then
          spr(enemy.death[enemy.s], enemy.x, enemy.y, 4, 2)
        else
          spr(enemy.death[enemy.s], enemy.x, enemy.y, 4, 2, true, true)
        end
      end
    end
    --local r = get_rect(enemy)
    --rect(r.x1, r.y1, r.x2, r.y2)
  end
  
  --powerups
  for powerup in all(powerups) do
    if powerup.n == "rainbow" then
      spr(61, powerup.x, powerup.y)
    elseif powerup.n == "rapid" then
      spr(62, powerup.x, powerup.y)
    elseif powerup.n == "apple" then
      spr(47, powerup.x, powerup.y)
    elseif powerup.n == "banana" then
      spr(46, powerup.x, powerup.y)
    elseif powerup.n == "orange" then
      spr(14, powerup.x, powerup.y)
    end
  end
  
  --shield
  if mode != "dead" and shield.time > 0 then
    if shield.time > 60 or shield.time%2 == 0 then
      spr(46, shield.x, shield.y)
      --local r = get_rect(shield)
      --rect(r.x1, r.y1, r.x2, r.y2)
    end
  end
  
  --barrage
  --don't draw oranges above ceiling
  clip(0, ceil-8, 128, 72)
  for barrage in all(barrages) do
    if barrage.flat then
      spr(15, barrage.x, barrage.y)
    else
      spr(14, barrage.x, barrage.y)
    end
  end
  clip()
  
  --slime
  if rainbow > 0 then
    local slime = get_spr("rainbow")
    if rainbow > 60 or rainbow%2 == 0 then
      spr(slime, x, y, 2, 1)
    end
  elseif mode == "dead" then
    if death_s != 0 then
      spr(slime_die_a[death_s], x, y, 2, 1)
    end
  else
    local slime = get_spr("slime")
    if rapid > 60 or rapid%2 == 1 then
      pal(11, 12)
      pal(3, 1)
    end
    if invuln%2 == 0 then
      if surface == "c" then
        spr(slime, x, y, 2, 1, false, true)
      elseif surface == "a" then
        spr(8, x, y, 2, 1)
      else
        spr(slime, x, y, 2, 1)
      end
    end
    pal(11, 11)
    pal(3, 3)
  end
  
  --bullets and splats
  if rapid > 0 then
    pal(11, 12)
    pal(3, 1)
  end
  for bullet in all(bullets) do
    spr(30, bullet.x, bullet.y)
  end
  for splat in all(splats) do
    spr(splat_a[splat.s], splat.x, splat.y)
  end
  pal(11, 11)
  pal(3, 3)
  
  --title
  if mode == "title" then
    if title_time >= 20 then
      spr(160, 32, 0, 8, 2)
      if title_time >= 40 then
        spr(193, 40, 16, 5, 2)
        if title_time >= 60 then
          spr(136, 32, 10, 8, 5)
        end
      end
    end
  end
  
  --text
  color(7) --white
  if mode == "title" then
    if title_time >= 60 then
      print("press x to start", 32, 50)
    end
  elseif mode == "menu" then
    print("arrows to move, z to shoot ", 0, 0, 7)
    print("fire", 108, 0, 9)
    print("apple", 0, 6, 8)
    print(" restores health", 20, 6, 7)
    print("slime", 0, 12, 11)
    print(" dislikes ", 20, 12, 7)
    print("lemon", 60, 12, 10)
    cursor(0, 18)
    color(7)
    print("\nx to select difficulty\n")
    for i = 1,#menu_items do
      if i == menu_cursor then
        if i == 1 then color(11)
        elseif i == 2 then color(10)
        elseif i == 3 then color(8)
        end
        print(">"..menu_items[i])
        color(7)
      else
        print(" "..menu_items[i])
      end
    end
  elseif mode != "title" then
    print("score: "..flr(score))
    if mode == "play" then
      print("hp: "..hp)
      cursor(64, 0)
      if shield.time > 0 then
        color(10)
        print("banana shield")
      end
      if #barrages > 0 then
        color(9)
        print("orange barrage")
      end
      if rapid > 0 then
        color(12)
        print("rapid fire")
      end
      if rainbow > 0 then
        print("rainbow slime!")
      end
      color(7)
    elseif mode == "dead" then
      print("game over")
      if dead_time >= 31 then
        print("\narrows to\nshow stats")
        cursor(64, 0)
        local cx = 64
        local cy = 0
        if page == 0 then
          print("< high scores >\n")
          local new_high = false
          local scores = get_hiscores()
          for i,high_score in pairs(scores) do
            if flr(score) == high_score and not new_high then
              new_high = true --avoids duplicate highlighting
              color(11)
            end
            print(i..": "..high_score)
            color(7)
          end
        elseif page == 1 then
          print("< kills >")
          cy += 7
          for e in all(enemy_types) do
            local count = killed[e]
            if e == "fire" then
              spr(get_spr("fire"), cx, cy-1)
              cursor(cx+10, cy)
              print(count + killed.fire2)
              cy += 9
              cursor(cx, cy)
            elseif e == "lemon" then
              spr(45, cx, cy-3)
              cursor(cx+10, cy)
              print(count)
              cy += 9
              cursor(cx, cy)
            elseif e == "mouth" then
              spr(get_spr("mouth"), cx, cy-1, 4, 2)
              cursor(cx+34, cy+5)
              print(count)
              cy += 17
              cursor(cx, cy)
            end
          end
        elseif page == 2 then
          print("< powerups >")
          cy += 7
          local sprites = {47, 14, 46, 62, 61}
          for i = 1,#powerup_types do
            local p = powerup_types[i]
            local s = sprites[i]
            local count = assists[p]
            spr(s, cx, cy-1)
            cursor(cx+10, cy)
            print(count)
            cy += 9
            cursor(cx, cy)
          end
        end
        cursor(40, 51)
        print("x to restart")
      end
    end
  end
end

function _update()
  --title/menu/game over
  if mode == "title" then
    if title_time < 80 then
      title_time += 1
      if title_time == 20 then
        sfx(22)
      elseif title_time == 40 then
        sfx(23)
      elseif title_time == 60 then
        sfx(24)
      elseif title_time == 80 then
        music(8, 0, 1+2)
      end
    end
    if btnp(5) then --button 2
      mode = "menu"
      if title_time < 80 then
        music(8, 0, 1+2)
      end
    end
  elseif mode == "menu" then
    if btnp(2) then --up
      menu_cursor -= 1
      if menu_cursor < 1 then
        menu_cursor = #menu_items
      end
    end
    if btnp(3) then --down
      menu_cursor += 1
      if menu_cursor > #menu_items then
        menu_cursor = 1
      end
    end
    if btnp(5) then --button 2
      menu_choice = menu_cursor
      mode = "play"
      music(0, 0, 1+2)
    end
  elseif mode == "dead" then
    if dead_time < 31 then
      dead_time += 1
    end
    if dead_time >= 31 then
      if btnp(0) then page = (page-1)%3 end
      if btnp(1) then page = (page+1)%3 end
      if btnp(5) then --button 2
        run() --restart game
      end
    end
  end
  
  --animate sprites and bg
  for key,sprite in pairs(sprites) do
    inc_anim(sprite)
  end
  bg = (bg+get_speed())%64
  
  --dead enemies
  for enemy in all(enemies) do
    if not enemy.a then
      enemy.s += 1
      if enemy.s > #enemy.death then
        del(enemies, enemy)
      end
    end
  end
  
  --dead slime
  if mode == "dead" and death_s > 0 then
    death_s += 1
    if death_s > #slime_die_a then
      death_s = 0
    end
  end
  
  --splats
  for splat in all(splats) do
    splat.s += 1
    if splat.s > #splat_a then
      del(splats, splat)
    end
  end
  
  --invulnerability timer
  if invuln > 0 then invuln -= 1 end
  
  --rainbow timer
  if rainbow > 0 then rainbow -= 1 end
  
  --rapid fire timer
  if rapid > 0 then rapid -= 1 end
  
  --music
  if rainbow <= 0 and song == "rainbow" then
    song = "main"
    music(0, 0, 1+2)
  end
  
  --move shield
  if shield.time > 0 then
    shield.time -= 1
    shield.angle += 1/30
    shield.x = x+4 + 12*cos(shield.angle)
    shield.y = y + 12*sin(shield.angle)
  end
  
  --move and delete barrages
  for barrage in all(barrages) do
    if barrage.time <= 0 then
      if not barrage.sound then
        sfx(4)
        barrage.sound = true
      end
      if barrage.flat then
        barrage.x -= get_speed()
        barrage.flat_time -= 1
        if barrage.flat_time <= 0 then
          del(barrages, barrage)
        end
      elseif barrage.y >= ground then
        barrage.y = ground
        barrage.flat = true
      else
        barrage.dx += 0.02
        barrage.x += barrage.dx
        barrage.dy += 0.2
        barrage.y += barrage.dy
      end
    else
      barrage.time -= 1
    end
  end
  
  --update score
  if mode == "play" and score < 32767 then
    score += 0.5
  end
  
  --slime movement
  if rainbow > 0 then
    if btn(2) then y -= 3 end
    if btn(3) then y += 3 end
    if btn(0) then x -= 3 end
    if btn(1) then x += 3 end
  elseif mode != "dead" then
    --local dv = 0.5
    local dv = 0.75
    if surface == "g" then
      dv = 0
      if btn(2) then --jump
        surface = "a"
        v = -5
        sfx(0)
      end
    elseif surface == "a" then
      if btn(2) and v < 0 then
        dv = 0.25
      end
    else
      dv = 0
      if btn(3) then --fall
        surface = "a"
        v = 1
      end
    end
    v += dv
    y += v
    if btn(0) then x -= 1 end
    if btn(1) then x += 1 end
  end
  if y > ground then
    y = ground
    if rainbow <= 0 then
      surface = "g"
      sprites.slime.s = 1
      v = 0
    end
  end
  if y < ceil then
    y = ceil
    if rainbow <= 0 then
      surface = "c"
      sprites.slime.s = 1
      v = 0
    end
  end
  if x < 0 then x = 0 end
  if x > edge-16 then x = edge-16 end
  
  --spawn enemies/powerups
  if mode == "play" or mode == "dead" then
    cooldown -= get_speed()
    if cooldown <= 0 then
      --multiply spawn rates by speed
      --for consistent object spacing
      if rnd(1) < enemy_rate*get_speed() then
        enemy = enemy_types[flr(rnd(#enemy_types))+1]
        spawn(enemy)
      elseif rainbow <= 0 then
        if rnd(1) < apple_rate*get_speed() then
          spawn("apple")
        elseif rnd(1) < banana_rate*get_speed() then
          spawn("banana")
        elseif rnd(1) < orange_rate*get_speed() then
          spawn("orange")
        elseif rnd(1) < rapid_rate*get_speed() then
          spawn("rapid")
        elseif rnd(1) < rainbow_rate*get_speed() then
          spawn("rainbow")
        end
      end
    end
  end
  
  --spawn bullet
  if b_cooldown > 0 then b_cooldown -= 1 end
  if mode != "dead" and rainbow <= 0 and btn(4) then
    if rapid > 0 and (b_cooldown <= 0 or #bullets == 0) then
      spawn_bullet()
    elseif #bullets == 0 then
      spawn_bullet()
    end
  end
  
  --move and delete enemies
  for enemy in all(enemies) do
    if enemy.n == "lemon" then
      enemy.x -= get_speed()
      if enemy.x < -8 then
        del(enemies, enemy)
      end
    elseif enemy.n == "fire" then
      if enemy.a then
        --hard mode fire was too fast, so we nerfed it
        if menu_choice == 1 or menu_choice == 2 then
          enemy.x -= get_speed()*2
        elseif menu_choice == 3 then
          enemy.x -= get_speed()+2
        end
      else
        enemy.x -= get_speed()
      end
      if enemy.x < -8 then
        del(enemies, enemy)
      end
    elseif enemy.n == "fire2" then
      enemy.x -= get_speed()
      if enemy.a then
        if enemy.d == "up" then
          enemy.y -= 2
          if enemy.y < ceil then
            enemy.y = ceil
            enemy.d = "down"
          end
        else
          enemy.y += 2
          if enemy.y > ground then
            enemy.y = ground
            enemy.d = "up"
          end
        end
      end
      if enemy.x < -8 then
        del(enemies, enemy)
      end
    elseif enemy.n == "mouth" then
      enemy.x -= get_speed()
      if enemy.x < -32 then
        del(enemies, enemy)
      end
    end
  end
  
  --move and delete powerups
  for powerup in all(powerups) do
    powerup.x -= get_speed()
    if powerup.x < -8 then
      del(powerups, powerup)
    end
  end
  
  --move and delete splats
  for splat in all(splats) do
    splat.x -= get_speed()
    if splat.x < -8 then
      del(splats, splat)
    end
  end
  
  --move and delete bullets
  for bullet in all(bullets) do
    bullet.x += 4
    if bullet.x >= edge then
      del(bullets, bullet)
    end
  end
  
  --bullet collisions
  for bullet in all(bullets) do
    local bullet_r = get_rect(bullet)
    for enemy in all(enemies) do
      local enemy_r = get_rect(enemy)
      if collide(bullet_r, enemy_r) and enemy.a then
        if enemy.n == "fire" or enemy.n == "fire2" then
          kill(enemy)
        else
          spawn_splat(bullet, enemy)
        end
        del(bullets, bullet)
        break
      end
    end
  end
  
  --barrage collisions
  for barrage in all(barrages) do
    if not barrage.flat then
      local barrage_r = get_rect(barrage)
      for enemy in all(enemies) do
        local enemy_r = get_rect(enemy)
        if enemy.a and collide(barrage_r, enemy_r) then
          kill(enemy)
        end
      end
    end
  end
  
  --slime collisions
  if mode == "play" then
    --get slime rect
    local h
    if rainbow > 0 then
      h = rainbow_h
    elseif surface == "a" then
      h = slime_air_h
    elseif surface == "c" then
      h = flip_hit(slime_h, 8)
    else
      h = slime_h
    end
    local slime_r = make_rect(h, x, y)
    
    --powerups
    for powerup in all(powerups) do
      local powerup_r = get_rect(powerup)
      if collide(slime_r, powerup_r) then
        if powerup.n == "apple" then
          do_heal()
        elseif powerup.n == "banana" then
          do_shield()
        elseif powerup.n == "rainbow" then
          do_rainbow()
        elseif powerup.n == "rapid" then
          do_rapid()
        elseif powerup.n == "orange" then
          do_barrage()
        end
        del(powerups, powerup)
        if assists[powerup.n] < 32767 then
          assists[powerup.n] += 1
        end
      end
    end
    
    --enemies
    local shield_r = get_rect(shield)
    for enemy in all(enemies) do
      if enemy.a then
        local enemy_r = get_rect(enemy)
        if shield.time > 0 and collide(shield_r, enemy_r) then
          kill(enemy)
        elseif collide(slime_r, enemy_r) then
          if rainbow > 0 then
            kill(enemy)
          elseif invuln <= 0 then
            do_damage()
          end
        end
      end
    end
  end
end

__gfx__
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3333ffffffffffffffffffffffffffffffffffffffff9449ffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3bbb73fffffffffffffffffffff77fffffffffffffff999999fffffffff
ffffff3333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3bbbbb73ffffffffffffffffffff07faff70ffffffff99999999ffffffff
fffff3bb773fffffffffff3333ffffffffffffffffffffffffffffffffffffffffff3bbbbbb3ffffffffffffffffffffffffff77ffffffff77999970ffffffff
ffff3bbbbb73ffffffff33bbb733ffffffffff333333fffffffffff33333ffffffff3bbbbbb3ffffffffffffffffffffaffffafaffffffff07999977fff44fff
ffff3bbbbbb3fffffff3bbbbbb773ffffffff3bbb7773ffffffff33bb7733fffffff3bbbbbb3fffffffffffffffffffffaafffafffffffff99999999f999999f
ffff3bbbbbb3fffffff3bbbbbbbb3fffffff3bbbbbbb73fffff33bbbbbb73ffffffff3bbbb3fffffffffffffffffffffafaafaff77faaf77f999999f77999977
fffff333333ffffffff3333333333ffffff33333333333fff333333333333fffffffff3333ffffffffffffffffffffffffaaaafa07aaaa70ff9999ff07999970
ffffffffffffffffffffff3333fffffffffffffffffffffffffffffffffffffbffffffffff3fffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffff3bbbb3fffffffff3f3333ff3fbffffffffffffffffffffffffffffffffffffffbffffbffffffffffffffffffffffffffffffffff3ff
ffffffffffffffffffff3bbbbbb33ffffbfff3bbbb33fffffff3ff3333ff3ffffffffff33fffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffbbbbbbfffffffffbbbbbbbbbfffffff33bbbb33fffffff3ffbbbbfffffffffffffbbffffffffffffffffffffffffffffffffffffff3
fffffffffffffffffffffbbbbbbffffffffbbbbbbbbbffffbfbbbbbbbbbbfbffffffff3bb3fffffffffffffbbfffffffffffffffffffffffffffffffffff3f33
fffffffffffffffffff33bbbbbb3ffffffff33bbbb3fffbfffff33bbbb3ffffffffffff33fffffffffffffffffffffffffffffffffffffffff3333fffffffff3
fffffffffffffffffffff3bbbb3ffffffff3ff3333ffffffffffff3333fffffbfffffffffff3fffffffffbffffbffffffffffffffffffffff3bbbb3fffffffff
ffffffffffffffffffffff3333ffffffffffffffffffffffff3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3333fffffff3ff
ffff9fffff9f9fffff9ffffffffff9ffffffffffffffffffffff8ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4aafffff44fff
ff9f9fffff99fffffffff9fffff9fffffffff9ffffff9fffff8fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaaaff884488f
ff99a9ffff9a9fffff9f99fffffa9fffff999ff9ff99ffafffffffffff8fffffffff8ffffffffffffffffffffffffffffffffffffffffffffffffa7787088778
ff9aa9ffff9aa9ffff99a9ffff9a99ff99a9a9af99a9a9ffff8f8fffffff8fffffffffffff8fffffffffffffffffffffffffffffffaaaafffffffa0787788078
f98aa89ff98aa89ff98aa89ff98aa89f8a8a9aff8a8a99f9ff9999ffff8f8fffff8f8ffffffffffffffffffffffffffffffffffff77aa07ffffffaaa88888888
f9aaaa9ff9aaaa9ff9aaaa9ff9aaaa9faaaaa9ffaaaaa9fff889988ff888888fff8888fffff88fffffffffffffffffffffffffffa70aa77afff77aaa88888888
ff9aa9ffff9aa9ffff9aa9ffff9aa9ff9aaa9fff9aaa9ffff99aa99f89999998f899998fff8998fffffddffffffdfffffffffffffaaaaaaffff70aaff888888f
fff99ffffff99ffffff99ffffff99ffff999fffff999ffffff8888fff888888fff8888fffff88fffffd88dffffd8dffffffdffffffaaaafff4aaaaffff8ff8ff
fffffffffff8fffffccaafffff2ffffffaa99fff1ffffffff9988fffffffcffff8822ffffafffffff2211ffffffff9fff11ccffff777777ff777777fffffffff
ffffffffffffff21133339ffffffff1cc33338ffffffffcaa33332ffffffffa9933331ffffffff9883333cffffffff8223333affff7887ffff7c17ffffffffff
ffffffffffff22133bb7739fff1111c33b77738ffcffcca33777b32fffaaaa93377bb31f9fffa98337bbb3cfff8ff8233bbbb3afff7997ffff71c7ffffffffff
ffffffffbf822bbbbbbbb738ffff11bbbbbbbb32bf1ccbbbbbbbbb31ffffaabb7bbbbb3cff99bbb77bbbbb3affff8bb7bbbbbb39ff7aa7ffff7c17ffffffffff
fffffffffffb22bbbbbbbb38fbf11bbbbbbbbb32fffbccbbbbbbbb31fbfaabbbbbbbbb3cfff999bbbbbbbb3afff8bbbbbbbbb739f7cccc7ff7c1c17fffffffff
fffffffff82822133bbbb39f2ff211c33bbbb38fffcfcca33bbbb32fcffcaa933bbbb31ffaff99833bbbb3cf9f8888233bbbb3af711111177c1c1c17ffffffff
ffffffffffffff21133339ffffffff1cc33338ffffffffcaa33332ffffffffa9933331ffffffaf9883333cffffffff8223333aff7222222771c1c1c7ffffffff
fffffffffff8fffffccaaffff2fffffffaa99fffffffff1ff9988ffffcfffffff8822ffffffffffff2211ffffffff9fff11ccffff777777ff777777fffffffff
5505550055555505fffffffffffffffffffffffffffffffffffbffffffffffffffffffffffff7fffffffffffffffffef7effffffffffffffffffffffffffffff
5550505505555055ffffffffffffffffffffffffffffffffffb7f7ffffffffffffffffffff7f77ffffffffffffff22e77e22fffffffffffff11451144115511f
5500055550000555ffffffffffffffffffffffffffffffffff7777ffffffffffffffffffff7777ffffffffffff2222e66e2222fffffffffff11551145115511f
5055055005505055ffffffffffffffffffffffffffffffffeeee77ff7ffffffffffffff78877eeeefffffffff22222e67e22222ffffffffff11551155115411f
0555500555055500ffffffffffffffffffffffffffffffff2222eee77ffffffffffff8877bee2222ffffffff222222e77e222222fffffffff11551145115511f
5550050555055055fffffffffffffffffffffffffffffffff222222eeffffffffff8888ee2b2222ffffffff2222222e66e2222222ffffffff11551155115511f
5505555055500555ffbffffffffffffffffffffffffff7fffff222222effffffff8888e222222fffffffff22222222e67e22222222fffffff11541155115511f
5055555055055055fb7ffffffffffffffffffff88888f77ffffff22222efffffff888e22222fbfffffffff22222222e77e22222222fffffff11451155115511f
0555555500555500e77f7ffffffffffffffff8888887877effffff22222efffff888e22222ffffffffffff22222222e66e22222222fffffff11441154115511f
5055555505555055e7777fffffffffffffff88888887777efffffff22222effff88b22222fffffffffffff22222222e68e22222222fffffff11451155115511f
55055555055505552ee77f7ffffffffffff8888887877ee2ffffffff22222eff88bbb222ffffffffffffff22222222e88e22222222fffffff11551155114511f
5550555050550555222ee77eeeeeeeffffbbbbeee77be222ffffffff22222eff88b22b22fffffffffffffff2222222e88e2222222ffffffff11451155115511f
5555000555005555f2222ee2222222effbbbb2222eeb222ffffffffff22222e88b22222ffffffffffffffff2222222e8be2222222ffffffff11551145114511f
5550555550550555ff2222222222222eb2b2b222222222fffffffffff222222eb222b22fffffffffffffffff222222beeb222222fffffffff11551155114411f
5505555505555005fff2222222222222b2b22222222b2fffffffffffff2222222b2222fffffffffffffffffff22222b22b22222ffffffffff11551155114411f
0055555505555550ffff222222222222222222222222ffffffffffffff222222222222ffffffffffffffffffff222222222222ffffffffffffffffffffffffff
ffffffff56665666ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
6656665655555555ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
5555555566566656ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
5666566655555555fffffffffffffffffffffff888fffffffffffffffffffffffffffff888fffffffffffffffffffffffffffff777ffffffffffffffffffffff
5555555556665666ffff7ffffffffffffffff88888f7ffffffff7ffffffffffffffff88888f7ffffffff7ffffffffffffffff77777f7ffffffffffffffffffff
6656665655555555bff77ff7ffffffffffff888878f77ff7bff77ff7ffffffffffff888878f77ff77ff77ff7ffffffffffff777777f77ff7ffffffffffffffff
555555556656665677f77f77fffffffffff8888877f77f7777f77f77fffffffffff8888877f77f7777f77f77fffffffffff7777777f77f77ffffffffffffffff
56665666ffffffff777eeee7ffffffffff8888887ebee777777eeee7ffffffffff8878887ebee77777777777ffffffffff77777777777777ffffffffffffffff
fffffffffffffffffbe2222efffffffff8888888e2722e7ff7e7222efffffffff888888872722e7ff7777777fffffffff7777777f777f77fffffffffffffffff
fffffffffffffffffe222222befffffff88888ee222222effe222227befffffff78888ee227222eff777f77777fffffff77f777fff77777fffffffffffffffff
ffffffffffffffffe2222222b2efffff88888b2222b2222ee222272272efffff787887727272722e77777777777fffff77f77777f7777777ffffffffffffffff
ffffffffffffffffe2222222222effff8888b2222222222ee2722272227effff878777272722272e77f777777f77ffff7fff777777777777ffffffffffffffff
ffffffffffffffffe222ff22b222eff8888bb27222ff222ee222ff227777eff77877f77272ff222e7777ff77fff77ff777f7f77777ff7f77ffffffffffffffff
fffffffffffffffffe22fff222722eb7bbb7b7272fff22effe22fff77f727e77777fff772fff22eff777fff77f777777777fff777fff777fffffffffffffffff
fffffffffffffffffe2ffffff727222b272bb27ffffff2eff72ffffff7777777f777f77ffffff7eff77ffffff77777f7f7ffff7ffffff77fffffffffffffffff
ffffffffffffffffffffffffff72727b2b27b7ffffffffffffffffffff7ff77f77f777ffffffffffffffffffff7fffff7ffff7ffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3ffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3ffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3ffffffffffff
fffffffffffffffffffffffff7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3ffffffffffff
ffffffffffffffffffffffff777fffffffffffffffffffffffffffffffff7ffffffffffffffffffffffffffffffffffffffffffffffffffffff3ffffffffffff
fff7fffffffffffffffffffff7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3bffff3ffffff
ff777fffffffffffffff7fffffffff7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3bbb3fffffff
fff7fffffffffffffffffffffffff777ffffffffffffffffffffff7fff7f7fffffffffffffffffffffffffffffffffffffffffffffffffffffff3bbb3fffffff
ffffffffffffffffff7f7f7ff7f7ff7ffff7fffffffffffffffffffffff7fffffffffffffffffffffffffffffffffffffffffffffffffffffffff3b3ffffffff
7fffffff7ffffffffffffffffff7ffffff7f7ffffffffffffff7ffffff7f7ffffffffffffffffffffffffffffffffffffffffffffffffffffffff3b3ffffffff
fff7fff7f7fffffff7ff7ffff77777fffff7fffff7f7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3b3ffffffff
ff777fff7ffffffff7fffffffff7ffffffffffffff7ffffff7fff7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff33ffffffff
fff7ff7ffffffff77777f7f7fff7fffffffffffff7f7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff33ffffffff
ffffffffff7ffffff7ffff7fffffff7f7ffffffffffffffffff7fffff7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3fffffffff
f7fffffff777fffff7fff7f7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3fffffffff
ffffffffff7fff7fffffffffffffffffffffff7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3b3ffffffff
f22888888888ff2288888888fff2288888ffff2288888f222888ffffff22888fffffffffffffffffffffffffffffffffffffffffffffffffffff3bb73fffffff
2288888888888228888888888f228888888ff2288888882288888ffff2288888ffffff3333ffffffffffffffffffffffffffffffffffffffffff3bb73fffffff
228888888888882888888888822888888888f2288888888288888ffff2288888fff333bbbb333ffffffffffffffffffffffffffffffffffffff3bbbb73ffffff
22888fff2288882888fffffff22888888888f2288ff28888288888ff2288888fff3bbbbbbbbb73fffffffffffffffffffffffffffffffffffff3bbbb73ffffff
22888ffff228882888fffffff22888f22888f2288fff2888228888ff228888fff3bbbbbbbbbbb73ffffffffffffffffffffffffffffffffffff3bbbb73ffffff
22888ffff228882888ffffff22888fff228882288fff2288f228888228888fff3bbbbbbbbbbbbb73fffffffffffffffffffffffffffffffffff3bbbb73ffffff
22888fff2288882888ffffff22888fff228882288fff2288f228888228888fff3bbbbbb333bbbbbb3fffffff333333ffffffffffff333333fff3bbbb73ffffff
22888888888882288888888822888fff228882288fff2288ff2288888888ffff3bbbb33fff33bbbbb3ffff337bb77733fffffffff377bb773ff3bbbbb3ffffff
228888888888f2288888888822888888888882288fff2288ff2288888888ffff3bbb3fffffff3bbbb73ff3bbbbbbbbb73fffffff3bbbbbbb73f3bbbbb3ffffff
228888888888f2288888888228888888888888288fff2288fff22888888fffff3bbb3ffffffff3bbbb3ff3bbbbbbbbbb3ffffff3bbbbbbbbb733bbbbb3ffffff
22888ff22888822888fffff228888888888888288fff2288ffff228888ffffff3bbb3fffffffff3bbb3f3bbbbbbbbbbb73ffff3bbbbbbbbbbbbbbbbb73ffffff
22888fff2288822888fffff228888fff228888288fff2888ffff228888ffffff3bbb3ffffffffff3b3ff3bbbbbbbbbbbb3ffff3bbbb33bbbbbbbbbbb73ffffff
22888fff2288882888fffff228888fff228888288ff28888ffff228888ffffff3bbb3ffff333fff3b3ff3bbbbbbbbbbbb3fff3bbbb3ff3bbbbbbbbbbb3ffffff
22888ffff22888288888888828888fff228888288888888fffff228888fffffff3bbb3ff3b773ff3b3f3bbbbbbbbbbbbbb3ff3bbb3fff3bbbbb3bbbb73ffffff
22888ffff22888888888888888888fff22888828888888ffffff228888fffffff3bbb3ff3bbb73ff3ff3bbbbbbbbbbbbbb3ff3bbb3fff3bbbb3f3bbb3fffffff
f2288fffff228882888888888288fffff2888f2288888ffffffff2288ffffffff3bbb3ff3bbbbb3ffff3bbbbbbbbbbbbbb3f3bbb3ffff3bbbb3f3bbb3fffffff
fffffffffffffffffaaaaaffaffffffffffffffff9affffffffffffffffffffff3bbb3fff33bbbb33ff3bbbbbbbbbbbbbb3f3bbb3fff3bbbbb3ff3b3ffffffff
ffffffffffffffffa99999afaffffffaaaaafffff9affffffffffffffffffffff3bbbb3ffff3bbbbb3f3bbbbbbbbbbbbbb33bbbbb333bbbbbb3f3bb73fffffff
fffffffffffffffa9fffff9a9ffff9a99999affff9afffffffffffffffffffffff3bbbb3333bbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3f3bbbb73ffffff
fffffffffffffffa9ffffff9ffff9affffff9afff9affffffffffffffffffffffff3bbbbbbbbb33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33f3bbbbbbb3fffff
fffffffffffffffa9ffffffffff9afffffff9afff9afffaffffffffffffffffffff3bbbbbbbb3ff3b333bbbbbbbbbbbbbb333bbbbbbbb33fff3bbbbbbbb33fff
ffffffffffffffffaffffffffff9afffffff9afaaaaaaa9fffffffffffffffffffff33333333ffff3fff33333333333333fff33333333ffffff333333333333f
ffffffffffffffff9aaffffffff9affffffaafa999a999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffff99aaafffff9affffaa99f9ff9afffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffff999affffaaaaaa99ffffff9afffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffaafffffa9ffa9a9999ffffffff9afffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffa99affffa9ff9f9afffffffffff9afffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffa9f9affa9fffff9afffffffafff9afffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffff9aaaaaa9fffafff9affffaa9fff9afffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff999999fffa9ffff9aaaa99ffff9afffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffff9aaa9ffffff9999ffffff9af9affffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffff999ffffffffffffffffff9aafffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
__label__
55555555505333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb35555505555000055555055555222222222222222222222222222222222222222
55555555055333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb35555505550555505550555522222222222222222222222222222222222222222
5555555055333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3555550505555550505555222222222222222222222222222222222222222222
5555550555333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3555555055555555055552222222222222222222222222222222222222222222
5555550555333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3555555055555555055522222222222222222222222222222222222222222222
5555550555333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3555555055555555055222222222222222222222222222222222222222222222
5555505555333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3555550055555555052222222222222222222222222222222222222222222222
5555505555333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3555505505555555022222222222222222222222222222222222222222222222
5555505555333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3555055550555550522222222222222222222222222222222222222222222222
5555055555333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3550555555055550222222222222222222222222222222222222222222222222
5555055555333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb35550555555055552222222222222222222222222222222222222222222222222
5000555555333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb35505555555505552222222222222222222222222222222222222222222222222
05550555555333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb30505555555505522222222222222222222222222222222222222222222222222
55555055555333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb35055555555550022222222222222222222222222222222222222222222222222
55555505555333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb35055555555505222222222222222222222222222222222222222222222222222
555555505553333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb35505555555005522222222222222222222222222222222222222222222222222e
555555505555333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb35505555550555e2222222222222222222222222222222222222222222222222ee
5555555500553333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3555055500555ee222222222222222222222222222222222222222222222222eee
5555555505000333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb35555050055555ee22222222222222222222222222222222222222222222222eeee
55555550555553333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7773555550555555eee2222222222222222222222222222222222222222222222eeeee
55555660555555333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb777735555005555555eeee22222222222222222222222222222222222222222222eeeeee
555666605555553333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7777735500555555555eeee222222222222222222222222222222222222222222eeeeeeeb
5566666055555553333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb77777355055555555555eeeee2222222222222222222222222222222222222222eeeeeee2b
55666660005555563333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb77773500555555555555eeeee22222222222222222222222222222222222222eeeeeeee22b
566666055500556663333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb777735055555555555555eeeeee222222222222222222222222222222222222eeeeeeee22b2
6666605555550666663333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb777300555555555555555eeeeeee222222222222222222222222222222222eeeeeeeee222b8
660005555555066666633333bbbbbbbbbbbbbbbbbbbbbbbbbbbbb773055555555555555555eeeeeeee222222222222222222222222222222eeeeeeeeeeb222b8
00555555556660666666333333bbbbbbbbbbbbbbbbbbbbbbbbbbb7355555555555555555557eeeeeeeee22222222222222222222222222eeeeeeeeeee6b22b88
5555555566666606666666333333bbbbbbbbbbbbbbbbbbbbbbb773555555555555555555557eeeeeeeeeee2222222222222222222222eeeeeeeeeeee762b8b88
5555555666666660666600553333337bbbbbbbbbbbbbbbbb7773355555555555555555555577eeeeeeeeeeeee2222222222222222eeeeeeeeeeeee77762b8b88
555555666666666060005500553333337777bbbbbbbbb77733355555555555555555555555777eeeeeeeeeeeeee22222222222eeeeeeeeeeeeee77777282bb88
55555666666666660556665500553333333377777777733335555555555555555555555555777beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777777828bb88
55556666666666660666666655005053333333333333333555555555555555555555555555777b7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee627777772888b88
55566666666666660666666666550555993333333333995555555555555555555555555555e77b777eeeeeeeeeeeeeeeeeeeeeeeeeeeeee77622777788888b81
55566666666666606666666666665059a95559995999995555555555555555555555555555e77b77777eeeeeeeeeeeeeeeeeeeeeeeeee7777622777788888b11
5566666666666660666666666666659aa95999959999955955555555555555555555555555e77b7777711eeeeeeeeeeeeeeeeeeeeee777777628277788888b12
5566666666666606666666666696669aa99999999a99566555595555555555555555555555ee7bb77771112eeeeeeeeeeeeeeeee762777777682877888881b21
0566666666666606666666666666669aa999999a9999565555555655555555555555555555ee7bb77711122222eeeeeeeeeee777762777776228887888111b12
5006666666660066666666666666699aaa999aa99996655995566555555555555555555555eebbb7771124242222222222777777762277776888888881112b21
055000666660666666666666669999aaaa99aaa99966999555665555555555555555555555eebbb77712824242422222227777776222777768888881111b1b12
55555506660556666666666699a99aaaa99aaa999699995566655555555555555555555555eebbb17788282424242222227777776228277788888811212b1b21
555555600055556666666669aa99aaaaaaaaaa9999999556665555555555555555555555555bbbb1788882828242424242777777682288778888711212b76b12
55555666660555566666669aaa9aaaaaaaaaaa999a99556665655555555555555555555555bbbbb188888828282824242427777762888887888171212177761e
5555666666605556666669aaaaaaaaaaaaaaaaa9a99566665655555555555555555555555bbbbeb88888888282828282828b77778888888881177612127776ee
555666666660555666669aaaaaaaaaaaaaaaaaaaa966656556555555555555555555bbbbbbbbeeb888888888882828282828777b88b888811117761127777eee
556666666666055666669aaaaaaaaaaaaaaaaaaa9966665665555555555555555bbbbbbbbbbbee8888888888888888888888b7b888b88111127776121777eeee
55666666666605666660aaaaaaaaaaaaaaaaaaaa96666666655555555555555bbb55555bbbb5eb88888888888888888888888bb888b7112121777761277eeeee
56666666666605666006aaa88aaaaaaaaaaaaaa96656566655555555555555bbb5555555555558888888888888888888888888b11b7712121277776117eeeeee
56666666666505600666aaa88aaaaa88aaaaaa96656566665555555555555bbb5555555555bb58888888888888888888888881111b777121277777761eeeeee2
66666666666550056666aaa88aaaaa88aaaaaa66565666655555555555555bb5555555555bbbb8888888888888888888888111221b77711217777776eeeeee22
666666666650056666666aaaaaaaaa88aaaaa66666666655555555555555bb555555555555bbf8888888888888888888811122227b777711277777eeeeeee222
666666666605566665667aaaaaaaaaaaaaaa765566665555555555555555b55555555555555588888888888888888881112222227b7777111777eeeeeeee2225
6666666600556666566777aaaaaaaaaaaaa7666655655555555555555555b5555555555555558888888888888888881112222222b7b7776177eeeeeeeee22255
66666660555666665667777aaaaaaaaaa77666656600005555555555555bb5555555555555558888888888888888111112222222b7b7776eeeeeeeeee2225555
666660055665665566677777aaaaaaa7776666565555550055555555555bb555555555555555888888888888888ee11111222222b7b7eeeeeeeeeeee22555555
66660555565665666667777777777777766665655555555500555555555bb55555555555555588888888888888eeeeee1111111beeeeeeeeeeeeee2205555555
66005555656655666666777777777777665656655555555555055555555b55555555555555558888888888888eeeeeeeeeeeeeebeeeeeeeeeeee220055555555
60555555656555666666677777777666666566555555555555500bbbbbbb5555555555555555888888888888eeeeeeeeeeeeeeeebeeeeeeeee22005555555555
055555556665666666666667777666665666555bbbb55555555bb00bbb55555555555555555588888888888022eeeeeeeeeeeeeebeeeeeee2200555555555555
55555555665656666666666666666666666555bbbbbbb55555bb555005555555555555555555b8888888885500222eeeeeeeeeeebeee22220055555555555555
555555556656566666666666666655666655bbbb5bbbbbb55bb5555550055555555555555555b88888888b55550002222eeeeeeeb22200005555555555555555
555555556656655666666666665566666555bbb55555bbbbbb555555555005555555555555555b8888888b55555550000222222bbb0055555555555555555555
55555555565565566666666665666666555bbb5555555bbbb55555555555500555555555555555b888885b5555555555500000bbbbb555555555555555555555
5555555555656655555666555666665555bbbbb5555555bb555555555555555000055555555555bb888b5b555555555555bb555bbbbb55555555555555555555
5555555555565566666666666666555555bbbbbbb5555bbb5555555555555555555055555555555bbbb55555555555555bbbb5555bbbb5555555555555555555
555555555555666565555666555555555bbb55bbbbbbbbbb55555bb5555555555555005555555555bb555b555555555555bb555555bb55555555555555555555
55555555555555666666665555555555bbb55555bbbbbbb55555bbbb5555555555555500055555555b5555555555555555555555555555555555555555555555
5555555555555555555555555555555bbb55555555bbb5555555bbbbbbb5555555555555500055555b5555555555555555555555555555555555595555555555
555555555555555555555555555555bbb555555555bbb555555bbb5bbbbb555555555555555500055b5555555555555555555555555555555555595555555555
55555555555555555555555555555bbbb555555555bb555555bbbb555bbbbb5555555555555555500b5555555555555555555555555555555555999555555555
55555555555555555555555555555bbb5555555555bb555555bbb555555bbb55555555555555555bb00555555555555555555555555555555555999555555555
555555555555555555555555555555555555555555bb55555bbb55555555555555555555555555bb555055555555555555555555555555555555999955555555
55555555555555555555555555555555555555555bbb5555bbbb55555555555555555555555555bb555500555555555555555555555555555555999955555555
55555555555555555555555555555555555555555bb55555bbbbbb5555555555555bbb555555555bbb5555055555555555555555555555555555999955555555
55555555555555555555555555555555555555555bb5555bbb5bbbbb5555555555bbbb55555555555bb555500555555555555555555595555559999995555555
55555555555555555555555555555555555555555bb555bbb555bbbbbb5555555bbbbb555555555555b555555000555555555555555595555559999995555555
55555555555555555555555555555555555555555bb55bbb555555bbbb555555bbbbbb55555555b555b5555555550005555555555555955555599a9995555955
55555555555555555555555555555555555555555bbbbbb555555555bb55555bbb5bbb5555555bbbbbb5555555555550055555555559995555999a9999555555
555555555555555555555555555555555555555555bbbbbbb5555555555555bbb55bb55555555bbbbb5555555555555550055555555999555599aaa999555555
55555555555555555555555555555555555555555555bbbbbbbb55555555bbbbb55bb5555555bbbbbbb555555555555555500055555999955599aaa999555955
5555555555555555555555555555555555555555555bb55bbbbbbb55555bbbbbbb5bb555555bbb555bbbbbb5555555555555550005999995599aaaa999555955
555555555555555555555555555555555555555555bb555555bbbb5555bbb555bbbbb55555bbb5555bbbbbbb55555555555555555999a99559aaaaaa99955955
55555555555555555555777bbbb755555555555bbbbb55555555bbbb5bbb55555bbb555555bbb55555bb5bbbb555555555555555999aa99099aaaaaa99955955
55555555555555555bbbbbbbbbbbb555555555b5555bb5555555bbbbbbb5555555bb55555bbb555555bb555bb55555555555555999aaa9959aaaaaaa99959995
555555555555555bbbbbbbbbbbbbb755555555bb5555b555555bb5bbbb55555555bb55555bb5555555bb555bb555555bbb5555999aaa9999aaaaaaaa99959995
55555555555555bbbbbbbbbbbbbbbb755555555bb555555555bb555bb555555555bb5555bbb555555bbb555bb55555bbbb555999aaaa999aaaaaaaaa99959995
5555555555555bbbbbbbbbbbbbbbbbb75555b555bb55555bbbb555555555555555bb555bbb5555555bbb555bb55bbbbbb555999aaaaa99aaaaaaaaaa99999999
555555555555bbbbbb55555bbbbbbbbb5555bb555bb555bb5bb55555555555555bbb555bb55555555bb5555bbbbbbbb5555999aaaaa99aaaaaaaaaa999999999
55555555555bbbbbb5555555bbbbbbb775555b5555b55bb555b5555555bb55555bb555bbb5555555bbb5555bbbbb555555999aaaaaa9aaaaaaaaaaa9999a9999
5555555555bbbbb5555555555bbbbbb775555bb55bb5bb5b555b55555bb555555bbb55bb5555555bbb55555bbb555555599aaaaaaaaaaaaaaaaaaaa9999a9999
555555555bbbbbb55555555555bbbbbb755555bbbb55b555b5bbbbb5bb55555555bbbbbb55555bbbb555555bb555555599aaaaaaaaaaaaaaaaaaaa9999aaa999
555555555bbbbb555555555555bbbbbb55555555b555b5555bb555bb55555555555bbbbbbbbbbbbb555555bbb55555559aaaaaaaaaaaaaaaaaaaaa9999aaa999
55555555bbbbb55555bbb555555bbbbb5555555bb555b555555555bbb555555555555bbbbbbbbb5555555bbb55555559aaaaaaaaaaaaaaaaaaaaaa999aaaa999
55555555bbbbb5555bbbbb5555555555555555bb5555bbbb555555b5bbb555555555555bb55555555555bbbb55555559aaaaaaaaaaaaaaaaaaaaaaa9aaaaa996
5555555bbbbb55555bbbbbb555555555555557bbb5555b555555bb5555b5555555555555555555555555bbb55555555aaa888aaaaaaaaaaaaaaaaaaaaaaaa996
5555555bbbbb55555bbbbbbb5555555555577bbbbb55b555555bb555555555555555555555555555555bbb55555555aaaa888aaaaaaaaaaaaaaaaaaaaaaaa966
555555bbbbbb5555555bbbbbb5555555557bbbbbbbbb5555555b555555555555555555555555555555bbb555555555aaaa888aaaaaaaaaaaaaaaaaaaaaaaa966
555555bbbbbb55555555bbbbbbb555555bbbbbbbbbbbb555555bb555555555555555555555555555555bb555555555aaaa888aaaaaaa888aaaaaaaaaaaaaa966
555555bbbbbb555555555bbbbbbb5555bbbbb555bbbbb7555555555555555555555555555555555555555555555566aaaa888aaaaaaa888aaaaaaaaaaaaaa966
555555bbbbbb55555555bbbbbbbb555bbbbb55555bbbbb7555555555555555555555555555555555555555555556666aaaaaaaaaaaaa888aaaaaaaaaaaaaa966
555555bbbbbbb555555bbbbbbbbb55bbbbb5555555bbbb75555555bbbb5555555555555555555555555555555566666aaaaaaaaaaaaa888aaaaaaaaaaaaa9766
5555555bbbbbbb5555bbbbbbbbbb5bbbbb55555555bbbb755557bbbbbbbbb5555555555555555555555555555666666aaaaaaaaaaaaa888aaaaaaaaaaaaa9776
5555555bbbbbbbbbbbbbbbbbbbbb5bbbb5555555555bbb75557bbbbbbbbbbb755555555555555555555555556666666aaaaaaaaaaaaaaaaaaaaaaaaaaaa97776
5555555bbbbbbbbbbbbbbbbbbbbbbbbb55555555555bbb7557bbbbbbbbbbbbb555555555555555555555555666666666aaaaaaaaaaaaaaaaaaaaaaaaaa977776
55555555bbbbbbbbbbbbbbbbbbbbbbb555555555555bbb755bbbbbb555bbbbb755555555555555555555556666666666aaaaaaaaaaaaaaaaaaaaaaaaa9777776
555555555bbbbbbbbbbbbbbbb55bbbb55555555555bbbb55bbbbb5555555bbb7555555555555555555555666666666666aaaaaaaaaaaaaaaaaaaaaaa97777766
5555555555bbbbbbb555bbbb555bbb55555555555bbbbbbbbbb5555555555bb75555555555555555555556666666666666aaaaaaaaaaaaaaaaaaaaa977777766
55555555555555555555bbbb555bbb5555555555bbbbbbbbbbb5555555555bbb75555555555555555555666666666666666aaaaaaaaaaaaaaaaaa99777777666
555555555555555555555bb5555bbb555555555bbbbb55bbbb55555555555bbbb55555555555555555556656666666666666aaaaaaaaaaaaaa99977777777666
555555555555555555555555555bbbb555555bbbbbb555bbbb55555555555bbbb5555555bb7555555556666666666666666677aaaaaaaa999977777777776666
555555555555555555555555555bbbbb5555bbbbbb555bbbb555555555555bbb755555bbbb755555556665666666666666677777799999777777777777766666
5555555555555555555555555555bbbbbbbbbbbbb5555bbbb55555555555bbbb55555bbbbbb75555556655666666666666677777777777777777777777666666
5555555555555555555555555555bbbbbbbbbbbb5555bbbb55555555555bbbb55555bbbbbbb75555566655666666666666667777777777777777777776666666
555555555555555555555555555555bbbbbbbb555555bbbb5555555555bbbb55555bbbbbbbb55555566555666666666666667777777777777777777766666666
55555555555555555555555555555555555555555555bbb555555555bbbbbb5555bbbbbbbb755555566556666666666666666777777777777777776666666666
5555555555555555555555555555555555555555555bbbb555555555bbbbb55555bbbbbbb5555555565556666666666666666666777777777777666666666666
5555555555555555555555555555555555555555555bbbbb555555bbbbb55555bbbbbbbb55555555565556666666666666666666666666666666666666666666
5555555555555555555555555555555555555555555bbbbb55555bbbbb555555bbbbbbb555555555565556656666666666666666666666666666666666666666
5555555555555aa55555555555555555555555555555bbbbbbbbbbbbb555555bbbbbbb5555555555565556655666666666666666666666666666666666666665
5555aaaaaa55aaa55555555555555555555555555555bbbbbbbbbbbbb55555bbbbbbb55555555555565555655666666666666666666666666666666666666656
55aaaaaaaaaaaa55555555555555555555555555555555bbbbbbbbbbb55555bbbbbb555555555555565555655566666666666666666666666666666666665566
5aaaaaaaaaaaaa555555555555555555555555555555555bbbbbbbbbb5555bbbbb55555555555555565555656566666666666666666666666666666666555665
aaaaaaaaaaaaaaa55555555555555555555555555555555555555555bbbbb55bb555555555555555566555656655666666666666666666666666666555656556
aaaaaaaaaaaaaaaa5555555555555555555555555555555555555555bbbbb5555555555555555555566565556665555556666666666666666666655565555665
aaaaaaaaaaaaaaaa5555555555555555555555555555555555555555bbbb75555555555555555555556655565566556665555555556666665555556556566656
aaaaaaaaaaaaaaa75555555555555555555555555555555555555555bbbb75555555555555555555556656556655655666666666665555555555655555666565
aaaaaaaaaaaaaa0075555555555555555555555555555555555555555bbb55555555555555555555555665655666555556666666555555555655555666665665
aaaaaaaaaaaaa7007555555555555555555555555555555555555555555555555555555555555555555565665566665555555555555566665555566665556656

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6060606060606060606060606060606060606060606060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041404140414041404140414041404140414041404140410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051505150515051505150515051505150515051505150510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041404140414e4f4041404140414e4f4041404140414e4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051505150515e5f5051505150515e5f5051505150515e5f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041404140414041404140414041404140414041404140410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051505150515051505150515051505150515051505150510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4041404140414041404140414041404140414041404140410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6161616161616161616161616161616161616161616161610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000734007340073400734007340083400a3400d34010340163401e340213402234026340203002030000303003031f3001f30000303003031d3001d30000303003031a300003031d300003031f30000303
000200000764107641102411b2411524120241302411c60124000240002400024000280002400029000290002b0002b0002d0002d0002d0002b0002b0002b0002b0002900028000280002b00029000290002b000
0002000007373073730437303373093730837300373073033f1023f1051b3031530320303303030730307303103031b3031530320303303030730307303103031b3031530320303303030730307303103031b303
001800001b6540c6552a60406604066041800418004180041b604066040a6040b6041460414604206042060400604006041f6041f60400604006041d6041d60400604006041a604006041d604006041f60400604
000700003102131021300212e0212b02127021230211e0211002107021010010c001010011600107001010010900104001010011f00100001000011d0011d00100001000011a001000011d001000011f00100001
0004000022663226632016219162121620d162151631d00210002100021b0021b0021b00204002040020400210002100020400204002040020400210002100020300210002100021000210002100021000210002
000600000e35010350133501535019350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700002e45328453164530d45310403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403
000400003f500205002c500385003f50003500165003f5003f5003f5003f500235001450014500205002050000500005001f5001f50000500005001d5001d50000500005001a500005001d500005001f50000500
0002000028500205001d50022500285002a5002a50026500245002130022300233001430014300203002030000303003031f3001f30000303003031d3001d30000303003031a300003031d300003031f30000303
001200003c0053c005266051e6051a6051360511605116050f6050d6050a605106050a6050c6050d6050d6050c6050c605136050f6050f605136050f6050f605116050d6050a6050a6050d6050c6050d6050d605
000400001900119001190011900119001190010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
000400000100101001010010100101001010010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
000400001400014000100000d0000a0000900007000010002b0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d000300002400024000240002400024000240002400024000240002400028000
0004000013600176001b20017200131000e1000a1002b0002b0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d000300002400024000240002400024000240002400024000240002400028000
0004000022600226002010019100121000d100151001d00010000100001b0001b0001b00004000040000400010000100000400004000040000400010000100000300010000100001000010000100001000010000
010800001105211052050520500212052120521005210052040520400210052100520405204002040520400210052100520405204002040520400210052100520405204002040520400210052100520405204002
010800000305110051100511005114002120020d0001d00010633106351b0001b0001b00004000040000400010000100000400004000040000400010000100000305110051100511000110633106351060510605
01080000145050e3051a5051750514505263051a5051a3051450521305145052330514505143052030520305145550e3051a5551750514555263051a5551a3051455521305145052330514555143052030520305
01080000145050e3051a5051750514505263051a5051a30514505213051450523305145051430520305203051a55514505145550c505145550c5051a5551d5050050500505145550c5051a5551a5051f50500505
011000000c2500c2510a2510725103251002510025100202227521e7521c752207521e7521c7521d7521a752177521b75219752177521875218752187521875218752187020c7020c7020c7520c7520c7520c752
0110000000700007000070000700007000070000700007001675216752167521475214752147521175211752117520f7520f7520f7520c7520c7520c7520c7520c75200700007000070000752007520075200752
010400000107101071010710107101071010710000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
000400000d0710d0710d0710d0710d0710d0710000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
000400001907119071190711907119071190710d00000001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
010200000d0710d0710d0710d0710d0710d0710d0710d0710d0710d0710d0710d0710d0710d0710d0710d0710d0010d0010d0010d0010d0010d001286050d0012860528614286112861128615286052860528605
01040000286050d0010d0710d0710d0710d0010d0010d001286150000128605286052860528604286152860528605286050d0010d0010d0010d0010d0010d0012860528605000010000100001000012860528605
010200001000110014100211002110031100411004110051100511005110061100611006110061100611006110061100611006110061100611006110051100511005110041100411003110021100211001510001
0104000010001170141702117031170411705117061170711707117071170611705117041170311702117015130010f0140f0210f0310f0410f0510f0610f0710f0710f0610f0510f0410f0310f0210f0150c001
01020000010010101401011010210102101031010310104101041010510105101061010610107101071010710107101071010710106101061010510105101041010410103101031010210102101011010153f102
01020000110041105411052110521105211052110521105211052110521105211052110521105211052110521105211052110521105211052110521105211052110551b0021b0021b0021b0021b0021b0021b002
010400000f0040f0540f0520f0520f0520f0520f0520f0520f0550c0000c0000c0000c0000c0000c0000c00011004110541105211052110521105211052110521105511002110021100211002110021100211005
010200001205412054120541205412054120541205412054120541205412054120541205412054120541205411054110541105411054110541105411054110541105411054110541105411054110541105411054
010400003f1023f1053f1063f1043f1043f1043f1043f1043f1023f1053f1063f1043f114001033f1043f1143f1043f104001033f1140010300103001033f1123f1150010300103001033f1023f1050010300103
010200001261412621126211263112631126211262112615126041260512604126051260112601126011260112601126011260112601126011260112601126051260412605006040060400604006040060400604
010c00001865518603186031000518655186031860317005186551860318603230051865518603180532400318053180031800310603186532800318053280031805324003186531865318653280031805310005
010c00001805318003180031800318653240031805318003180532100318053180031865324003180532400318053180031800310603186532800318053280031805324003186531865318653280031805318003
010c00001805318003180031800318653240031805318003180532100318003180031865324003180532400318053180031805318053186532800318053280031805324003180031800318003180031800318003
010c0000185022450201502185021c0221c0221c0221f0021d0321d0321d032210021f0421f0421f042015021855201502015020150224552015020150201502185520150201502015022455224502245023f502
010c000018552245020150218502245520150224502015021855201502245020150224552015020150201502185520150201502015022455201502015020150218552015020150201502245521b5021b5021b502
010c00001f0021f0021f0021f0021f0221f0221f0221f002210322103221032210022304223042230420c00024050240002105024050110002105011000240502805011000260502400024050110002605028000
010c000028050120042405028050280002405026000280502b0502800029050120042805012004290502900024050240002105024050110002105011000240502805011000260502400024050110002605024000
010c000028050120042405028050280002405026000280502b0502800029050120042805012004290502b002280002b002280002600024004240022400224005240022400224005240022400224002240053c005
001200003c0453c005266051e6051a6051360511605116050f6050d6050a605106050a6050c6050d6050d6050c6050c605136050f6050f605136050f6050f605116050d6050a6050a6050d6050c6050d6050d605
000c0000240002400024000240002400024000240002400024000240002400024000280002400029000290002b0002b0002d0002d0002d0002b0002b0002b0002b0002900028000280002b00029000290002b000
000c00002b0002b0002b0002b000240002400024000240002400024000240000f0000e0000f000230002300021000210002300023000240002400024000260002600026000290002900029000290002900029000
010c000029000290002b0002b0002b0002b0002b0002b0002b0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d0002d000300002400024000240002400024000240002400024000240002400028000
000c000018002180021c0021c0022400224002240022800228002260022800226002240022410324002260022b0022b0022d0022b002290022b00229002260022400223002240022300228002260022400223002
001200001d00522005220051d0051d0052200522005220051d0052200522005240012400124005240051d005260052400529005260052400526005240051d0051a005180051d0052200122001220052200518005
000c00001f0051f0052600526005240052400529005290051f0051f0052600526005240052400529005290052800528005280052800529005260052b0052b0052800530005260053000529005280052400524005
000c00003000530005300052800528005280053000528005280052f1002d00528005280052d0052d00523005290051c0052d00523005280051d0052d0051f005280052d00526005290052b005260052600526005
000c00003000528005300052800528005280053000528005280052f1002d005280052f005300053000523005290051c0053000523005320051d005340051f005350052d005340052900532005260053000530005
000c00002b0052b0053200532005300053000535005350052b0052b00532005320053000530005350053500534005340053400534005350053200537005370053400530005320053000535005340053000524005
000c00002d0052d005280052800526005260052b0052b0052d0052d005280052800526005260052b0052b005290052800529005280052b0052b0052b0052b0052d005300052d005300052a005280052b00524005
000c00002f0052f0052d0052d0052f0052f0052d0052d0052f0052f0052d0052d0053000530005280052a0052b0052a0052a005280052900528005280052b0052600524005250052600524005280052300524005
000c00001f1041f1052610426105241042410529104291051f1041f1052610426105241042410529104291051c1051c1051c1051c1051d1051a1051f1051f1051c105181051a105181051d1051c1051810524105
000c000021104211051c1041c1051a1041a1051f1041f10521104211051c1041c1051a1041a1051f1041f1051d105281051d1051c1051f1051f1051f1051f105211051810521105181051e1051c1051f10524105
000c000023104231052110421105231042310521104211052310423105211042110524104241051c1041e1051f1051e1051e1051c1051d1051c1051c1051f1051a10518105191051a105181051c1050b10524105
001000000c2000c2010a2010720103201002010020100202227021e7021c702207021e7021c7021d7021a702177021b70219702177021870218702187021870218702187020c7020c7020c7020c7020c7020c702
0010000000700007000070000700007000070000700007001670216702167021470214702147021170211702117020f7020f7020f7020c7020c7020c7020c7020c70200700007000070000702007020070200702
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 10115044
00 10115144
00 10115044
00 10115144
00 10111244
00 10111344
00 10111244
02 10111344
01 19225244
00 1a5f5444
00 191b5644
00 1a1c4344
00 191d4344
00 1a4f4344
00 191e4344
00 1a1f4d44
00 19204e44
00 1a214f44
00 1d6b5044
02 1a6c5244
04 14157044
01 23262822
00 24272944
00 25272a44
04 2b424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

