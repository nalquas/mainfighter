-- title:  MainFighter
-- author: Nalquas
-- desc:   A rail-shooter set in a fake-3D world made for #FC_JAM.
-- script: lua
-- input:  gamepad
-- saveid: MainFighterGame



-- ============LICENSE=============
-- MainFighter - A rail-shooter set in a fake-3D world made for #FC_JAM.
-- Copyright (C) 2017-2018  Niklas 'Nalquas' Freund
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- =========END OF LICENSE=========





--[[
Dev Notes

Rough Dev-Log:
23.10.2017 (Day 1): Intro Sequence, Menu Code
24.10.2017 (Day 2): Ground Animation, Player Movement/Animation, Scrolling Background
25.10.2017 (Day 3): Shooting, Ground Enhancement (Stones), Overlay
Pause of Development for 4 Days
30.10.2017 (Day 4): Enemy Spawning, Relative Movement of Shots/Enemies to Ground, Enemy Destruction Logic
Pause of Development for 2 Days
02.11.2017 (Day 5): Basic Enemy AI, Improved Shooting Routine, Perfected relative Movement, Player Destruction Logic, Explosion Effects, Game Over Effect
03.11.2017 (Day 5.5): Game Over Menu Logic, Foundation for adding story intro
04.11.2017 (Day 6): Story Intro, Foundation for Boss of Level 1 (Mega-TriWing), Improved AI Behaviour
05.11.2017 (Day 7): Boss Behaviour, Title "MainFighter", Victory Menu, Sound Effects, Menu Background
Initial Release (Only Level 1 Available)
17.12.2018: Minor improvements on the old menu layout; Smooth ground scrolling, smooth intro; Minor rephrasing
18.12.2018: Reduce intensity of ground/intro bars flying by (made even non-epileptic people sick...); Added a crosshair for easier aiming
22.12.2018: Fixed pmem usage

Maximum length: 65.536 Symbols

Pmem Definition:
0     - empty
1     - Inverted Y Axis or not?
2-255 - Empty

Sounds:
0: BEEP / Boss Spawning (Make it somewhat silent, PLEASE)
1: Engine
2: Shot
3: Explosion
4: Player was hit
5-62: Random Noise / Unassigned
63: Typing

Play Area Definition:
X: 0-420 (Left-Right) (at offsetFactor=0.75)
Y: 0-136 (Up-Down)
Z= 0-128 (Distant-Near) (Player at 128)

Levels:
0 - Short Story Introduction (No Gameplay - It's a "Cutscene"!)
1 - Earth-like planet, keep it somewhat easy
2 - Space (Asteroid Field?)
3 - Final Level, Alien World with geometric forms (Triangles? O.o), make it hard

TO-DO:
+Replace printCenter commands with manually positioned print commands (saves space)

--]]

-- VARIABLES: FPS
local FPS={value =0,frames =0,lastTime=-1000}
function FPS:getValue()
  if (time()-self.lastTime <= 1000) then
    self.frames=self.frames+1
  else 
    self.value=self.frames
    self.frames=0
    self.lastTime=time()
  end
  return self.value
end

-- VARIABLES: DEVELOPER ONLY
versionNr="1.1"
releaseDate="22.12.2018"
debug=false

-- VARIABLES: GENERAL
mode=-1
t=0
invertedY=false
if pmem(1)>0 then
	invertedY=true
end

-- VARIABLES: INTRO
intro={text="Nalquas presents: An update for...",textDis=0,tDelay1=0,name="MainFighter - A game for #FC_JAM",nameDis=0,tDelay2=0,Factor=0,FactorChange=0.15}

-- VARIABLES: MENU
menu={mode=1,maxMode=3,tClick=0}

-- VARIABLES: GAME
spawnFactor=82
offsetFactor=0.75
player={alive=true,lastHitTime=0,shotDamage=2.5,speed=1,hp=100,energy=100,x=104,y=52,z=128,spdX=0,spdY=0,spdZ=0.3,groundFactor=0,tShot=0,gameOverCircleSize=0}
levelData={}
-- Level 1:
levelData[1]={ground={c1=11,c2=5},props={c1=7,c2=3},spawnedData={triWing=0,megaTriWing=0},spawnData={triWing=49,megaTriWing=1}}

-- Level 2:
levelData[2]={ground={c1=11,c2=5},props={c1=7,c2=3},spawnedData={triWing=0,megaTriWing=0},spawnData={triWing=25,megaTriWing=0}}

-- Level 3:
levelData[3]={ground={c1=1,c2=6},props={c1=9,c2=4},spawnedData={triWing=0,megaTriWing=0},spawnData={triWing=25,megaTriWing=0}}

level=1
props={}
for i=0,50 do
	sx=math.random(-50,550)
	sy=70
	props[i]={sx=sx,sy=sy,x=sx,y=sy,spdX=0,spdY=player.spdZ}
	for j=1,math.random(1,100) do
		props[i].spdY=props[i].spdY*1.07333333
		props[i].y=props[i].y+props[i].spdY
		if props[i].y>136 then
			props[i].y=props[i].sy
			props[i].spdY=player.spdZ
		end
	end
end
shots={speed=4,cost=11}
enemyData={}
enemyData[1]={correctnessFactor=60,hp=1,speed=0.88,tShotMax=95,sprite=300,spriteSize={x=2,y=2},doSpriteChange=true,size={x=16,y=16,z=16}} -- TriWing
enemyData[-1]={correctnessFactor=85,hp=100,speed=0.86,tShotMax=80,sprite=365,spriteSize={x=3,y=4},doSpriteChange=false,size={x=24,y=27,z=16}} -- Mega-TriWing
enemies={}
explosions={}
gameOverMenu={mode=1,maxMode=2,tClick=0}

-- VARIABLES: STORY (a.k.a. Level 0)
story={tStart=0,tText=60,tBetweenTexts=60,progress=0,maxText=11}
story[1]={text="04.11.2743, Somewhere in Deep Space..."}
story[2]={text="Droid X2: ...so you're saying they're\nsearching for a \"main character\"?"}
story[3]={text="You: Indeed, they're searching one\nfor some \"video game\"."}
story[4]={text="Droid X2: I've got no idea what\nthat's supposed to be,"}
story[5]={text="Droid X2: ...but you'll never be\nthe main character!"}
story[6]={text="You: Hah, you don't know who you're talking with then!"}
story[7]={text="Droid X2: Alright... let's make a\ndeal: If you beat all my flying drones,"}
story[8]={text="Droid X2: ...then you get to be the\nmain character,"}
story[9]={text="Droid X2: ...otherwise,\nI'll be the lucky one."}
story[10]={text="You: Deal! Haha! That will be easy,\nyou'll never be the main character!"}
story[11]={text="Droid X2: We'll see..."}

function Background(bgrValue)
	poke(0x03FF8, bgrValue) -- Set Background
end

function printCenter(text,x,y,color,fixed,smallfont)
	scale=1
	width=print(text,0,-12,15,fixed,1,smallfont)
	print(text,(((x*2)-width)//2)+1,y,color,fixed,scale,smallfont)
end

function CountInString(text,substring)
	count=0
	for i in string.gmatch(text,substring) do
		count=count+1
	end
	return count
end

fancyMemory={text="Placeholder",textDis=12,x=0,y=0,c=15,centered=true,size=1}
function printFancyUpdate(text,x,y,c,centered,size)
	y=y-(CountInString(text,"\n")*4)
	fancyMemory={text=text,textDis=0,x=x,y=y,c=c,centered=centered,size=size}
end
function printFancy()
	if fancyMemory.centered then
		printCenter(string.sub(fancyMemory.text,0,fancyMemory.textDis),fancyMemory.x,fancyMemory.y,fancyMemory.c,true)
	else
		print(string.sub(fancyMemory.text,0,fancyMemory.textDis),fancyMemory.x,fancyMemory.y,fancyMemory.c,true,fancyMemory.size)
	end
	
	if fancyMemory.textDis<string.len(fancyMemory.text) then
		if (t%5==0) then
			fancyMemory.textDis=fancyMemory.textDis+1
			sfx(63,"E-4",7,0,15,0)
		end
	end
end

function StopSfx()
	for i=0,3 do
		sfx(-1,0,-1,i,15,0)
	end
end

introDark={}
for i=0,15 do
	introDark[i]={num=i,y=i^2}
end
function IntroFlying()
	for j=-1,1,2 do
		if j==-1 then
			rect(0,0,240,64,1)
		else
			rect(0,73,240,68,1)
		end
		for i=0,#introDark do
			rect(0,68+((5+(2*introDark[i].y))*j),240,(math.sqrt(introDark[i].y)+0.2)*2.5,6)
			if j==1 then
				introDark[i].y=(introDark[i].num*1.53333)^2
				introDark[i].num=introDark[i].num+0.05
				if introDark[i].num>#introDark then introDark[i].num=0 end
			end
		end
	end
end

groundDark={}
for i=0,15 do
	groundDark[i]={num=i,y=i^2}
end
function DrawGround()
	rect(0,70,240,66,11)
	for i=0,#groundDark do
		rect(0,70+(2*groundDark[i].y),240,(math.sqrt(groundDark[i].y)+0.2)*2.5,5)
		groundDark[i].y=(groundDark[i].num*1.43333)^2
		groundDark[i].num=groundDark[i].num+0.05
		if groundDark[i].num>#groundDark then groundDark[i].num=0 end
	end
end

function MakeShot(x,y,byPlayer)
	spdY=0.29032132616129
	if byPlayer then spdY=-3 end
	z=0
	if byPlayer then z=128 end
	return {alive=true,byPlayer=byPlayer,x=x,y=y,z=z,spdY=spdY}
end
shots[0]=MakeShot(-100,-100,true)
shots[0].alive=false

function MakeEnemy(id)
	
	newBtn={}
	for i=0,7 do
		newBtn[i]=false
	end
	return {alive=false,hp=enemyData[id].hp,spawning=true,spawnVisible=false,tSpawn=0,id=id,speed=enemyData[id].speed,sprite=enemyData[id].sprite,size=enemyData[id].size,x=math.random(32,372),y=math.random(0,64),z=enemyData[id].size.z,spdX=0,spdY=0,spdZ=0,btn=newBtn,tShot=0}
	
end
enemies[0]=MakeEnemy(1)
enemies[0].spawning=false
enemies[0].alive=false

function MakeExplosion(x,y,maxSize,sizeFactor)
	
	return {alive=true,x=x,y=y,size=1,maxSize=maxSize,sizeIncrease=sizeFactor}
end
explosions[0]=MakeExplosion(-100,-100)
explosions[0].alive=false

function CountEnemies()
	j=0
	for i=0,#enemies do
		if enemies[i].alive or enemies[i].spawning then
			j=j+1
		end
	end
	k=(levelData[level].spawnData.triWing-levelData[level].spawnedData.triWing)+(levelData[level].spawnData.megaTriWing-levelData[level].spawnedData.megaTriWing)+j
	return k
end

function ResetGameValues()
	player={alive=true,lastHitTime=0,shotDamage=2.5,speed=1,hp=100,energy=100,x=104,y=52,z=128,spdX=0,spdY=0,spdZ=0.3,groundFactor=0,tShot=0,gameOverCircleSize=0}
	for i=1,3 do
		levelData[i].spawnedData={triWing=0,megaTriWing=0}
	end
	for i=1,#shots do
		shots[i]=nil
	end
	for i=1,#explosions do
		explosions[i]=nil
	end
	for i=1,#enemies do
		enemies[i]=nil
	end
	fancyMemory={text="Placeholder",textDis=12,x=0,y=0,c=15,centered=true,size=1}
	story.tText=60
	story.tStart=0
	story.progress=0
	t=0
end

-- Message in Console:
trace("\n\n-----------------------------\n      Nalquas presents:\n      MainFighter V"..versionNr.."\n  Last updated: "..releaseDate.."\nhttps://nalquas.itch.io/mainfighter\n-----------------------------\n")

-- Change palette entry 12 each line to have a good sky gradient
function scanline(row)
	--Possible colors: (B is always X-row*3)
	--  R   G   B
	-- 000-000-255 Pure blue (looks artificial)
	-- 096-064-255 Sundown, early
	-- 128-064-255 Sundown, mid
	-- 128-096-255 Morning

	-- skygradient (palette position 12)
	poke(0x3fe4,64) --r
	poke(0x3fe5,64+row*2.5) --g
	poke(0x3fe6,200) --b
end

function TIC()
	if mode==-1 then
		-- ===================
		-- MODE: EPILEPSY WARNING
		-- ===================
		
		if t>120 then
			if btn(4) then
				mode=0
				t=0
			end
		end
		
		Background(0)
		cls(0)
		
		tri(119,15,79,80,159,80,14)
		rect(114,27,11,36,0)
		rect(114,68,11,10,0)
		
		print("EPILEPSY WARNING!",21,85,15,true,2)
		print("If you're prone to epileptic attacks,\n       do not play this game.",14,99,15,true,1)
		if t>120 then
			print("Press Z to continue...",55,120,15,true,1)
		end
		
	elseif mode==0 then
		-- ===================
		-- MODE: INTRO
		-- ===================
		
		Background(3)
		cls(0)
		
		IntroFlying() -- Render Flying effect
		
		if intro.tDelay1<30 then
			printCenter(string.sub(intro.text,0,intro.textDis),119,66,15,true) -- Show intro.text
		else
			printCenter(string.sub(intro.name,0,intro.nameDis),119,66,15,true) -- Show intro.name
		end
		
		if intro.textDis<string.len(intro.text) then
			if (t%5==0) then
				intro.textDis=intro.textDis+1
				sfx(63,"E-4",7,0,15,0)
			end
		elseif intro.tDelay1>=30 then
			if intro.nameDis<string.len(intro.name) then
				if (t%5==0) then
					intro.nameDis=intro.nameDis+1
					sfx(63,"E-4",7,0,15,0)
				end
			elseif intro.tDelay2>=90 then
				mode=1
			else
				intro.tDelay2=intro.tDelay2+1
			end
		else
			intro.tDelay1=intro.tDelay1+1
		end
		
		if debug then
			print("intro.textDis "..intro.textDis.."/"..string.len(intro.text).."\nintro.nameDis "..intro.nameDis.."/"..string.len(intro.name).."\nintro.tDelay1 "..intro.tDelay1.."/30\nintro.tDelay2 "..intro.tDelay2.."/90")
		end
		
	elseif mode==1 then
		-- ===================
		-- MODE: MENU
		-- ===================
		
		if menu.tClick>10 then
			menu.tClick=0
			if btn(0) or btn(1) then
				if btn(0) then
					menu.mode=menu.mode-1
				elseif btn(1) then
					menu.mode=menu.mode+1
				end
				
				-- Menu Looping
				if menu.mode<1 then
					menu.mode=menu.maxMode
				elseif menu.mode>menu.maxMode then
					menu.mode=1
				end
			elseif btn(2) or btn(3) or btn(4) or btn(5) or btn(6) or btn(7) then
				if menu.mode==1 then
					ResetGameValues()
					level=0
					mode=2
				elseif menu.mode==2 then
					invertedY=not invertedY
					if invertedY then
						pmem(1,1)
					else
						pmem(1,0)
					end
				elseif menu.mode==3 then
					exit()
				else
					menu.mode=1
				end
			else
				menu.tClick=11
			end
		end
		
		-- Normal Rendering:
		Background(3)
		cls(0)
		
		IntroFlying()
		
		-- Menu Rendering:
		c={}
		for i=1,menu.maxMode do
			if i==menu.mode then
				if (math.floor(t/8)%2==0) then
					c[i]=14
				else
					c[i]=9
				end
			else
				c[i]=15
			end
		end
		print("MainFighter",53,34,15,true,2)
		printCenter("Start a new run",119,56,c[1],false)
		printCenter("Invert Y-Axis ["..tostring(invertedY).."]",119,66,c[2],false)
		printCenter("Exit to TIC-80",119,76,c[3],false)
		
		printCenter("(C) Nalquas, 2017-2018",120,120,15,false)
		printCenter("GNU General Public License Version 3",120,127,15,false)
		print("V"..versionNr,4,4,15,false,1)
		
		-- Time Incrementation:
		if menu.tClick<=10 then
			menu.tClick=menu.tClick+1
		end
		
	elseif mode==2 then
		-- ===================
		-- MODE: GAME
		-- ===================
		if level==0 then
			-- Show Story Intro
			Background(2)
			cls(0)
			
			if fancyMemory.textDis>=string.len(fancyMemory.text) then
				if story.tText>=story.tBetweenTexts then
					if story.progress<story.maxText then
						story.progress=story.progress+1
						printFancyUpdate(story[story.progress].text,107,64,15,true,1)
						story.tText=0
					else
						printCenter("Press Z to begin...",111,96,15,true)
						if btn(4) then
							ResetGameValues()
							level=1
						end
					end
				else
					story.tText=story.tText+1
				end
			end
			
			printFancy()
			
			if story.tStart>60 and story.progress<story.maxText then
				print("Press X to skip...",132,128,15,true,1)
				if btn(5) then
					ResetGameValues()
					level=1
				end
			end
			
			story.tStart=story.tStart+1
			
		else
			if player.alive then
				-- INPUT AND PLAYER HANDLING
				if player.alive then
					a=0
					b=1
					if invertedY then
						a=1
						b=0
					end
					if btn(a) then
						if player.spdY>=0 then
							player.spdY=-(player.speed/10)
						else
							player.spdY=player.spdY*((player.speed/10)*12)
						end
					elseif btn(b) then
						if player.spdY<=0 then
							player.spdY=(player.speed/10)
						else
							player.spdY=player.spdY*((player.speed/10)*12)
						end
					else
						if player.spdY<(player.speed/10) and player.spdY>-(player.speed/10) then
							player.spdY=0
						else
							player.spdY=player.spdY/((player.speed/10)*12)
						end
					end
					
					if btn(2) then
						if player.spdX>=0 then
							player.spdX=-(player.speed/10)
						else
							player.spdX=player.spdX*((player.speed/10)*12)
						end
					elseif btn(3) then
						if player.spdX<=0 then
							player.spdX=(player.speed/10)
						else
							player.spdX=player.spdX*((player.speed/10)*12)
						end
					else
						if player.spdX<(player.speed/10) and player.spdX>-(player.speed/10) then
							player.spdX=0
						else
							player.spdX=player.spdX/((player.speed/10)*12)
						end
					end
					
					if player.tShot>10 then
						if player.energy>=shots.cost then
							if btn(4) then
								shots[#shots+1]=MakeShot((player.x+16)+(offsetFactor*player.x),(player.y+16),true)
								player.tShot=0
								player.energy=player.energy-shots.cost
								sfx(2,"C-4",32,1,15,0)
							end
						end
					else
						player.tShot=player.tShot+1
					end
					
					if player.energy<0 then
						player.energy=0
					elseif player.energy<100 then
						player.energy=player.energy+0.5
					elseif player.energy>100 then
						player.energy=100
					end
					
					if player.spdY<-player.speed then
						player.spdY=-player.speed
					elseif player.spdY>player.speed then
						player.spdY=player.speed
					end
					if player.spdX<-player.speed then
						player.spdX=-player.speed
					elseif player.spdX>player.speed then
						player.spdX=player.speed
					end
					
					player.x=player.x+player.spdX
					player.y=player.y+player.spdY
					
					if player.x<0 then
						player.x=0
					elseif player.x>208 then
						player.x=208
					end
					if player.y<0 then
						player.y=0
					elseif player.y>104 then
						player.y=104
					end
				end
				
				-- Spawn Routine
				if math.random(0,spawnFactor)==1 then
					if levelData[level].spawnedData.triWing<levelData[level].spawnData.triWing then
						enemies[#enemies+1]=MakeEnemy(1)
						levelData[level].spawnedData.triWing=levelData[level].spawnedData.triWing+1
					end
				end
				
				-- Boss Spawn Routine
				if CountEnemies()==1 and levelData[level].spawnedData.megaTriWing<levelData[level].spawnData.megaTriWing then
					enemies[#enemies+1]=MakeEnemy(-1)
					enemies[#enemies].x=120+(player.x*offsetFactor)
					levelData[level].spawnedData.megaTriWing=levelData[level].spawnedData.megaTriWing+1
				end
				
				-- Enemy Handling
				for i=0,#enemies do
					if enemies[i].alive then
						for j=4,7 do
							-- Set all pressed buttons to false again (except movement 0-3)
							enemies[i].btn[j]=false
						end
						
						-- Enemy AI
						if math.random(1,100)==1 then
							-- Cancel Movement Completely
							for j=0,3 do
								enemies[i].btn[j]=false
							end
						end
						if math.random(1,(math.floor(math.abs(math.floor(enemies[i].y-(player.y-36.9501653-(enemies[i].size.y/2))))/3)+1))==1 then
							-- Random Movement Up/Down; More Likely to activate if near to player
							for j=0,1 do
								enemies[i].btn[j]=false
							end
							selBtn=0
							if (enemies[i].y-player.y)<=0 then
								if math.random(1,100)<enemyData[enemies[i].id].correctnessFactor then
									selBtn=1
								else
									selBtn=0
								end
							else
								if math.random(1,100)<enemyData[enemies[i].id].correctnessFactor then
									selBtn=0
								else
									selBtn=1
								end
							end
							
							enemies[i].btn[selBtn]=true
						end
						if math.random(1,(math.floor(math.abs(math.floor(enemies[i].x-(player.x+(player.x*offsetFactor))))/3)+1))==1 then
							-- Random Movement Left/Right; More Likely to activate if near to player
							for j=2,3 do
								enemies[i].btn[j]=false
							end
							selBtn=2
							if (enemies[i].x-(player.x+(player.x*offsetFactor)))<=0 then
								if math.random(1,100)<enemyData[enemies[i].id].correctnessFactor then
									selBtn=3
								else
									selBtn=2
								end
							else
								if math.random(1,100)<enemyData[enemies[i].id].correctnessFactor then
									selBtn=2
								else
									selBtn=3
								end
							end
							enemies[i].btn[selBtn]=true
						end
						if math.random(1,(math.abs(math.floor(enemies[i].x-(player.x+(player.x*offsetFactor))))+(math.abs(math.floor(enemies[i].x-(player.x+(player.x*offsetFactor)))))+20))==1 then
							enemies[i].btn[4]=true
						end
						
						-- Enemy Routine
						if enemies[i].btn[0] then
							if enemies[i].spdY>=0 then
								enemies[i].spdY=-(enemies[i].speed/10)
							else
								enemies[i].spdY=enemies[i].spdY*((enemies[i].speed/10)*12)
							end
						elseif enemies[i].btn[1] then
							if enemies[i].spdY<=0 then
								enemies[i].spdY=(enemies[i].speed/10)
							else
								enemies[i].spdY=enemies[i].spdY*((enemies[i].speed/10)*12)
							end
						else
							if enemies[i].spdY<(enemies[i].speed/10) and enemies[i].spdY>-(enemies[i].speed/10) then
								enemies[i].spdY=0
							else
								enemies[i].spdY=enemies[i].spdY/((enemies[i].speed/10)*12)
							end
						end
						
						if enemies[i].btn[2] then
							if enemies[i].spdX>=0 then
								enemies[i].spdX=-(enemies[i].speed/10)
							else
								enemies[i].spdX=enemies[i].spdX*((enemies[i].speed/10)*12)
							end
						elseif enemies[i].btn[3] then
							if enemies[i].spdX<=0 then
								enemies[i].spdX=(enemies[i].speed/10)
							else
								enemies[i].spdX=enemies[i].spdX*((enemies[i].speed/10)*12)
							end
						else
							if enemies[i].spdX<(enemies[i].speed/10) and enemies[i].spdX>-(enemies[i].speed/10) then
								enemies[i].spdX=0
							else
								enemies[i].spdX=enemies[i].spdX/((enemies[i].speed/10)*12)
							end
						end
						
						if enemies[i].tShot<enemyData[enemies[i].id].tShotMax then
							enemies[i].tShot=enemies[i].tShot+1
						else
							if enemies[i].btn[4] then
								if enemies[i].id==-1 then
									shots[#shots+1]=MakeShot((enemies[i].x+(enemies[i].size.x/4)),(enemies[i].y+((enemies[i].size.y/4)*3)),false) -- Shot L
									shots[#shots+1]=MakeShot((enemies[i].x+(enemies[i].size.x/2)),(enemies[i].y+(enemies[i].size.y/4)),false) -- Shot M
									shots[#shots+1]=MakeShot((enemies[i].x+((enemies[i].size.x/4)*3)),(enemies[i].y+((enemies[i].size.y/4)*3)),false) -- Shot R
									sfx(2,"C-3",32,1,15,0)
								else
									shots[#shots+1]=MakeShot((enemies[i].x+(enemies[i].size.x/2)),(enemies[i].y+(enemies[i].size.y/2)),false)
									sfx(2,"C-5",32,1,12,0)
								end
								enemies[i].tShot=0
							end
						end
						
						if enemies[i].spdY<-enemies[i].speed then
							enemies[i].spdY=-enemies[i].speed
						elseif enemies[i].spdY>enemies[i].speed then
							enemies[i].spdY=enemies[i].speed
						end
						if enemies[i].spdX<-enemies[i].speed then
							enemies[i].spdX=-enemies[i].speed
						elseif enemies[i].spdX>enemies[i].speed then
							enemies[i].spdX=enemies[i].speed
						end
						
						enemies[i].x=enemies[i].x+enemies[i].spdX
						enemies[i].y=enemies[i].y+enemies[i].spdY
						
						if enemies[i].x<enemies[i].size.x/2 then
							enemies[i].x=enemies[i].size.x/2
						elseif enemies[i].x>((240+(240*offsetFactor))-enemies[i].size.x*3) then
							enemies[i].x=((240+(240*offsetFactor))-enemies[i].size.x*3)
						end
						if enemies[i].y<0 then
							enemies[i].y=0
						elseif enemies[i].y>(92-enemies[i].size.y) then
							enemies[i].y=(92-enemies[i].size.y)
						end
					end
				end
				
				-- Shot Handling
				for i=0,#shots do
					if shots[i].alive then
						if shots[i].byPlayer then
							shots[i].spdY=shots[i].spdY/1.07333333
						else
							shots[i].spdY=shots[i].spdY*1.07333333
						end
						shots[i].y=shots[i].y+shots[i].spdY
						if shots[i].byPlayer then
							shots[i].z=shots[i].z-shots.speed
						else
							shots[i].z=shots[i].z+shots.speed
						end
						if shots[i].z<0 or shots[i].y>136 then
							shots[i].alive=false
						end
						if shots[i].byPlayer then
							for j=0,#enemies do
								if enemies[j].alive then
									if shots[i].x>=enemies[j].x and shots[i].y>=enemies[j].y and shots[i].z>=enemies[j].z and shots[i].x<=enemies[j].x+enemies[j].size.x and shots[i].y<=enemies[j].y+enemies[j].size.y and shots[i].z<=enemies[j].z+enemies[j].size.z then
										enemies[j].hp=enemies[j].hp-player.shotDamage
										shots[i].alive=false
										explosions[#explosions+1]=MakeExplosion(shots[i].x,shots[i].y,3,1.003333)
										break
									end
								end
							end
						else
							-- Collision with player
							if player.hp>0 and player.alive then
								if shots[i].x-(offsetFactor*player.x)>=player.x and shots[i].y>=player.y and shots[i].z>=player.z-16 and shots[i].x-(offsetFactor*player.x)<=player.x+32 and shots[i].y<=player.y+32 and shots[i].z<=player.z+16 then
									player.hp=player.hp-5
									shots[i].alive=false
									sfx(4,"F-3",16,3,15,0)
									player.lastHitTime=t
								end
							end
						end
					end
				end
				
				-- Enemies: Death
				for j=0,#enemies do
					if enemies[j].alive and enemies[j].hp<=0 then
						enemies[j].alive=false
						sizeFactor=1
						if enemies[j].id==1 then sizeFactor=1.03333 elseif enemies[j].id==-1 then sizeFactor=1.33333 end
						explosions[#explosions+1]=MakeExplosion(enemies[j].x+(enemies[j].size.x/2),enemies[j].y+(enemies[j].size.y/2),((enemies[j].size.x+enemies[j].size.y)/2.5),sizeFactor)
						sfx(3,"E-3",32,2,15,0)
					end
				end
				
				if player.alive and player.hp<=0 then
					StopSfx()
					music(1,-1,-1,false)
					sfx(3,"F-2",64,2,15,-2)
					player.alive=false
				end
				
				-- RENDERING
				Background(0)
				--cls(8)
				--map(0,0+((level-1)*17),60,11,(-player.x)/5,((player.y)/40)-10,-1,1) -- Sky
				cls(12) --Clear but do sky at the same time (see scanline)
				map(0,12+((level-1)*17),60,2,(-player.x)/3,((player.y)/30)+55,13,1) -- Mountains
				map(0,15+((level-1)*17),60,1,(-player.x)/2.5,((player.y)/30)+63,13,1) -- Trees
				
				DrawGround()
				
				-- Stones:
				for i=0,#props do
					props[i].spdX=0
					props[i].x=props[i].x+props[i].spdX
					props[i].spdY=props[i].spdY*1.027499995 --1.01833333 --1.03666666 --1.07333333
					props[i].y=props[i].y+props[i].spdY
					if props[i].y>136 then
						props[i].x=math.random(-50,550)
						props[i].y=props[i].sy
						props[i].spdY=player.spdZ
					end
					r=math.floor(((props[i].y-70)/22)+1)
					
					clip(props[i].x-(1.2*player.x)-r,props[i].y-r,(r*2)+1,r)
					circ(props[i].x-(1.2*player.x),props[i].y,r-1,levelData[level].props.c1)
					circb(props[i].x-(1.2*player.x),props[i].y,r,levelData[level].props.c2)
					clip()
				end
				
				-- Explosions (Enemies):
				for i=0,#explosions do
					if explosions[i].alive then
						circ(explosions[i].x-(offsetFactor*player.x),explosions[i].y,explosions[i].size,6)
						circ(explosions[i].x-(offsetFactor*player.x),explosions[i].y,explosions[i].size-1,14)
						
						explosions[i].sizeIncrease=explosions[i].sizeIncrease/1.055555
						explosions[i].size=explosions[i].size+explosions[i].sizeIncrease
						if explosions[i].size>explosions[i].maxSize then
							explosions[i].alive=false
						end
					end
				end
				
				-- Enemies:
				for i=0,#enemies do
					if enemies[i].alive then
						xSpr=0
						ySpr=0
						if enemyData[enemies[i].id].doSpriteChange then
							if enemies[i].spdX<=-(enemies[i].speed/2) then
								xSpr=-2 -- Left
							elseif enemies[i].spdX>=(enemies[i].speed/2) then
								xSpr=2 -- Right
							end
							if enemies[i].spdY <=-(enemies[i].speed/2) then
								ySpr=-32 -- Up
							elseif enemies[i].spdY>=(enemies[i].speed/2) then
								ySpr=32 -- Down
							end
						end
						spr(enemies[i].sprite+xSpr+ySpr,math.floor(enemies[i].x)-(offsetFactor*player.x),math.floor(enemies[i].y),15,1,0,0,enemyData[enemies[i].id].spriteSize.x,enemyData[enemies[i].id].spriteSize.y)
					elseif enemies[i].spawning then
						if enemies[i].tSpawn%5==0 then
							enemies[i].spawnVisible=not enemies[i].spawnVisible
						end
						if enemies[i].spawnVisible then
							spr(enemies[i].sprite,math.floor(enemies[i].x)-(offsetFactor*player.x),math.floor(enemies[i].y),15,1,0,0,enemyData[enemies[i].id].spriteSize.x,enemyData[enemies[i].id].spriteSize.y)
							if CountEnemies()==1 then
								sfx(0,"F-2",2,3,15,0)
							else
								if t>player.lastHitTime+16 then
									sfx(0,"F-2",2,3,9,0)
								end
							end
						end
						if enemies[i].tSpawn>120 then
							enemies[i].spawning=false
							enemies[i].alive=true
						else
							enemies[i].tSpawn=enemies[i].tSpawn+1
						end
					end
				end
				
				if player.alive then
					spr(511,math.floor(player.x)+13,math.floor(player.y)-19,0,1,0,0,1,1) --Crosshair
				end
				
				-- Player's Shots (Behind Player):
				for i=0,#shots do
					if shots[i].alive then
						if shots[i].z<=player.z then
							circ(shots[i].x-(offsetFactor*player.x),shots[i].y,math.floor((shots[i].z/128)*5)-1,14)
						end
					end
				end
				
				-- Player:
				if player.alive then
					xSpr=0
					if player.spdX<=-0.8 then
						xSpr=-4 -- Very left
					elseif player.spdX<=-0.4 then
						xSpr=-2 -- Left
					elseif player.spdX>=0.8 then
						xSpr=4 -- Very Right
					elseif player.spdX>=0.4 then
						xSpr=2 -- Right
					end
					ySpr=0
					if player.spdY <=-0.5 then
						ySpr=-32 -- Up
					elseif player.spdY>=0.5 then
						ySpr=32 -- Down
					end
					spr(292+xSpr+ySpr,math.floor(player.x),math.floor(player.y),15,2,0,0,2,2) --Player
					if (math.abs(xSpr)+math.abs(ySpr))>=0.8 then
						sfx(1,"C#4",-1,0,8,0)
					else
						sfx(1,"C-4",-1,0,8,0)
					end
				end
				
				-- Player's Shots (In Front of Player):
				for i=0,#shots do
					if shots[i].alive then
						if shots[i].z>player.z then
							circ(shots[i].x-(offsetFactor*player.x),shots[i].y,math.floor((shots[i].z/128)*5)-1,14)
						end
					end
				end
				
				-- OVERLAY
				-- HP bar:
				rect(0,129,74,7,1) -- Frame
				rect(13,130,60,5,6) -- Red 6
				rect(13,130,(player.hp/100)*60,5,11) -- Green 11
				print("HP",1,130,15,true,1)
				
				-- Energy bar:
				rect(166,129,74,7,1) -- Frame
				rect(167,130,60,5,4) -- Brown
				rect(167,130,(player.energy/100)*60,5,14) -- Yellow
				print("EN",228,130,15,true,1)
				
				-- Level Display:
				--printCenter("Level "..level,119,2,15,true)
				
				
				-- Boss HP Bar:
				if CountEnemies()<=1 then
					rect(0,0,86,7,1) -- Frame
					rect(25,1,60,5,6) -- Red 6
					rect(25,1,(enemies[#enemies].hp/100)*60,5,11) -- Green 11
					print("BOSS",1,1,15,true,1)
				else
					-- Remaining Enemies:
					print("Remaining: "..CountEnemies(),2,2,15,false,1)
				end
				
				-- FPS Display:
				print("FPS: " .. FPS:getValue(),202,2,15)
				
				if debug then
					print("player.x "..player.x.."\nplayer.y "..player.y.."\nplayer.spdX "..player.spdX.."\nplayer.spdY "..player.spdY.."\nplayer.tShot "..player.tShot.."\nplayer.hp "..player.hp.."\nplayer.energy "..player.energy.."\nActual X: "..player.x+(offsetFactor*player.x).."\nspawnData "..levelData[level].spawnData.triWing.."\nspawnedData "..levelData[level].spawnedData.triWing,0,50)
				end
				
				-- CHANGE TO GAMEOVER IF ENEMIES ARE DEAD
				if CountEnemies()<=0 then
					StopSfx()
					music(2,-1,-1,false)
					sfx(3,"F-2",64,2,15,-2)
					player.alive=false
				end
			else
				-- DO NOT USE cls() UNTIL SCREEN COMPLETELY OCCUPIED! OTHERWISE, EFFECT IS RUINED!
				if player.gameOverCircleSize<=228 then
					if CountEnemies()>0 then
						player.gameOverCircleSize=player.gameOverCircleSize+1.5
						circ(player.x+16,player.y+16,player.gameOverCircleSize,6)
						circ(player.x+16,player.y+16,player.gameOverCircleSize-1,14)
					else
						player.gameOverCircleSize=player.gameOverCircleSize+1
						circ(enemies[#enemies].x+(enemies[#enemies].size.x/2)-(player.x*offsetFactor),enemies[#enemies].y+16,player.gameOverCircleSize,6)
						circ(enemies[#enemies].x+(enemies[#enemies].size.x/2)-(player.x*offsetFactor),enemies[#enemies].y+16,player.gameOverCircleSize-1,14)
					end
				elseif player.gameOverCircleSize>234 then
					Background(0)
					if CountEnemies()>0 then
						cls(6)
					else
						cls(5)
					end
					printFancy()
					if fancyMemory.textDis>=string.len(fancyMemory.text) then
						-- Show GameOverMenu
						-- Remaining Enemies:
						if CountEnemies()>0 then
							print("Remaining Enemies: "..CountEnemies(),65,55,15,false,1)
						else
							print("Now YOU'RE the main character!",37,55,15,false,1)
							printCenter("More Levels coming soon...",120,127,15,false)
						end
						
						if gameOverMenu.tClick>10 then
							gameOverMenu.tClick=0
							if btn(0) or btn(1) then
								if btn(0) then
									gameOverMenu.mode=gameOverMenu.mode-1
								elseif btn(1) then
									gameOverMenu.mode=gameOverMenu.mode+1
								end
								
								-- Menu Looping
								if gameOverMenu.mode<1 then
									gameOverMenu.mode=gameOverMenu.maxMode
								elseif gameOverMenu.mode>gameOverMenu.maxMode then
									gameOverMenu.mode=1
								end
							elseif btn(2) or btn(3) or btn(4) or btn(5) or btn(6) or btn(7) then
								if gameOverMenu.mode==1 then
									ResetGameValues()
									level=1
									mode=2
								elseif gameOverMenu.mode==2 then
									-- Back to Main Menu
									ResetGameValues()
									mode=1
								else
									gameOverMenu.mode=1
								end
							else
								gameOverMenu.tClick=11
							end
						end
						
						-- Menu Rendering:
						c={}
						for i=1,gameOverMenu.maxMode do
							if i==gameOverMenu.mode then
								if (math.floor(t/8)%2==0) then
									c[i]=14
								else
									c[i]=9
								end
							else
								c[i]=15
							end
						end
						printCenter("Restart",120,70,c[1],false)
						printCenter("Back to Main Menu",120,78,c[2],false)
						
						-- Time Incrementation:
						if gameOverMenu.tClick<=10 then
							gameOverMenu.tClick=gameOverMenu.tClick+1
						end
					end
				else
					if CountEnemies()>0 then
						cls(9)
					else
						cls(11)
					end
					if CountEnemies()>0 then
						printFancyUpdate("GAME OVER!",62,39,15,false,2)
					else
						printFancyUpdate("VICTORY!",71,39,15,false,2)
					end
					player.gameOverCircleSize=player.gameOverCircleSize+1.5
				end
				
				
			end
		end

	else
		-- ===================
		-- MODE: UNKNOWN
		-- ===================
		
		mode=1
		
	end
	t=t+1
end

-- <TILES>
-- 000:2222222222222222222222222222222222222222222222222222222222222222
-- 001:ddddddddddddddddddddddddddddddddbdddd5ddb5b5d5d5b5b5b5b545b1b4b5
-- 002:dddddddddddddddddddddddddddddddddddddddddddddddddddddfddddddff3d
-- 003:1111111111111111111111111111111111111111111111111111111111111111
-- 004:1111111111111111111111111111111111111111111111111111111111111111
-- 005:1111111111111111111111111111111111111111111111111111111111111111
-- 006:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddfff
-- 007:ddddddddddddddddddddddddddddddddddddddddddddddddffddddddff3ddddd
-- 008:1111111111111111111111111111111111111111111111111111111111111111
-- 009:1111111111111111111111111111111111111111111111111111111111111111
-- 010:1111111111111111111111111111111111111111111111111111111111111111
-- 011:1111111111111111111111111111111111111111111111111111111111111111
-- 012:1111111111111111111111111111111111111111111111111111111111111111
-- 013:1111111111111111111111111111111111111111111111111111111111111111
-- 014:1111111111111111111111111111111111111111111111111111111111111111
-- 015:1111111111111111111111111111111111111111111111111111111111111111
-- 016:2222222222222222222222282822282222282228828282828828882828888888
-- 017:dddddddddddddfffddddffffdddff3f7dd33aaa7da33337733777aa7aa737737
-- 018:ddd3ffffdddfaafadffaf373ff377aa7f333a7a3373337773a77a7377a333377
-- 019:ddddddddfdddddddf3dddddd377adddd37a77ddd737aa3dd7a77737a333333a3
-- 020:ddddffdddddff3fdddffffffd3fa3faada333377773aa33373aa37aaaa373337
-- 021:ddddddddddffdddddffffdddffa3ffdd73a7a73d3a3777737aa73377733aa33a
-- 022:ddddfff7dddfffafddf3f333d7aa7f7a3aa333a33377aa77a33a337333aa3377
-- 023:ffffddddaffffddd33a3fddd33a333dd33aaaa3d77aa33a3a73377a7a3333733
-- 024:1111111111111111111111111111111111111111111111111111111111111111
-- 025:1111111111111111111111111111111111111111111111111111111111111111
-- 026:1111111111111111111111111111111111111111111111111111111111111111
-- 027:1111111111111111111111111111111111111111111111111111111111111111
-- 028:1111111111111111111111111111111111111111111111111111111111111111
-- 029:1111111111111111111111111111111111111111111111111111111111111111
-- 030:1111111111111111111111111111111111111111111111111111111111111111
-- 031:1111111111111111111111111111111111111111111111111111111111111111
-- 032:8888888888888888888888888888888888888888888888888888888888888888
-- 033:1111111111111111111111111111111111111111111111111111111111111111
-- 034:1111111111111111111111111111111111111111111111111111111111111111
-- 035:1111111111111111111111111111111111111111111111111111111111111111
-- 036:1111111111111111111111111111111111111111111111111111111111111111
-- 037:1111111111111111111111111111111111111111111111111111111111111111
-- 038:1111111111111111111111111111111111111111111111111111111111111111
-- 039:1111111111111111111111111111111111111111111111111111111111111111
-- 040:1111111111111111111111111111111111111111111111111111111111111111
-- 041:1111111111111111111111111111111111111111111111111111111111111111
-- 042:1111111111111111111111111111111111111111111111111111111111111111
-- 043:1111111111111111111111111111111111111111111111111111111111111111
-- 044:1111111111111111111111111111111111111111111111111111111111111111
-- 045:1111111111111111111111111111111111111111111111111111111111111111
-- 046:1111111111111111111111111111111111111111111111111111111111111111
-- 047:1111111111111111111111111111111111111111111111111111111111111111
-- 048:88888888888888888888888d8d888d88888d888dd8d8d8d8dd8ddd8d8ddddddd
-- 049:1111111111111111111111111111111111111111111111111111111111111111
-- 050:1111111111111111111111111111111111111111111111111111111111111111
-- 051:1111111111111111111111111111111111111111111111111111111111111111
-- 052:1111111111111111111111111111111111111111111111111111111111111111
-- 053:1111111111111111111111111111111111111111111111111111111111111111
-- 054:1111111111111111111111111111111111111111111111111111111111111111
-- 055:1111111111111111111111111111111111111111111111111111111111111111
-- 056:1111111111111111111111111111111111111111111111111111111111111111
-- 057:1111111111111111111111111111111111111111111111111111111111111111
-- 058:1111111111111111111111111111111111111111111111111111111111111111
-- 059:1111111111111111111111111111111111111111111111111111111111111111
-- 060:1111111111111111111111111111111111111111111111111111111111111111
-- 061:1111111111111111111111111111111111111111111111111111111111111111
-- 062:1111111111111111111111111111111111111111111111111111111111111111
-- 063:1111111111111111111111111111111111111111111111111111111111111111
-- 064:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 065:1111111111111111111111111111111111111111111111111111111111111111
-- 066:1111111111111111111111111111111111111111111111111111111111111111
-- 067:1111111111111111111111111111111111111111111111111111111111111111
-- 068:1111111111111111111111111111111111111111111111111111111111111111
-- 069:1111111111111111111111111111111111111111111111111111111111111111
-- 070:1111111111111111111111111111111111111111111111111111111111111111
-- 071:1111111111111111111111111111111111111111111111111111111111111111
-- 072:1111111111111111111111111111111111111111111111111111111111111111
-- 073:1111111111111111111111111111111111111111111111111111111111111111
-- 074:1111111111111111111111111111111111111111111111111111111111111111
-- 075:1111111111111111111111111111111111111111111111111111111111111111
-- 076:1111111111111111111111111111111111111111111111111111111111111111
-- 077:1111111111111111111111111111111111111111111111111111111111111111
-- 078:1111111111111111111111111111111111111111111111111111111111111111
-- 079:1111111111111111111111111111111111111111111111111111111111111111
-- 080:1111111111111111111111111111111111111111111111111111111111111111
-- 081:1111111111111111111111111111111111111111111111111111111111111111
-- 082:1111111111111111111111111111111111111111111111111111111111111111
-- 083:1111111111111111111111111111111111111111111111111111111111111111
-- 084:1111111111111111111111111111111111111111111111111111111111111111
-- 085:1111111111111111111111111111111111111111111111111111111111111111
-- 086:1111111111111111111111111111111111111111111111111111111111111111
-- 087:1111111111111111111111111111111111111111111111111111111111111111
-- 088:1111111111111111111111111111111111111111111111111111111111111111
-- 089:1111111111111111111111111111111111111111111111111111111111111111
-- 090:1111111111111111111111111111111111111111111111111111111111111111
-- 091:1111111111111111111111111111111111111111111111111111111111111111
-- 092:1111111111111111111111111111111111111111111111111111111111111111
-- 093:1111111111111111111111111111111111111111111111111111111111111111
-- 094:1111111111111111111111111111111111111111111111111111111111111111
-- 095:1111111111111111111111111111111111111111111111111111111111111111
-- 096:1111111111111111111111161611161111161116616161616616661616666666
-- 097:1111111111111111111111111111111111111111111111111111111111111111
-- 098:1111111111111111111111111111111111111111111111111111111111111111
-- 099:1111111111111111111111111111111111111111111111111111111111111111
-- 100:1111111111111111111111111111111111111111111111111111111111111111
-- 101:1111111111111111111111111111111111111111111111111111111111111111
-- 102:1111111111111111111111111111111111111111111111111111111111111111
-- 103:1111111111111111111111111111111111111111111111111111111111111111
-- 104:1111111111111111111111111111111111111111111111111111111111111111
-- 105:1111111111111111111111111111111111111111111111111111111111111111
-- 106:1111111111111111111111111111111111111111111111111111111111111111
-- 107:1111111111111111111111111111111111111111111111111111111111111111
-- 108:1111111111111111111111111111111111111111111111111111111111111111
-- 109:1111111111111111111111111111111111111111111111111111111111111111
-- 110:1111111111111111111111111111111111111111111111111111111111111111
-- 111:1111111111111111111111111111111111111111111111111111111111111111
-- 112:6666666666666666666666666666666666666666666666666666666666666666
-- 113:1111111111111111111111111111111111111111111111111111111111111111
-- 114:1111111111111111111111111111111111111111111111111111111111111111
-- 115:1111111111111111111111111111111111111111111111111111111111111111
-- 116:1111111111111111111111111111111111111111111111111111111111111111
-- 117:1111111111111111111111111111111111111111111111111111111111111111
-- 118:1111111111111111111111111111111111111111111111111111111111111111
-- 119:1111111111111111111111111111111111111111111111111111111111111111
-- 120:1111111111111111111111111111111111111111111111111111111111111111
-- 121:1111111111111111111111111111111111111111111111111111111111111111
-- 122:1111111111111111111111111111111111111111111111111111111111111111
-- 123:1111111111111111111111111111111111111111111111111111111111111111
-- 124:1111111111111111111111111111111111111111111111111111111111111111
-- 125:1111111111111111111111111111111111111111111111111111111111111111
-- 126:1111111111111111111111111111111111111111111111111111111111111111
-- 127:1111111111111111111111111111111111111111111111111111111111111111
-- 128:6666666666666666666666696966696666696669969696969969996969999999
-- 129:1111111111111111111111111111111111111111111111111111111111111111
-- 130:1111111111111111111111111111111111111111111111111111111111111111
-- 131:1111111111111111111111111111111111111111111111111111111111111111
-- 132:1111111111111111111111111111111111111111111111111111111111111111
-- 133:1111111111111111111111111111111111111111111111111111111111111111
-- 134:1111111111111111111111111111111111111111111111111111111111111111
-- 135:1111111111111111111111111111111111111111111111111111111111111111
-- 136:1111111111111111111111111111111111111111111111111111111111111111
-- 137:1111111111111111111111111111111111111111111111111111111111111111
-- 138:1111111111111111111111111111111111111111111111111111111111111111
-- 139:1111111111111111111111111111111111111111111111111111111111111111
-- 140:1111111111111111111111111111111111111111111111111111111111111111
-- 141:1111111111111111111111111111111111111111111111111111111111111111
-- 142:1111111111111111111111111111111111111111111111111111111111111111
-- 143:1111111111111111111111111111111111111111111111111111111111111111
-- 144:9999999999999999999999999999999999999999999999999999999999999999
-- 145:1111111111111111111111111111111111111111111111111111111111111111
-- 146:1111111111111111111111111111111111111111111111111111111111111111
-- 147:1111111111111111111111111111111111111111111111111111111111111111
-- 148:1111111111111111111111111111111111111111111111111111111111111111
-- 149:1111111111111111111111111111111111111111111111111111111111111111
-- 150:1111111111111111111111111111111111111111111111111111111111111111
-- 151:1111111111111111111111111111111111111111111111111111111111111111
-- 152:1111111111111111111111111111111111111111111111111111111111111111
-- 153:1111111111111111111111111111111111111111111111111111111111111111
-- 154:1111111111111111111111111111111111111111111111111111111111111111
-- 155:1111111111111111111111111111111111111111111111111111111111111111
-- 156:1111111111111111111111111111111111111111111111111111111111111111
-- 157:1111111111111111111111111111111111111111111111111111111111111111
-- 158:1111111111111111111111111111111111111111111111111111111111111111
-- 159:1111111111111111111111111111111111111111111111111111111111111111
-- 160:1111111111111111111111111111111111111111111111111111111111111111
-- 161:1111111111111111111111111111111111111111111111111111111111111111
-- 162:1111111111111111111111111111111111111111111111111111111111111111
-- 163:1111111111111111111111111111111111111111111111111111111111111111
-- 164:1111111111111111111111111111111111111111111111111111111111111111
-- 165:1111111111111111111111111111111111111111111111111111111111111111
-- 166:1111111111111111111111111111111111111111111111111111111111111111
-- 167:1111111111111111111111111111111111111111111111111111111111111111
-- 168:1111111111111111111111111111111111111111111111111111111111111111
-- 169:1111111111111111111111111111111111111111111111111111111111111111
-- 170:1111111111111111111111111111111111111111111111111111111111111111
-- 171:1111111111111111111111111111111111111111111111111111111111111111
-- 172:1111111111111111111111111111111111111111111111111111111111111111
-- 173:1111111111111111111111111111111111111111111111111111111111111111
-- 174:1111111111111111111111111111111111111111111111111111111111111111
-- 175:1111111111111111111111111111111111111111111111111111111111111111
-- 176:1111111111111111111111111111111111111111111111111111111111111111
-- 177:1111111111111111111111111111111111111111111111111111111111111111
-- 178:1111111111111111111111111111111111111111111111111111111111111111
-- 179:1111111111111111111111111111111111111111111111111111111111111111
-- 180:1111111111111111111111111111111111111111111111111111111111111111
-- 181:1111111111111111111111111111111111111111111111111111111111111111
-- 182:1111111111111111111111111111111111111111111111111111111111111111
-- 183:1111111111111111111111111111111111111111111111111111111111111111
-- 184:1111111111111111111111111111111111111111111111111111111111111111
-- 185:1111111111111111111111111111111111111111111111111111111111111111
-- 186:1111111111111111111111111111111111111111111111111111111111111111
-- 187:1111111111111111111111111111111111111111111111111111111111111111
-- 188:1111111111111111111111111111111111111111111111111111111111111111
-- 189:1111111111111111111111111111111111111111111111111111111111111111
-- 190:1111111111111111111111111111111111111111111111111111111111111111
-- 191:1111111111111111111111111111111111111111111111111111111111111111
-- 192:1111111111111111111111111111111111111111111111111111111111111111
-- 193:1111111111111111111111111111111111111111111111111111111111111111
-- 194:1111111111111111111111111111111111111111111111111111111111111111
-- 195:1111111111111111111111111111111111111111111111111111111111111111
-- 196:1111111111111111111111111111111111111111111111111111111111111111
-- 197:1111111111111111111111111111111111111111111111111111111111111111
-- 198:1111111111111111111111111111111111111111111111111111111111111111
-- 199:1111111111111111111111111111111111111111111111111111111111111111
-- 200:1111111111111111111111111111111111111111111111111111111111111111
-- 201:1111111111111111111111111111111111111111111111111111111111111111
-- 202:1111111111111111111111111111111111111111111111111111111111111111
-- 203:1111111111111111111111111111111111111111111111111111111111111111
-- 204:1111111111111111111111111111111111111111111111111111111111111111
-- 205:1111111111111111111111111111111111111111111111111111111111111111
-- 206:1111111111111111111111111111111111111111111111111111111111111111
-- 207:1111111111111111111111111111111111111111111111111111111111111111
-- 208:1111111111111111111111111111111111111111111111111111111111111111
-- 209:1111111111111111111111111111111111111111111111111111111111111111
-- 210:1111111111111111111111111111111111111111111111111111111111111111
-- 211:1111111111111111111111111111111111111111111111111111111111111111
-- 212:1111111111111111111111111111111111111111111111111111111111111111
-- 213:1111111111111111111111111111111111111111111111111111111111111111
-- 214:1111111111111111111111111111111111111111111111111111111111111111
-- 215:1111111111111111111111111111111111111111111111111111111111111111
-- 216:1111111111111111111111111111111111111111111111111111111111111111
-- 217:1111111111111111111111111111111111111111111111111111111111111111
-- 218:1111111111111111111111111111111111111111111111111111111111111111
-- 219:1111111111111111111111111111111111111111111111111111111111111111
-- 220:1111111111111111111111111111111111111111111111111111111111111111
-- 221:1111111111111111111111111111111111111111111111111111111111111111
-- 222:1111111111111111111111111111111111111111111111111111111111111111
-- 223:1111111111111111111111111111111111111111111111111111111111111111
-- 224:1111111111111111111111111111111111111111111111111111111111111111
-- 225:1111111111111111111111111111111111111111111111111111111111111111
-- 226:1111111111111111111111111111111111111111111111111111111111111111
-- 227:1111111111111111111111111111111111111111111111111111111111111111
-- 228:1111111111111111111111111111111111111111111111111111111111111111
-- 229:1111111111111111111111111111111111111111111111111111111111111111
-- 230:1111111111111111111111111111111111111111111111111111111111111111
-- 231:1111111111111111111111111111111111111111111111111111111111111111
-- 232:1111111111111111111111111111111111111111111111111111111111111111
-- 233:1111111111111111111111111111111111111111111111111111111111111111
-- 234:1111111111111111111111111111111111111111111111111111111111111111
-- 235:1111111111111111111111111111111111111111111111111111111111111111
-- 236:1111111111111111111111111111111111111111111111111111111111111111
-- 237:1111111111111111111111111111111111111111111111111111111111111111
-- 238:1111111111111111111111111111111111111111111111111111111111111111
-- 239:1111111111111111111111111111111111111111111111111111111111111111
-- 240:1111111111111111111111111111111111111111111111111111111111111111
-- 241:1111111111111111111111111111111111111111111111111111111111111111
-- 242:1111111111111111111111111111111111111111111111111111111111111111
-- 243:1111111111111111111111111111111111111111111111111111111111111111
-- 244:1111111111111111111111111111111111111111111111111111111111111111
-- 245:1111111111111111111111111111111111111111111111111111111111111111
-- 246:1111111111111111111111111111111111111111111111111111111111111111
-- 247:1111111111111111111111111111111111111111111111111111111111111111
-- 248:1111111111111111111111111111111111111111111111111111111111111111
-- 249:1111111111111111111111111111111111111111111111111111111111111111
-- 250:1111111111111111111111111111111111111111111111111111111111111111
-- 251:1111111111111111111111111111111111111111111111111111111111111111
-- 252:1111111111111111111111111111111111111111111111111111111111111111
-- 253:1111111111111111111111111111111111111111111111111111111111111111
-- 254:1111111111111111111111111111111111111111111111111111111111111111
-- </TILES>

-- <SPRITES>
-- 000:fffffffffffffffffffffffffffffff3fffff7a3fffff37aff7a3007fff7a000
-- 001:fffffffffffffffff333ffff333333ff3333333333333333a33333317a33311f
-- 002:fffffffffffffffffffffffffffff333fffff333fff7a337fff37a30ff307a00
-- 003:ffffffffffffffffffffffff3333ffff33333fffa333333f7a3333337a333333
-- 004:fffffffffffffffffffffffffffff333ffff3333fff337a3ff3307a3f33307a3
-- 005:ffffffffffffffffffffffff333fffff3333ffff37a33fff07a333ff07a3333f
-- 006:ffffffffffffffffffffffffffff3333fff33333f33333373333337a3333307a
-- 007:ffffffffffffffffffffffff333fffff333fffffa337afff337a3fff307a33ff
-- 008:ffffffffffffffffffff333fff333333333333333333333013333307f113007a
-- 009:ffffffffffffffffffffffff3fffffff37afffff7a3fffffa3337aff3307afff
-- 010:f7affffff77affffff77affffff77a33ffff7300ffff3000fff33000fff33000
-- 011:ffffffffffffffffffffffffffffffff3fffffff03ffffff033aaaaf0337777f
-- 012:fffffff7fffffff7fffffff7fffffff7fffffff3ffffff30fffff300ffff3300
-- 013:afffffffafffffffafffffffafffffff3fffffff03ffffff003fffff0033ffff
-- 014:fffffffffffffffffffffffffffffffffffffff3ffffff30f7777330faaaa330
-- 015:fffff7afffff7aaffff7aaff337aafff003affff0003ffff00033fff00033fff
-- 016:fff37a00ff3007aaf30077a1f000711f300111ff01166fff1f111fffffffffff
-- 017:77a111ff71166fff1f111fffffffffffffffffffffffffffffffffffffffffff
-- 018:ff3007a0f30077a033000111301111ff11166ffffff11fffffffffffffffffff
-- 019:77a3331107a111ff111661ffff111fffffffffffffffffffffffffffffffffff
-- 020:333377aa333337a311111111ff1661fffff11fffffffffffffffffffffffffff
-- 021:77aa333337a3333311111111ff1661fffff11fffffffffffffffffffffffffff
-- 022:113307aaff1117a3ff166111fff111ffffffffffffffffffffffffffffffffff
-- 023:37a333ff07aa333f11133333ff111133fff66111fff11fffffffffffffffffff
-- 024:ff1117aafff6611afff111f1ffffffffffffffffffffffffffffffffffffffff
-- 025:007a3fff77a333ff17aa333ff11a333fff111333fff66113fff111f1ffffffff
-- 026:fff33300ffff3333ffff7333ffff7a33fff7aafffff7afffff7aafffffaaffff
-- 027:3337777f33ffffff3fffffffffffffffffffffffffffffffffffffffffffffff
-- 028:ffff3300ffff3330ffff7333fff7aa33ff7aaff3f7aafffffaafffffffffffff
-- 029:0033ffff0333ffff333affff3377afff3ff77affffff77affffff77fffffffff
-- 030:faaaa333ffffff33fffffff3ffffffffffffffffffffffffffffffffffffffff
-- 031:00333fff3333ffff333affff337affffff77affffff7affffff77affffff77ff
-- 032:fffffffffffffffffffffffffffff7afffffff7aff7afff7fff7af30ffff7a00
-- 033:fffffffffffffffffffffffffffffffffff33333a33333317a3a311f07a111ff
-- 034:ffffffffffffffffffffffffffffaffffff7aff7ffff7af0ffff7a00fff307a0
-- 035:ffffffffffffffffffffffffafffffffafffffff7a333fff7a33333307aa3311
-- 036:fffffffffffffffffffffffffffffffffffff7affffff7a3fff307a3f33307a3
-- 037:fffffffffffffffffffffffffffffffff7afffff37afffff07a33fff07a333ff
-- 038:fffffffffffffffffffffffffffffff7fffffff7fff3337a3333307a113377a3
-- 039:fffffffffffffffffffffffffff7ffffaff7afff3f7affff307affff07a33fff
-- 040:ffffffffffffffffffffffffffffffff33333fff13333307f113707aff1117a3
-- 041:fffffffffffffffffffffffff7afffff7affffffafff7aff33f7afff307affff
-- 042:fffffffff7afffffff7afffffff7afffffff7333ffff3333fff33300fff33000
-- 043:ffffffffffffffffffffffffffffffff3fffffff33ffffff333fffff033aaaaf
-- 044:fffffffffffffff7fffffff7fffffff7fffffff7ffffff33fffff333ffff3330
-- 045:ffffffffafffffffafffffffafffffffafffffff33ffffff333fffff0333ffff
-- 046:fffffffffffffffffffffffffffffffffffffff3ffffff33fffff333f7777330
-- 047:fffffffffffff7afffff7afffff7afff333affff3333ffff00333fff00033fff
-- 048:fff007a0ff0007a1ff30711ff33111ff31166fff1f111fffffffffffffffffff
-- 049:71166fff1f111fffffffffffffffffffffffffffffffffffffffffffffffffff
-- 050:ff3007aaf3307111331111ff11166ffffff11fffffffffffffffffffffffffff
-- 051:77a111ff111661ffff111fffffffffffffffffffffffffffffffffffffffffff
-- 052:333377aa11111111ff1661fffff11fffffffffffffffffffffffffffffffffff
-- 053:77aa333311111111ff1661fffff11fffffffffffffffffffffffffffffffffff
-- 054:ff1117aaff166111fff111ffffffffffffffffffffffffffffffffffffffffff
-- 055:77a333ff111a333fff111133fff66111fff11fffffffffffffffffffffffffff
-- 056:fff6611afff111f1ffffffffffffffffffffffffffffffffffffffffffffffff
-- 057:07a33fff17a333fff11a33ffff11133ffff66113fff111f1ffffffffffffffff
-- 058:fff33000ffff3300fffff333ffff7a33ffff7afffff7affffff7afffff7affff
-- 059:0337777f33ffffff3fffffffffffffffffffffffffffffffffffffffffffffff
-- 060:ffff3300ffff3300fffff330ffff7a33fff7aff3ff7afffff7afffffffffffff
-- 061:0033ffff0033ffff033fffff337affff3ff7afffffff7afffffff7afffffffff
-- 062:faaaa330ffffff33fffffff3ffffffffffffffffffffffffffffffffffffffff
-- 063:00033fff0033ffff333fffff337affffff7afffffff7affffff7afffffff7aff
-- 064:fffffffffffffffffffff7afffffff7af7affff7ff7afffffff7aff3ffff7a30
-- 065:ffffffffffffffffffffffffffffffffafffff337a33333107aa311f07a111ff
-- 066:fffffffffffffffffffffffffff7aff7fff7aff7ffff7affffff7a30fffff7a0
-- 067:ffffffffffffffffffffffffafffffffafffffff7affffff7a33333307aa3311
-- 068:fffffffffffffffffffffffffffff7affffff7affffff7affffff7a3ff3307a3
-- 069:fffffffffffffffffffffffff7affffff7affffff7afffff37afffff07a33fff
-- 070:fffffffffffffffffffffffffffffff7fffffff7ffffff7a3333307a113077a3
-- 071:ffffffffffffffffffffffffaff7afffaff7afffff7affff307affff07afffff
-- 072:ffffffffffffffffffffffffffffffff33fffff71333307af11077a3ff1117a3
-- 073:fffffffffffffffff7afffff7affffffaffff7afffff7aff3ff7afff307affff
-- 074:faaffffff7aaffffff7aaffffff7aa33ffff7a33fff33733fff33300fff33000
-- 075:ffffffffffffffffffffffff3fffffff33ffffff333fffff333aaaaf033aaaaf
-- 076:fffffffffffffff7fffffff7fffffff7ffffff37fffff337ffff3333ffff3330
-- 077:ffffffffafffffffafffffffafffffffa3ffffffa33fffff3333ffff0333ffff
-- 078:fffffffffffffffffffffffffffffff3ffffff33fffff333f7777333f7777330
-- 079:fffff77fffff77affff77aff3377afff337affff33a33fff00333fff00033fff
-- 080:fffff7aafff007a1ff00711ff00111ff311661ff1f166fffff111fffffffffff
-- 081:011661ff1f166fffff111fffffffffffffffffffffffffffffffffffffffffff
-- 082:fff007aaff007111301111ff111661ffff166ffffff11fffffffffffffffffff
-- 083:77a111ff111661ffff1661ffff111fffffffffffffffffffffffffffffffffff
-- 084:333377aa11111111ff1661ffff1661fffff11fffffffffffffffffffffffffff
-- 085:77aa333311111111ff1661ffff1661fffff11fffffffffffffffffffffffffff
-- 086:ff1117aaff166111ff1661fffff111ffffffffffffffffffffffffffffffffff
-- 087:77a33fff111a33ffff111133ff166111fff661fffff11fffffffffffffffffff
-- 088:ff16611afff661f1fff111ffffffffffffffffffffffffffffffffffffffffff
-- 089:77afffff17a33ffff11a33ffff11133fff166113fff661f1fff111ffffffffff
-- 090:fff33000ffff3000ffff7300ffff7a33fff77afffff7afffff77afffff7affff
-- 091:0337777f03ffffff3fffffffffffffffffffffffffffffffffffffffffffffff
-- 092:ffff3300ffff3300ffff7300fff77a30ff77aff3f77afffff7afffffffffffff
-- 093:0033ffff0033ffff003affff037aafff3ff7aaffffff7aaffffff7afffffffff
-- 094:faaaa330ffffff30fffffff3ffffffffffffffffffffffffffffffffffffffff
-- 095:00033fff0003ffff003affff337affffff7aaffffff7affffff7aaffffff7aff
-- 096:1111111111111111111111111111111111111111111111111111111111111111
-- 097:1111111111111111111111111111111111111111111111111111111111111111
-- 098:1111111111111111111111111111111111111111111111111111111111111111
-- 099:1111111111111111111111111111111111111111111111111111111111111111
-- 100:1111111111111111111111111111111111111111111111111111111111111111
-- 101:1111111111111111111111111111111111111111111111111111111111111111
-- 102:1111111111111111111111111111111111111111111111111111111111111111
-- 103:1111111111111111111111111111111111111111111111111111111111111111
-- 104:1111111111111111111111111111111111111111111111111111111111111111
-- 105:1111111111111111111111111111111111111111111111111111111111111111
-- 106:1111111111111111111111111111111111111111111111111111111111111111
-- 107:1111111111111111111111111111111111111111111111111111111111111111
-- 108:1111111111111111111111111111111111111111111111111111111111111111
-- 109:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6
-- 110:fff7affffff7affffff7affffff33fffff3333fff633336f6ff33ff6fff7afff
-- 111:ffffffffffffffffffffffffffffffffffffffffffffffffffffffff6fffffff
-- 112:1111111111111111111111111111111111111111111111111111111111111111
-- 113:1111111111111111111111111111111111111111111111111111111111111111
-- 114:1111111111111111111111111111111111111111111111111111111111111111
-- 115:1111111111111111111111111111111111111111111111111111111111111111
-- 116:1111111111111111111111111111111111111111111111111111111111111111
-- 117:1111111111111111111111111111111111111111111111111111111111111111
-- 118:1111111111111111111111111111111111111111111111111111111111111111
-- 119:1111111111111111111111111111111111111111111111111111111111111111
-- 120:1111111111111111111111111111111111111111111111111111111111111111
-- 121:1111111111111111111111111111111111111111111111111111111111111111
-- 122:1111111111111111111111111111111111111111111111111111111111111111
-- 123:1111111111111111111111111111111111111111111111111111111111111111
-- 124:1111111111111111111111111111111111111111111111111111111111111111
-- 125:ffffff6ffff336ffff3333ffff3333fffff33ffffff6fffffff6fffffff6ffff
-- 126:fff7affffff7affffff7afffff3333fff333333f333003333300003333000033
-- 127:f6ffffffff633fffff3333ffff3333fffff33fffffff6fffffff6fffffff6fff
-- 128:1111111111111111111111111111111111111111111111111111111111111111
-- 129:1111111111111111111111111111111111111111111111111111111111111111
-- 130:1111111111111111111111111111111111111111111111111111111111111111
-- 131:1111111111111111111111111111111111111111111111111111111111111111
-- 132:1111111111111111111111111111111111111111111111111111111111111111
-- 133:1111111111111111111111111111111111111111111111111111111111111111
-- 134:1111111111111111111111111111111111111111111111111111111111111111
-- 135:1111111111111111111111111111111111111111111111111111111111111111
-- 136:1111111111111111111111111111111111111111111111111111111111111111
-- 137:1111111111111111111111111111111111111111111111111111111111111111
-- 138:1111111111111111111111111111111111111111111111111111111111111111
-- 139:1111111111111111111111111111111111111111111111111111111111111111
-- 140:1111111111111111111111111111111111111111111111111111111111111111
-- 141:fff6fffffff6fffffff6fff7fff6ff7afff337afff3333ffff3333ffff73366f
-- 142:f330033f7a33337aaff33ff7fffffffffffffffffffffffffffffffffff33fff
-- 143:ffff6fffffff6fffafff6fff7aff6ffff7a33fffff3333ffff3333fff6633aff
-- 144:1111111111111111111111111111111111111111111111111111111111111111
-- 145:1111111111111111111111111111111111111111111111111111111111111111
-- 146:1111111111111111111111111111111111111111111111111111111111111111
-- 147:1111111111111111111111111111111111111111111111111111111111111111
-- 148:1111111111111111111111111111111111111111111111111111111111111111
-- 149:1111111111111111111111111111111111111111111111111111111111111111
-- 150:1111111111111111111111111111111111111111111111111111111111111111
-- 151:1111111111111111111111111111111111111111111111111111111111111111
-- 152:1111111111111111111111111111111111111111111111111111111111111111
-- 153:1111111111111111111111111111111111111111111111111111111111111111
-- 154:1111111111111111111111111111111111111111111111111111111111111111
-- 155:1111111111111111111111111111111111111111111111111111111111111111
-- 156:1111111111111111111111111111111111111111111111111111111111111111
-- 157:f7affff67affffffafffffffffffffffffffffffffffffffffffffffffffffff
-- 158:6f3333f6f633336ffff33fffffffffffffffffffffffffffffffffffffffffff
-- 159:6ffff7afffffff7ffffffff7ffffffffffffffffffffffffffffffffffffffff
-- 160:1111111111111111111111111111111111111111111111111111111111111111
-- 161:1111111111111111111111111111111111111111111111111111111111111111
-- 162:1111111111111111111111111111111111111111111111111111111111111111
-- 163:1111111111111111111111111111111111111111111111111111111111111111
-- 164:1111111111111111111111111111111111111111111111111111111111111111
-- 165:1111111111111111111111111111111111111111111111111111111111111111
-- 166:1111111111111111111111111111111111111111111111111111111111111111
-- 167:1111111111111111111111111111111111111111111111111111111111111111
-- 168:1111111111111111111111111111111111111111111111111111111111111111
-- 169:1111111111111111111111111111111111111111111111111111111111111111
-- 170:1111111111111111111111111111111111111111111111111111111111111111
-- 171:1111111111111111111111111111111111111111111111111111111111111111
-- 172:1111111111111111111111111111111111111111111111111111111111111111
-- 173:1111111111111111111111111111111111111111111111111111111111111111
-- 174:1111111111111111111111111111111111111111111111111111111111111111
-- 175:1111111111111111111111111111111111111111111111111111111111111111
-- 176:1111111111111111111111111111111111111111111111111111111111111111
-- 177:1111111111111111111111111111111111111111111111111111111111111111
-- 178:1111111111111111111111111111111111111111111111111111111111111111
-- 179:1111111111111111111111111111111111111111111111111111111111111111
-- 180:1111111111111111111111111111111111111111111111111111111111111111
-- 181:1111111111111111111111111111111111111111111111111111111111111111
-- 182:1111111111111111111111111111111111111111111111111111111111111111
-- 183:1111111111111111111111111111111111111111111111111111111111111111
-- 184:1111111111111111111111111111111111111111111111111111111111111111
-- 185:1111111111111111111111111111111111111111111111111111111111111111
-- 186:1111111111111111111111111111111111111111111111111111111111111111
-- 187:1111111111111111111111111111111111111111111111111111111111111111
-- 188:1111111111111111111111111111111111111111111111111111111111111111
-- 189:1111111111111111111111111111111111111111111111111111111111111111
-- 190:1111111111111111111111111111111111111111111111111111111111111111
-- 191:1111111111111111111111111111111111111111111111111111111111111111
-- 192:1111111111111111111111111111111111111111111111111111111111111111
-- 193:1111111111111111111111111111111111111111111111111111111111111111
-- 194:1111111111111111111111111111111111111111111111111111111111111111
-- 195:1111111111111111111111111111111111111111111111111111111111111111
-- 196:1111111111111111111111111111111111111111111111111111111111111111
-- 197:1111111111111111111111111111111111111111111111111111111111111111
-- 198:1111111111111111111111111111111111111111111111111111111111111111
-- 199:1111111111111111111111111111111111111111111111111111111111111111
-- 200:1111111111111111111111111111111111111111111111111111111111111111
-- 201:1111111111111111111111111111111111111111111111111111111111111111
-- 202:1111111111111111111111111111111111111111111111111111111111111111
-- 203:1111111111111111111111111111111111111111111111111111111111111111
-- 204:1111111111111111111111111111111111111111111111111111111111111111
-- 205:1111111111111111111111111111111111111111111111111111111111111111
-- 206:1111111111111111111111111111111111111111111111111111111111111111
-- 207:1111111111111111111111111111111111111111111111111111111111111111
-- 208:1111111111111111111111111111111111111111111111111111111111111111
-- 209:1111111111111111111111111111111111111111111111111111111111111111
-- 210:1111111111111111111111111111111111111111111111111111111111111111
-- 211:1111111111111111111111111111111111111111111111111111111111111111
-- 212:1111111111111111111111111111111111111111111111111111111111111111
-- 213:1111111111111111111111111111111111111111111111111111111111111111
-- 214:1111111111111111111111111111111111111111111111111111111111111111
-- 215:1111111111111111111111111111111111111111111111111111111111111111
-- 216:1111111111111111111111111111111111111111111111111111111111111111
-- 217:1111111111111111111111111111111111111111111111111111111111111111
-- 218:1111111111111111111111111111111111111111111111111111111111111111
-- 219:1111111111111111111111111111111111111111111111111111111111111111
-- 220:1111111111111111111111111111111111111111111111111111111111111111
-- 221:1111111111111111111111111111111111111111111111111111111111111111
-- 222:1111111111111111111111111111111111111111111111111111111111111111
-- 223:1111111111111111111111111111111111111111111111111111111111111111
-- 224:1111111111111111111111111111111111111111111111111111111111111111
-- 225:1111111111111111111111111111111111111111111111111111111111111111
-- 226:1111111111111111111111111111111111111111111111111111111111111111
-- 227:1111111111111111111111111111111111111111111111111111111111111111
-- 228:1111111111111111111111111111111111111111111111111111111111111111
-- 229:1111111111111111111111111111111111111111111111111111111111111111
-- 230:1111111111111111111111111111111111111111111111111111111111111111
-- 231:1111111111111111111111111111111111111111111111111111111111111111
-- 232:1111111111111111111111111111111111111111111111111111111111111111
-- 233:1111111111111111111111111111111111111111111111111111111111111111
-- 234:1111111111111111111111111111111111111111111111111111111111111111
-- 235:1111111111111111111111111111111111111111111111111111111111111111
-- 236:1111111111111111111111111111111111111111111111111111111111111111
-- 237:1111111111111111111111111111111111111111111111111111111111111111
-- 238:1111111111111111111111111111111111111111111111111111111111111111
-- 239:1111111111111111111111111111111111111111111111111111111111111111
-- 240:1111111111111111111111111111111111111111111111111111111111111111
-- 241:1111111111111111111111111111111111111111111111111111111111111111
-- 242:1111111111111111111111111111111111111111111111111111111111111111
-- 243:1111111111111111111111111111111111111111111111111111111111111111
-- 244:1111111111111111111111111111111111111111111111111111111111111111
-- 245:1111111111111111111111111111111111111111111111111111111111111111
-- 246:1111111111111111111111111111111111111111111111111111111111111111
-- 247:1111111111111111111111111111111111111111111111111111111111111111
-- 248:1111111111111111111111111111111111111111111111111111111111111111
-- 249:1111111111111111111111111111111111111111111111111111111111111111
-- 250:1111111111111111111111111111111111111111111111111111111111111111
-- 251:1111111111111111111111111111111111111111111111111111111111111111
-- 252:1111111111111111111111111111111111111111111111111111111111111111
-- 253:1111111111111111111111111111111111111111111111111111111111111111
-- 254:1111111111111111111111111111111111111111111111111111111111111111
-- 255:0000000000000000000f000000fff000000f0000000000000000000000000000
-- </SPRITES>

-- <MAP>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 001:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 002:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 003:010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 004:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 005:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 006:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 007:030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 008:040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 009:040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 010:040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 011:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 012:040460700420046070040460700420040404042004607004200404046070040460700420046070040460700420040404042004607004200404046070ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 013:415161711121316171415161711121314151112131617111213141516171415161711121316171415161711121314151112131617111213141516171ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 014:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 015:101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 016:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 017:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 018:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 019:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 020:010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 021:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 022:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 023:020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 024:030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 025:040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 026:040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 027:040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 028:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 029:040460700420046070040460700420040404042004607004200404046070040460700420046070040460700420040404042004607004200404046070ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 030:415161711121316171415161711121314151112131617111213141516171415161711121316171415161711121314151112131617111213141516171ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 031:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 032:101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 033:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 034:050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 035:050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 036:050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 037:060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 038:070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 039:070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 040:070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 041:080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808080808ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 042:090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 043:090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 044:090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 045:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 046:040460700420046070040460700420040404042004607004200404046070040460700420046070040460700420040404042004607004200404046070ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 047:415161711121316171415161711121314151112131617111213141516171415161711121316171415161711121314151112131617111213141516171ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 048:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 049:101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 050:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 051:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 052:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 053:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 054:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 055:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 056:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 057:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 058:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 059:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 060:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 061:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 062:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 063:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 064:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 065:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 066:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 067:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 068:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 069:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 070:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 071:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 072:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 073:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 074:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 075:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 076:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 077:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 078:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 079:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 080:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 081:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 082:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 083:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 084:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 085:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 086:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 087:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 088:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 089:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 090:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 091:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 092:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 093:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 094:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 095:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 096:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 097:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 098:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 099:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 100:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 101:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 102:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 103:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 104:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 105:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 106:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 107:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 108:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 109:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 110:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 111:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 112:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 113:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 114:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 115:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 116:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 117:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 118:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 119:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 120:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 121:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 122:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 123:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 124:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 125:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 126:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 127:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 128:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 129:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 130:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 131:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 132:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 133:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 134:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 135:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- 014:12232222211111111222222222211111
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000105000000000
-- 001:2f201f110f320f421f112f403f1f3f2f3f5e2f3e1f1e0f3e0f1f1f1f2f300f000f000f000f000f000f000f000f000f000f000f000f000f000f000f0038000f080f0f
-- 002:2f901f810f910fb11f811f713f625f927f628f829f63af83bf33bf54cf74cf74df75df85df95ef75ef66ef86ff66ff46ff57ff47ff37ff17ff37ff77b8400f000000
-- 003:4f6b2f3d0f3d0f4c0f4d1f3d3f1e4f5e5f1e6f2e7f4e7f5e8f5e8f5d9f7e9f8e9f7daf8eaf9fbf7fbf8ebf4ebf4ecf3ecf40df4fdf3fef2fff2fff901f5001000000
-- 004:020002300230020002300200020002300230020002300230022002300220022002200200023002300220022002200200022002200200022002200200285000000900
-- 063:0e000f000e000e000e000e000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f00304007000000
-- </SFX>

-- <PATTERNS>
-- 000:6ff1060000000000000000000000000000000000001000008ff1060000009ff1060000000000000000001000006ff106000000000000000000000000000000100000100000100000100000bff1060000000000000000001000009ff106000000000000000000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000100000
-- 058:6ff1040000000000000000009ff104000000000000000000dff104000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 059:6ff104000000000000000000dff1020000000000000000009ff102000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </PATTERNS>

-- <TRACKS>
-- 001:c30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a50300
-- 002:b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a50300
-- </TRACKS>

-- <SCREEN>
-- 000:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 001:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 002:88ffff88888888888888888888ff8888888ff8888888888888ff88888fffff88fff888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888fffff8ffff888ffff8ff888888fff888fff888
-- 003:88ff88f88fff88ff8f888ffff8888ffff88888ffff888fff88ff88888ff8888ff8ff88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888ff8888ff88f8fff888ff88888ff8888ff8ff88
-- 004:88ff88f8ff8ff8fffff8f88ff8ff8ff88f8ff8ff88f8f88ff88888888ffff88fff8f88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888ffff88ff88f88fff888888888ffff88fff8f88
-- 005:88ffff88fff888f8f8f8f88ff8ff8ff88f8ff8ff88f8fffff8ff88888888ff8ff88f88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888ff8888ffff8888fff8ff88888ff88f8ff88f88
-- 006:88ff88f88fff88f8f8f88ffff8ff8ff88f8ff8ff88f8888ff8ff88888ffff888fff888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888ff8888ff8888ffff88ff888888fff888fff888
-- 007:888888888888888888888888888888888888888888888fff888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 008:8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888887a8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 009:8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888887a8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 010:8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888887a8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 011:8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888887a8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 012:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888883333888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 013:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888833333388888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 014:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888333003338888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 015:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888330000338888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 016:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888330000338888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 017:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888833003388888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 018:8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888887a33337a8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 019:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888887a8833887a888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 020:88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888887a888888887a88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 021:88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888887a8888888888888888888888887a88888888887a8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 022:88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888887a888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 023:88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888887a888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 024:88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888887a888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 025:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888333388888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 026:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888883333338888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 027:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888833300333888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 028:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888833000033888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 029:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888833000033888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 030:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888883300338888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 031:88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888887a33337a888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 032:8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888887a8833887a88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 033:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888887a888888887a8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 034:88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888887a88888888887a888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 035:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 036:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 037:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 038:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 039:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 040:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 041:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 042:888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 043:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 044:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 045:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 046:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 047:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 048:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 049:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 050:ddddddddddddd7addddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 051:ddddddddddddd7addddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 052:ddddddddddddd7addddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 053:ddddddddddddd7addddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 054:dddddddddddd3333ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd7addddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 055:ddddddddddd333333dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd7addddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 056:dddddddddd33300333ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd7addddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 057:dddddddddd33000033ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd7adddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd7addddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 058:dddddddddd33000033dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd3333ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd7addddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 059:ddddddddddd330033dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd333333dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd7addddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 060:dddddddddd7a33337adddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd33300333ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd7addddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 061:ddddddddd7add33dd7addddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd33000033dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd3333dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 062:dddddddd7adddddddd7adddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd33000033ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd333333ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 063:ddddddd7adddddddddd7adddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd330033ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd33300333dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 064:ddddddddddddddddddfddddddddddddddddddffddddddddddddddddddddddddddddddffddddddddddddd7a33337addddddddddddddddddddddddddddddddddddddfddddddddddddddddddffd33000033ddddddddddfddddddddddddddddddddddddddddddddddffddddddddddddddddddddddddddddddffd
-- 065:dddddddddddddddddff3ddddddddddddddfffff3ddddddddddddddddddddddddddfffff3ddddddddddd7add33ff7addddddddddddddddddddddddddddddddddddff3ddddddddddddddfffff333000033dddddddddff3ddddddddddddddddddddddddddddddfffff3ddddddddddddddddddddddddddfffff3
-- 066:fddddddddddddddd3ffffddddddddddddfff7ffffddddddddffddddddddddddddfff7ffffddddddddd7adddd3fff7adddddddddddffddddddddddddddddddddd3ffffddddddddddddfff7ffff330033ddddddddd3ffffddddddddddddffddddddddddddddfff7ffffddddddddffddddddddddddddfff7fff
-- 067:ffddddddddfffdddfaafafddddddddddfffafaffffddddddff3fdddffdddddddfffafaffffddddddd7affdddfaafa7adddddddddff3fdddffdddddddddfffdddfaafafddddddddddfffafaff7a33337addfffdddfaafafddddddddddff3fdddffdddddddfffafaffffddddddff3fdddffdddddddfffafaff
-- 068:3fdddddddffffdffaf373f3ddddddddf3f33333a3fdddddffffffdffffdddddf3f33333a3fdddddddffffdffaf373f3ddddddddffffffdffffdddddddffffdffaf373f3ddddddddf3f333337afd33dd7affffdffaf373f3ddddddddffffffdffffdddddf3f33333a3fdddddffffffdffffdddddf3f33333a
-- 069:333dddddff3f7ff377aa7377addddd7aa7f7a33a333ddd3fa3faaffa3ffddd7aa7f7a33a333dddddff3f7ff377aa7377addddd3fa3faaffa3ffdddddff3f7ff377aa3377addddd7aa7f7a37a333ddddd7a3f7ff377aa7377addddd3fa3faaffa3ffddd7aa7f7a33a333ddd3fa3faaffa3ffddd7aa7f7a33a
-- 070:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7abbbbbbbbbb7abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 071:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 072:5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557a5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
-- 073:555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555573333555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
-- 074:55555555555555555555555555555555555557a555555555555555555555555555555555555555555555555555555555555555533333355553553555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
-- 075:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33300333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 076:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33000033aaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 077:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb330000337777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbb7abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 078:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfbbbbb330033bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 079:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfffbbbbb3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 080:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333300333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfbbbbb7a33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7abbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 081:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33000033bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333bbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 082:5555555555555555555555555555555555330000335555555555555555555555555555555555555555555555555555555555557a5555555555555555555555555555555555555555555555555555555555553333335555555555555555555555555555555555555555555555555555555555555555555555
-- 083:5555555555555555555555555555555555533003355555555555555555555555555555555555555555555555555555555555357a5555555555555555555555555555555555555555555555555555555555533300333555555555555555555555555555555555555555555555555555555555555555555555
-- 084:55555555555555555555555555555555557a33337a555555555555555555555555555555555555555555555555555555555557a55555555555555555555555555555555555555555555535555555555555533000033555555555555555555555555555555555555555555555555555555555555555555555
-- 085:5555555555555555555555555555555557a5533557a55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555533000033555555555555555555555555555555555555555555555555555555555555555555555
-- 086:555555555555555555555555555555557a555555557a5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555553300335555555555555555555555555555555555555555555555555555555555555555555555
-- 087:55555555555555555555555555555557a55555555557a55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557a33337a555555555555555555555555555555555555555555555555555555555555555555555
-- 088:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7abb33bb7abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 089:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7abbbbbbbb7abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 090:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7abbbbbbbbbb7abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbbbbbbbb
-- 091:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 092:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 093:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 094:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 095:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b7b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 096:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 097:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b7b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 098:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 099:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbeee333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 100:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b7b3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbeeee333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 101:555555555555555555555555555555555555555555555555555555555555555555555555555555555555e33333333333333555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555333555555555555555555555555555555555555
-- 102:555555555555555555555555555555555555555555555555555555555555555555555555555555555555e33333333333333555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555553575355555555555555555555555555555555555
-- 103:55555555555555555555555555555555555555555555555555555555555555555555555555555555533333333333333333377aa55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
-- 104:55555555555555555555555555555555555555555555555555555555555555555555555555555555533333333333333333377aa55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
-- 105:555555555555555555555555555555555555555555555555555555555555555555555555555555555333333333333330077aa3355555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
-- 106:555555555555555555555555555555555555555555555555555555555555555555555555555555555333333333333330077aa3355555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
-- 107:5555555555555555555555555555555555555555555555555555555555555555555555555555555551133333333330077aa33333377aa55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
-- 108:5555555555555555555555555555555555555555555555555555555555555555555555555555555551133333333330077aa33333377aa55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
-- 109:55555555555555555555555555555555555555555555555555555555555555555555555555555555555111133000077aa33330077aa5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
-- 110:55555555555555555555555555555555555555555555555555555555555555555555555555555555555111133000077aa33330077aa5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
-- 111:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11111177aaaa000077aa33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 112:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb11111177aaaa000077aa33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 113:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66661111aa7777aa333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 114:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66661111aa7777aa333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 115:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111bb111177aaaa333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 116:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111bb111177aaaa333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 117:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1111aa333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 118:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1111aa333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 119:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 120:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 121:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6666111133bbbbbbbbbbbbbbbbbbbbbbbbb333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 122:bbbbbb333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6666111133bbbbbbbbbbbbbbbbbbbbbbbb37773bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb37773bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 123:bbbbb37773bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111bb11bbbbbbbbbbbbbbbbbbbbbbb3777773bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3777773bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 124:bbbb3777773bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb111111bb11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 125:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 126:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 127:555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
-- 128:555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555533355555555555555555555555
-- 129:111111111111111111111111111111111111111111111111111111111111111111111111115555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555511111111111111111111111111111111111111111111111111111111111111111111111111
-- 130:1ff11f1ffff11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6666661555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444441fffff1ff11f1
-- 131:1ff11f1ff11f1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6666661555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444441ff1111fff1f1
-- 132:1fffff1ff11f1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6666661555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444441ffff11fffff1
-- 133:1ff11f1ffff11bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6666661555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444441ff1111ff1ff1
-- 134:1ff11f1ff1111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb6666661555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444441fffff1ff11f1
-- 135:111111111111111111111111111111111111111111111111111111111111111111111111115555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555511111111111111111111111111111111111111111111111111111111111111111111111111
-- </SCREEN>

-- <PALETTE>
-- 000:140c1c44243430346d4e4a4e854c30346524d04648757161597dced27d2c8595a16daa2cd2aa996dc2cadad45edeeed6
-- </PALETTE>

