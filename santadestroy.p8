pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
p={}

-- -1 none 0 blue 1 red 2 yellow
activeswitch=-1

curlvl=1

objects={}

snow={}
snowrfl=10
snowclk=0

camx=0
camy=0

--current cutscene
cs=0

--door
d={}

liftable=0

levels={
	--{x,y},{w,h},haskey,activeswitch
	{{0,0},{20,9},1,1}
}
-->8
function _init()
 ---1:idle 0:run 1:jump 2:trylift
 p.sstate=-1
 p.jumpup=3.8
 p.scounter=0
 p.clk=0
 p.animspd=4
 p.s=96
 p.flip=false
 p.x=10
 p.y=10
 p.w=1
 p.h=2
 p.up=0
 p.g=0.5
 p.maxfall=-2.5
 p.xspd=1
 p.hasitem=0
 p.jumpspg=6

	palt(0,false)
	palt(11,true)
	spawnitems(1)
	refillsnow()
end

function _draw()
	cls(1)
	drawsnow()
	updatecam()
	drawlevel(1)
	objects:draw()
	updatecs(cs)
	p:draw()

	print("cpu "..stat(1),0+camx,0+camy,7)
end

function drawdebug()
	cls(1)
	drawsnow()
	updatecam()
	drawlevel(1)
	p:draw()
	objects:draw()
	print("cpu "..stat(1),0+camx,0+camy,7)
end

function _update()
	--drawdebug()
 if(cs==0)then
 	p:move()
 	objects:update()
 	updatesnow()
 end
end
-->8
function objects:update()
	for o=1,#objects do
		if(objects[o].spr==118)then --if is key
			if(p.hasitem==objects[o])then
				objects[o].x=p.x
				objects[o].y=p.y-8
			else
				objects[o].move()
			end
		end
	end
end
-->8
function p:move()
	if(p:grounded())then
		if(btn(4))then
			if(p.hasitem!=0)then
				--throw item
				p.hasitem.xspd=1.6
				p.hasitem.flip=false
				if(p.flip)p.hasitem.flip=true
				p.hasitem.yspd=1.6
				p.hasitem.thrown=true
				p.canlift=false
				p.hasitem=0
			else
				--lift item
				p.hasitem=p:lift()
				if(p.hasitem==0)p.sstate=2
			end

			return
		else
			p.up=0
			if(btn(0)or btn(1))p.sstate=0
			if(btn(2))p.up=p.jumpup
			if(not btn(0) and not btn(1))p.sstate=-1 
		end
	else
		p.sstate=1
	end

	p:fall()

	if(btn(1))then
		p.x+=p.xspd
	elseif(btn(0))then
		p.x-=p.xspd
	end

	if(p:collideright	())p.x=flr(p.x/8)*8
	if(p:collideleft	())p.x=flr(p.x/8+0x0.ffff)*8 --wizardry for ceil with flr

	if(p.x>=d.x
		and p.x<=d.x+d.w*8
		and p.y>=d.y
		and p.y<=d.y+d.h*8)then
		cs=1
	end
end

function p:lift()
	return liftable
end

function p:collideleft()
	--bottomleft
	blfx=self.x
	blfy=self.y+self.h*8-1

	--upleft
	ulfx=self.x
	ulfy=self.y

	while blfy>=ulfy do
		print(blfx,50,10,10)
		print(blfy,70,10,10)
		--print(lfx<rfx,70,30,10)
		--pset(blfx,blfy,10)
		tile=mget(blfx/8,blfy/8)
		if( fget(tile,0) and not fget(tile,1))then
			return true
		end
		blfy-=1
	end

	return false
end

function p:collideright()
	--bottomleft
	brfx=self.x+self.w*8-1
	brfy=self.y+self.h*8-1

	--upleft
	urfx=self.x+self.w*8-1
	urfy=self.y

	while brfy>=urfy do
		print(brfx,50,10,10)
		print(brfy,70,10,10)
		--print(lfx<rfx,70,30,10)
		--pset(brfx,brfy,10)
		tile=mget(brfx/8,brfy/8)
		if( fget(tile,0) and not fget(tile,1))then
			return true
		end
		brfy-=1
	end

	return false
end

function p:fall()

	self.up-=self.g
	if(self.up<self.maxfall)self.up=self.maxfall
	self.y-=self.up


	if(p:collidetop())then
		self.y=flr(self.y/8+0x0.ffff)*8
	end
	if( p:grounded() ) then
		self.y=flr(self.y/8)*8
	end
end

function p:collidetop()
	-- left foot
	lfx=self.x
	lfy=self.y

	--right foot
	rfx=self.x+self.w*8-1
	rfy=self.y

	while lfx<=rfx do
		-- print(lfx,50,10,10)
		-- print(rfx,70,10,10)
		-- print(lfx<rfx,70,30,10)
		pset(lfx,lfy,10)
		tile=mget(lfx/8,lfy/8)
		if( fget(tile,0) and not fget(tile,1))then
			return true
		end
		lfx+=1
	end

	return false
end

function p:grounded()
	-- left foot
	lfx=self.x
	lfy=self.y+self.h*8

	--right foot
	rfx=self.x+self.w*8-1
	rfy=self.y+self.h*8


	while lfx<=rfx do
		-- print(lfx,50,10,10)
		-- print(rfx,70,10,10)
		-- print(lfx<rfx,70,30,10)
		pset(lfx,lfy,10)
		local x=lfx/8
		local y=lfy/8
		tile=mget(lfx/8,lfy/8)
		if( fget(tile,0))then
			return true
		end

		if(p.up<=0 and fget(tile,7))then --land on switch
			if(tile==76)then
				activeswitch=0
				mset(x,y,92)
			elseif(tile==77)then
				activeswitch=1
				mset(x,y,93)
			elseif(tile==78)then
				activeswitch=2
				mset(x,y,94)
			end
			switchmap(curlvl)
			return true
		end

		--grounded on object
		if(p.up<=0)then
			for o=1,#objects do
				if(lfx>=objects[o].x and lfx<=objects[o].x+objects[o].w*8)then
					if(lfy>=objects[o].y and lfy<=objects[o].y+objects[o].h*8)then
						--is liftable
						if(objects[o].canlift)then
							liftable=objects[o]
							return true
						end
						--spring
						if(objects[o].spr==80)then
							p.up=p.jumpspg
						end
					end
				end
			end
		end

		lfx+=1
	end
	liftable=0

	return false
end
-->8
function switchmap(i)
	celx=levels[i][1][1]
	cely=levels[i][1][2]
	celw=levels[i][2][1]
	celh=levels[i][2][2]

	local i=celx
	local j=cely

	while(j<cely+celh)do
		while(i<celx+celw)do
			if(mget(i,j)==70)mset(i,j,86) --hard blue to transp blue (block)
			if(mget(i,j)==74)mset(i,j,90) --hard blue to transp blue (ladder)
			if(mget(i,j)==109)mset(i,j,111) --hard blue to transp blue (platform)

			if(mget(i,j)==69)mset(i,j,85) --hard red to transp red (block)
			if(mget(i,j)==125)mset(i,j,127) --hard red to transp red (ladder)
			if(mget(i,j)==73)mset(i,j,89) --hard red to transp red (platform)

			if(mget(i,j)==68)mset(i,j,84) --hard yellow to transp yellow (block)
			if(mget(i,j)==72)mset(i,j,88) --hard yellow to transp yellow (ladder)
			if(mget(i,j)==122)mset(i,j,95) --hard yellow to transp yellow (platform)

			if(activeswitch==0)then
				if(mget(i,j)==86)mset(i,j,70) --transp blue to hard blue (block)
				if(mget(i,j)==90)mset(i,j,74) --transp blue to hard blue (ladder)
				if(mget(i,j)==111)mset(i,j,109) --transp blue to hard blue (platform)

				if(mget(i,j)==93)mset(i,j,77) --erect red switch
				if(mget(i,j)==94)mset(i,j,78) --erect yellow switch
			elseif(activeswitch==1)then
				if(mget(i,j)==85)mset(i,j,69) --transp red to hard red (block)
				if(mget(i,j)==89)mset(i,j,73) --transp red to hard red (ladder)
				if(mget(i,j)==127)mset(i,j,125) --transp red to hard red (platform)

				if(mget(i,j)==92)mset(i,j,76) --erect blue switch
				if(mget(i,j)==94)mset(i,j,78) --erect yellow switch
			elseif(activeswitch==2)then
				if(mget(i,j)==84)mset(i,j,68) --transp yel to hard yel (block)
				if(mget(i,j)==88)mset(i,j,72) --transp yel to hard yel (ladder)
				if(mget(i,j)==95)mset(i,j,122) --transp yel to hard yel (platform)

				if(mget(i,j)==93)mset(i,j,77) --erect red switch
				if(mget(i,j)==92)mset(i,j,76) --erect blue switch
			end
			i+=1
		end
		j+=1
		i=celx
	end
end

function drawlevel(i)
	celx=levels[i][1][1]
	cely=levels[i][1][2]
	celw=levels[i][2][1]
	celh=levels[i][2][2]
	map(celx,cely,0,0,celw,celh)
end

function updatecam()
	celh=levels[curlvl][2][2]
	camy=0-(16-celh)*8
	camx=p.x-128/2
	if(camx<0)camx=0
	camera(camx,camy)
end

function makeobj(spr,x,y,w,h,flip,canlift,xspd,yspd,thrown,maxf, maxclk, ticktock)
	o={}
	o.spr=spr
	o.initx=x
	o.inity=y
	o.x=x
	o.y=y
	o.w=w
	o.h=h
	o.flip=flip or false
	o.canlift=canlift or false
	o.xspd=xspd or 0
	o.yspd=yspd or 0
	o.thrown=thrown or false
	o.initspr=spr
	o.maxf=maxf or 1
	o.maxclk=maxclk or -1
	o.ticktock=ticktock or -1 -- is ticktock anim?
	o.clk=0
	o.f=0
	add(objects,o)
	mset(x/8,y/8,0)

	function o:grounded()
		-- left foot
		lfx=self.x
		lfy=self.y+self.h*8

		--right foot
		rfx=self.x+self.w*8-1
		rfy=self.y+self.h*8


		while lfx<=rfx do
			pset(lfx,lfy,10)
			local x=lfx/8
			local y=lfy/8
			tile=mget(lfx/8,lfy/8)
			if(fget(tile,0))then
				return true
			end
			lfx+=1
		end
		return false
	end

	function o:collideleft()
		--bottomleft
	    	blfx=self.x
	    	blfy=self.y+self.h*8-1
	    
	    	--upleft
	    	ulfx=self.x
	    	ulfy=self.y
	    
	    	while blfy>=ulfy do
	    		print(blfx,50,10,10)
	    		print(blfy,70,10,10)
	    		--pset(blfx,blfy,10)
	    		tile=mget(blfx/8,blfy/8)
	    		if( fget(tile,0) and not fget(tile,1))then
	    			return true
	    		end
	    		blfy-=1
	    	end
	    
	    	return false
	end

	function o:collideright()
		--bottomleft
		brfx=self.x+self.w*8-1
		brfy=self.y+self.h*8-1

		--upleft
		urfx=self.x+self.w*8-1
		urfy=self.y

		while brfy>=urfy do
			print(brfx,50,10,10)
			print(brfy,70,10,10)
			--pset(brfx,brfy,10)
			tile=mget(brfx/8,brfy/8)
			if( fget(tile,0) and not fget(tile,1))then
				return true
			end
			brfy-=1
		end

		return false
	end

	return o
end

function spawnitems(i)
	celx=levels[i][1][1]
	cely=levels[i][1][2]
	celw=levels[i][2][1]
	celh=levels[i][2][2]
	local i=celx
	local j=cely

	while(j<cely+celh)do
		while(i<celx+celw)do
			--spawn player
			if(mget(i,j)==96)then
				p.x=i*8
				p.y=j*8
				mset(i,j,0)
			end
			
			--spawn door
			if(mget(i,j)==103)then
				d={}
				d.spr=103
				d.x=i*8
				d.y=j*8
				d.w=2
				d.h=2
				mset(i,j,0)
			end
			--spawn gifts
			if(mget(i,j)==105)then
				makeobj(105,i*8,j*8,1,1,false,false,0,0,false,2,3,1)
			end
			--spawn key
			if(mget(i,j)==118)then
				key=makeobj(118,i*8,j*8,1,1,false,true,0,0,false)
				
				function key:move()
					
					if(not key:grounded())then
						if(key.thrown)then
							if(key.flip and not key:collideleft())key.x-=key.xspd
							if(not key.flip and not key:collideleft())key.x+=key.xspd
							
							if(key:collideright	())key.x=flr(key.x/8)*8
							if(key:collideleft	())key.x=flr(key.x/8+0x0.ffff)*8 --wizardry for ceil with flr
						end
						key.y+=key.yspd
					end

					if(key:grounded())then
						key.thrown=false
						key.y=flr(key.y/8)*8
					end
				end
			end

			--spawn spring
			if(mget(i,j)==80)then
				makeobj(80,i*8,j*8,1,1)
			end
			i+=1
		end
		j+=1
		i=celx
	end

	printh("spawnitem i:"..i)
	printh("spawnitem j:"..j)
end

function refillsnow()
	for i=1,3 do
		makesnow(rnd(128),7)
		makesnow(rnd(128),6)
		makesnow(rnd(128),5)
	end
end

function updatesnow()
	snowdel={}
	for s=1,#snow do
		changedir=rnd(1)
		if(changedir>=0.95)snow[s].xdir=snow[s].xdir*-1
		snow[s].xoffset=rnd(1)*snow[s].xdir
		snow[s].fallspd=rnd(1.9)+0.1
		snow[s].y+=snow[s].fallspd
		snow[s].x+=snow[s].xoffset
		if(snow[s].y>128)add(snowdel,snow[s])
	end
	for s=1,#snowdel do
		del(snow,snowdel[s])
	end
	if(snowclk>snowrfl)then
	 	refillsnow()
	 	snowclk=0
	end
	snowclk+=1
end

function drawsnow()
	for s=1,#snow do
		pset(snow[s].x+camx,snow[s].y+camy,snow[s].c)
	end
end

function makesnow(xinit,col)
	s={}
	s.x=xinit
	s.y=-1
	s.xoffset=0
	s.fallspd=0
	s.xdir=1
	s.c=col
	add(snow,s)
end
-->8
function objects:draw()
	for o=1,#objects do
		spr(objects[o].spr,objects[o].x,objects[o].y)
		if(objects[o].initspr==105)animate(objects[o])
	end
end

function animate(o)
	--print(o.spr,40,40,7)
	o.clk+=1
	if(o.clk>o.maxclk)then
		o.clk=0
		o.f+=1*o.ticktock
		if(o.f>o.maxf-1 or o.f==0)then
			if(o.ticktock!=0)then
				o.ticktock*=-1
			else
				o.f=0
			end
		end
	end
	
	o.spr=o.initspr+o.f
end
-->8
function p:draw()
	if(p.sstate==1)p.s=97
	if(p.sstate==-1)p.s=96

	if(p.sstate==0)tmp=97
	if(p.sstate==2)tmp=100

	if(p.sstate==0 or p.sstate==2)then
		if(p.sstate==0)then
			if(p.scounter>1)p.scounter=0
		end
		if(p.sstate==2)then
			if(p.scounter>1)p.scounter=0
		end

		p.s=tmp+p.scounter
		p.clk+=1
		if(p.clk>p.animspd)then
			p.scounter+=1
			p.clk=0
		end
	end
	if(btn(1))then
		p.flip=false
	elseif(btn(0))then
		p.flip=true
	end

	if(p.hasitem!=0)p.s=p.s-64
	spr(self.s,self.x,self.y,self.w,self.h,self.flip)
end

-->8
csclk=0
ticktock=1

--cutscene management
function updatecs(c)
	--maxcsclk=3
	duration=20
	sx=7*8
	sy=6*8
	sw=2*8
	sh=2*8
	dx=d.x-csclk/2
	dy=d.y-csclk/2
	dw=d.w*8+csclk
	dh=d.h*8+csclk
		
	if(cs==1)then
		
		print(cs,50,50)
		csclk+=ticktock
		if(csclk>duration)then
			ticktock=-1
		end
		print(csclk,30,30)
		if(dw<0)cs=0
		
	end
	if(csclk<0)then
		cs=0
		csclk=0
		_init()
	end
	sspr(sx,sy,sw,sh,dx,dy,dw,dh)	
end
__gfx__
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00707000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00070000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00707000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb44ff4bbb44ff4bbb44ff4bff44444bb44444ffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b4944444b4944444b4944444ff9444ffff9444ffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
49a9fff449a9fff449a9fff449a944ffffa94444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
449f1f1f449f1f1f449f1f1f4494444444944444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
444f1f1f444f1f1f444f1f1f4444444444444444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
44effffe44effffe44effffe4444444444444444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
44ffffff44ffffff44ffffff4444444444444444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
448ffffb448ffffb448ffffb4444444444444444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
4888f8884888f88b4888f88b4444444b4444444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
4f88888b4f88888b4f88888bb44444bbb44444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
4bf888bb4bf888bb4bf888bbbb4448bbbb4448bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb8ff8bbbb8fff8bbb8ff8bbbb84888bb88488bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b888888bb8888888b888888bb888888bb888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b888888bb88888888888888bb888888bb888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
8888888888888888888888888888888bb8888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
8888888888888888888888888888888888888888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
53333335b3333333333333333333333b5aaaaaa5588888855cccccc533333333aaaaaaaa88888888cccccccc66666666bb0000bbbb0000bbbb0000bbbbbbbbbb
35333353333333333333333333333333a5aaaa5a85888858c5cccc5c33333333aaaaaaaa88888888cccccccc56565656b0cccc0bb088880bb0aaaa0bbbbbbbbb
33555533336336336336336336336333aa5555aa88555588cc5555cc33555533aa5555aa88555588cc5555cc65656565b0cccc0bb088880bb0aaaa0bbbbbbbbb
33533533b3363363363363363363363baa5aa5aa88588588cc5cc5cc33bbb533aabbb5aa88bbb588ccbbb5cc55555555b0cccc0bb088880bb0aaaa0bbbbbbbbb
33533533bbbbbbbbbbbbbbbbbbbbbbbbaa5aa5aa88588588cc5cc5cc33333333aaaaaaaa88888888cccccccc55555555b0cccc0bb088880bb0aaaa0bbbbbbbbb
33555533bbbbbbbbbbbbbbbbbbbbbbbbaa5555aa88555588cc5555cc33333333aaaaaaaa88888888cccccccc55555555b0cccc0bb088880bb0aaaa0bbbbbbbbb
35333353bbbbbbbbbbbbbbbbbbbbbbbba5aaaa5a85888858c5cccc5c33555533aa5555aa88555588cc5555cc55555555b000000bb000000bb000000bbbbbbbbb
53333335bbbbbbbbbbbbbbbbbbbbbbbb5aaaaaa5588888855cccccc533bbb533aabbb5aa88bbb588ccbbb5cc555555550cccccc0088888800aaaaaa0bbbbbbbb
999a9944bbbbbbbbb665566bbbbbbbbbbabababab8b8b8b8bcbcbcbcbbb9abbbabbbbbab8bbbbb8bbcbbbbbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabababa
bb6665bbbbbbbbbb66665566bbbbbbbbabababab8b8b8b8bcbcbcbcbbbb9abbbbabbbbbab8bbbbb8cbbbbbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabababab
b5bbbbbb999a994400000000bbbbbbbbbabababab8b8b8b8bcbcbcbcbbb9abbbabbbbbab8bbbbb8bbcbbbbbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabababa
bb55555bb56665bb66666650bbbbbbbbabababab8b8b8b8bcbcbcbcbbbbaabbbbabbbbbab8bbbbb8cbbbbbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbabababab
bbb6666bbb55555b50665050bbbbbbbbbabababab8b8b8b8bcbcbcbcbbb9abbbabbbbbab8bbbbb8bbcbbbbbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b555bbbbb555bbbb50650050bbbbbbbbabababab8b8b8b8bcbcbcbcbbbb9abbbbabbbbbab8bbbbb8cbbbbbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b9aa794bb9aa794b50650050bbbbbbbbbabababab8b8b8b8bcbcbcbcbbb9abbbabbbbbab8bbbbb8bbcbbbbbcbbbbbbbbb000000bb000000bb000000bbbbbbbbb
9aa999449aa99944b065005bbbbbbbbbabababab8b8b8b8bcbcbcbcbbbbaabbbbabbbbbab8bbbbb8cbbbbbcbbbbbbbbb0cccccc0088888800aaaaaa0bbbbbbbb
bb44444bbb44444bbb44444bbbb8888bbbbbbbbbbbbbbbbbbbbbbbbbbbbddddddddddbbbbb28b28bbb8bb8bbb82b82bbbccccccccccccccccccccccbbcbcbcbc
b4944444b4944444b4944444bb888888bb6bbbbbb6bbbb6bbbbbbbbbbbddddddddddddbbb6778877b778877b7788776bcccccccccccccccccccccccccbcbcbcb
49a9fff449a9fff449a9fff4bb888888bb44444bbbb6bbbbbbbbbbbbbddddddddddddddb677788777778877777887776cc6cc6cc6cc6cc6cc6cc6cccbcbcbcbc
449f1f1f449f1f1f449f1f1f78877777b4944444bb44444bbbbbbbbbdddd77777777dddd677788777778877777887776bcc6cc6cc6cc6cc6cc6cc6cbcbcbcbcb
444f1f1f444f1f1f444f1f1fbbff1f1f49a9fff4b4944444bbbbbbbbddd777aaaa777ddd288888888888888888888882bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
44effffe44effffe44effffebb7ffef744911f1149a9fff4bbbbbbbbdd777abbbba777dd677788777778877777887776bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
44ffffff44ffffff44ffffffbb77777744effffe44911f11bbbbbbbbdd77abbbbbba77dd677788777778877777887776bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
448ffffb448ffffb448ffffb7788777b44ffffff44effffebbbbbbbbdd77abbbbbba77ddb6778877b778877b7788776bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
4888f8884888f88b4888f88b7787888844fffffb44ffffffb9aaaaabdd77abbbbbba77ddbaaaaaaaaaaaaaaaaaaaaaabb8888888888888888888888bb8b8b8b8
4f88888f4f88888b4f88888b0000a000444888bb44fffffb9aa999aadd777abbbba777ddaaaaaaaaaaaaaaaaaaaaaaaa8888888888888888888888888b8b8b8b
4bf888fb4bf888bb4bf888bb88888877448888bb444888bb9aabb9aadd7777abba7777ddaa6aa6aa6aa6aa6aa6aa6aaa886886886886886886886888b8b8b8b8
bb8fffbbbb8fff8fbb8ff8fb00000077b488888b4488888b9aaaaaabdd7777abba7777ddbaa6aa6aa6aa6aa6aa6aa6abb8868868868868868868868b8b8b8b8b
b888888bb8888888b888888bb000000b8888888884888888b9aaaabbdd777abbbba777ddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b888888bb88888888888888bb0bbb0b08888888888888888bb9aabbbdd77abbbbbba77ddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
88888888888888888888888800bbbb00ff8888ffff8888ffbb9aabbbdd77aaaaaaaa77ddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
888888888888888888888888000bbb00ff8888ffff8888ffbb9aaabbdd777777777777ddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888ffffff882222228888888888888888888888888888888888888888888888888888888888888888228228888ff88ff888222822888888822888888228888
88888f8888f882888828888888888888888888888888888888888888888888888888888888888888882288822888ffffff888222822888882282888888222888
88888ffffff882888828888888888888888888888888888888888888888888888888888888888888882288822888f8ff8f888222888888228882888888288888
88888888888882888828888888888888888888888888888888888888888888888888888888888888882288822888ffffff888888222888228882888822288888
88888f8f8f88828888288888888888888888888888888888888888888888888888888888888888888822888228888ffff8888228222888882282888222288888
888888f8f8f8822222288888888888888888888888888888888888888888888888888888888888888882282288888f88f8888228222888888822888222888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555550000000000000000000000000000000000000000000000000000000000000000005555550000000000000000000000000000000000000000005555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb05555550000000000011111111112222222222333333333305555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb05555550000000000011111111112222222222333333333305555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb05555550000000000011111111112222222222333333333305555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb05555550000000000011111111112222222222333333333305555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb05555550000000000011111111112222222222333333333305555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb05555550000000000011111111112222222222333333333305555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb05555550000000000011111111112222222222333333333305555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb05555550000000000011111111112222222222333333333305555555
5555555099999999aaaaaaaaaaaaaaaa999999999999999999999999aaaaaaaaaaaaaaaa05555550000000000011111111177777777777733333333305555555
5555555099999999aaaaaaaaaaaaaaaa999999999999999999999999aaaaaaaaaaaaaaaa05555550444444444455555555570000000000777777777705555555
5555555099999999aaaaaaaaaaaaaaaa999999999999999999999999aaaaaaaaaaaaaaaa05555550444444444455555555570666666660777777777705555555
5555555099999999aaaaaaaaaaaaaaaa999999999999999999999999aaaaaaaaaaaaaaaa05555550444444444455555555570666666660777777777705555555
5555555099999999aaaaaaaaaaaaaaaa999999999999999999999999aaaaaaaaaaaaaaaa05555550444444444455555555570666666660777777777705555555
5555555099999999aaaaaaaaaaaaaaaa999999999999999999999999aaaaaaaaaaaaaaaa05555550444444444455555555570666666660777777777705555555
5555555099999999aaaaaaaaaaaaaaaa999999999999999999999999aaaaaaaaaaaaaaaa05555550444444444455555555570666666660777777777705555555
5555555099999999aaaaaaaaaaaaaaaa999999999999999999999999aaaaaaaaaaaaaaaa05555550444444444455555555570666666660777777777705555555
5555555099999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaa05555550444444444455555555570666666660777777777705555555
5555555099999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaa05555550444444444455555555570000000000777777777705555555
5555555099999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaa055555508888888888999999999777777777777bbbbbbbbb05555555
5555555099999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaa0555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555099999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaa0555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555099999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaa0555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555099999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaa0555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555099999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaa0555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555099999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb0555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555099999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb0555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555099999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb0555555088888888889999999999aaaaaaaaaabbbbbbbbbb05555555
5555555099999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb05555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
5555555099999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb05555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
5555555099999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb05555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
5555555099999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb05555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
5555555099999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb05555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb05555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb05555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb05555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb05555550ccccccccccddddddddddeeeeeeeeeeffffffffff05555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb05555550000000000000000000000000000000000000000005555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb05555555555555555555555555555555555555555555555555555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb05555555555555555555555555555555555555555555555555555555
55555550bbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb05555555555555555555555555555555555555555555555555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb05555550000000555556667655555555555555555555555555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb05555550000000555555666555555555555555555555555555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb0555555000000055555556dddddddddddddddddddddddd5555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb055555500060005555555655555555555555555555555d5555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb05555550000000555555576666666d6666666d666666655555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb05555550000000555555555555555555555555555555555555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb05555550000000555555555555555555555555555555555555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb05555555555555555555555555555555555555555555555555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb05555555555555555555555555555555555555555555555555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb05555556665666555556667655555555555555555555555555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb05555556555556555555666555555555555555555555555555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb0555555555555555555556dddddddddddddddddddddddd5555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb055555565555565555555655555555555555555555555d5555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb05555556665666555555576666666d6666666d666666655555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb05555555555555555555555555555555555555555555555555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbb05555555555555555555555555555555555555555555555555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb05555555555555555555555555555555555555555555555555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb05555555555555555555555555555555555555555555555555555555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb05555550005550005550005550005550005550005550005550005555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb055555011d05011d05011d05011d05011d05011d05011d05011d0555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb05555501110501110501110501110501110501110501110501110555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb05555501110501110501110501110501110501110501110501110555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb05555550005550005550005550005550005550005550005550005555
55555550bbbbbbbbbbbbbbbb99999999aaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb05555555555555555555555555555555555555555555555555555555
55555550000000000000000000000000000000000000000000000000000000000000000005555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
5555555555555555555555555555555555555555555555555555555555555555555555b9aaaaab55555555555555555555555555555555555555555555555555
55555555555555555555555557555555ddd5555d5d5d5d5555d5d55555555d555555559aa999aa56666666666666555555555555577777555555555555555555
55555555555555555555555577755555ddd555555555555555d5d5d5555555d55555559aabb9aa56dd66dd66ddd655555666665577dd77755666665556666655
55555555555555555555555777775555ddd5555d55555d5555d5d5d55555555d5555559aaaaaab566d666d66d6d6555566ddd665777d777566ddd66566ddd665
55555555555555555555557777755555ddd555555555555555ddddd555ddddddd55555b9aaaabb566d666d66ddd6555566d6d665777d77756666d665666dd665
555555555555555555555757775555ddddddd55d55555d55d5ddddd55d5ddddd555555bb9aabbb566d666d66d6d6555566d6d66577ddd77566d666656666d665
555555555555555555555755755555d55555d555555555555dddddd55d55ddd5555555bb9aabbb56ddd6ddd6ddd6555566ddd6657777777566ddd66566ddd665
555555555555555555555777555555ddddddd55d5d5d5d55555ddd555d555d55555555bb9aaabb56666666666666555566666665777777756666666566666665
555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555ddddddd566666665ddddddd5ddddddd5
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddd7bddddddddddddddddddddddb53333335588888855cccccc5dddddddd3333333388888888cccccccc66666666bb0000bbbb0000bbbb0000bbbbbbbbbb
1ddddd7ddddddddddddddddddddddddd3533335385888858c5cccc5cdddddddd3333333388888888cccccccc56565656b0cccc0bb088880bb033330bbbbbbbbb
115555dddd6dd6dd6dd6dd6dd6dd6ddd3355553388555588cc5555ccdd5555dd3355553388555588cc5555cc65656565b0cccc0bb088880bb033330bbbbbbbbb
115555ddbdd6dd6dd6dd6dd6dd6dd6db3353353388588588cc5cc5ccddbbb5dd33bbb53388bbb588ccbbb5cc55555555b0cccc0bb088880bb033330bbbbbbbbb
115555ddbbbbbbbbbbbbbbbbbbbbbbbb3353353388588588cc5cc5ccdddddddd3333333388888888cccccccc55555555b0cccc0bb088880bb033330bbbbbbbbb
115555ddbbbbbbbbbbbbbbbbbbbbbbbb3355553388555588cc5555ccdddddddd3333333388888888cccccccc55555555b0cccc0bb088880bb033330bbbbbbbbb
1222225dbbbbbbbbbbbbbbbbbbbbbbbb3533335385888858c5cccc5cdd5555dd3355553388555588cc5555cc55555555b000000bb000000bb000000bbbbbbbbb
22222225bbbbbbbbbbbbbbbbbbbbbbbb53333335588888855cccccc5ddbbb5dd33bbb53388bbb588ccbbb5cc555555550cccccc00888888003333330bbbbbbbb
999a9944bbbbbbbbb665566bbbbbbbbbb3b3b3b3b8b8b8b8bcbcbcbcbbb9abbb3bbbbb3b8bbbbb8bbcbbbbbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb6665bbbbbbbbbb66665566bbbbbbbb3b3b3b3b8b8b8b8bcbcbcbcbbbb9abbbb3bbbbb3b8bbbbb8cbbbbbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b5bbbbbb999a994400000000bbbbbbbbb3b3b3b3b8b8b8b8bcbcbcbcbbb9abbb3bbbbb3b8bbbbb8bbcbbbbbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb55555bb56665bb66666650bbbbbbbb3b3b3b3b8b8b8b8bcbcbcbcbbbbaabbbb3bbbbb3b8bbbbb8cbbbbbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb6666bbb55555b50665050bbbbbbbbb3b3b3b3b8b8b8b8bcbcbcbcbbb9abbb3bbbbb3b8bbbbb8bbcbbbbbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b555bbbbb555bbbb50650050bbbbbbbb3b3b3b3b8b8b8b8bcbcbcbcbbbb9abbbb3bbbbb3b8bbbbb8cbbbbbcbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b9aa794bb9aa794b50650050bbbbbbbbb3b3b3b3b8b8b8b8bcbcbcbcbbb9abbb3bbbbb3b8bbbbb8bbcbbbbbcbbbbbbbbb000000bb000000bb000000bbbbbbbbb
9aa999449aa99944b065005bbbbbbbbb3b3b3b3b8b8b8b8bcbcbcbcbbbbaabbbb3bbbbb3b8bbbbb8cbbbbbcbbbbbbbbb0cccccc00888888003333330bbbbbbbb
bb8888bbbbb8888bbbb8888bbbb8888bbbbbbbbbbbbbbbbbbbbbbbbbbbb1c1c1c1c1cbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b888888bbb888888bb888888bb888888bbb6bbbb6bbbb6bbbbbbbbbbbb1c1c1c1c1c1cbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
8888888b7b888888bb888888bb888888bb8888bbbb6bbbbbbbbbbbbbb1c177777777c1cbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
8777777bb88777777887777778877777b888888bbb8888bbbbbbbbbb1c17777777777c1cbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7ff1f1fbbbff1f1fbbff1f1fbbff1f1f8888888bb888888bbbbbbbbbc17777aaaa7777c1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b7ffef7bbb7ffef7bb7ffef7bb7ffef78777777b8888888bbbbbbbbb1c777a0000a7771cbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b777777bbb777777bb777777bb7777777fffeffb87777700000000000077a000000a77c1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b887778bb888777bb888777b7788777bb7ffff7b7fffef07777777777077a000000a771cbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
88887888778788888887887777878888b777777bb7ffff07b9aaaaab7077a000000a77c1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7700a0777700a0777700a0770000a000b887778bb77777079aa999aa70777a0000a7771cbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7788887788888877778888888888887788887888b88777079aabb9aa707777a00a7777c1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0000000000000000000000000000007788888888888878079aaaaaab707777a00a77771cbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0000000bb000000bb000000bb000000b0000a00088888807b9aaaabb70777a0000a777c1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
0bbbb0bb000bb0bbbb00bb0bb0bbb0b0b000000b0000a007bb9aabbb7077a000000a771cbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00bbb00b00bbb00bb00b00bb00bbbb00770bb07777000007bb9aabbb7077aaaaaaaa77c1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
000bb0000bbbb000b000000b000bbb00770bb077770bb007bb9aaabb707777777777771cbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00000000000000000000000000000000000000000000000777777777700000000000000000000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001030303010101000000000180808000000000000202020000000000000000000000000000000000000000000303030000000000000000000003030303030300
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000056000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000690000670056000000000000690000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000056000000007600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6f6f5a6f6f6f40404040000000404042424242420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005a00000000000045454545560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005a00000000000045000000560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005a00600000000045000000560000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005a000000004c0045005d00564040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
