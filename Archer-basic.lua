--[[
REQUIREMENTS 
 \\\\\\\\\\\\\\\\\\\\\\\\\\\\
 A Combat Pet
 Use 600hp-800hp pots at 50%
 white herb @ 60% 
Use your head when it comes to gear 1.7k Defense  highly recommended
put Rapid shot, Sharp Eyes, Arrow Storm,ScrewDriver Shot in a macro and assign it to key 'A'
--]]


g_ArcherScript = nil

class 'ArcherScript'
function ArcherScript:__init(app)
  self.name = "Archer-basic"
  self.app = app
  self.game = app.Game
  self.dx = app.DirectX
  self.fontDesc  = self.dx:CreateFont(18, 12, 400, false, "Arial")  
  self.fontObjectList  = self.dx:CreateFont(13, 12, 400, false, "Arial")  
  self.mouse = Vector2(0,0)
  self.myPC = nil  
  self.camera = nil
  self.mainsystem = self.game:GetMainSystem()
  self.objects = { {} }
  self.enabled = false
  self.state = 1
  self.time_lastheal = 0
  self.time_bufmanager = 0
  self.time_queue = 0
  self.queuedkeys = { }
  
  print("ArcherScript()") --debug
end

function ArcherScript:GetScriptName()
  return self.name
end

function ArcherScript:Macro1()
  self:QueueKeyEvent(0x1E)  -- A
  --self:QueueKeyEvent(0x2D)  -- X
end

function ArcherScript:null()
  --self:QueueKeyEvent(0x21) -- F
  --self:QueueKeyEvent(0x1F) -- S
  --self:QueueKeyEvent(0x2C) -- Z
end

function ArcherScript:ShadowChaser()
  self:QueueKeyEvent(0x1F) -- S
  --self:QueueKeyEvent(0x21) -- F
  --self:QueueKeyEvent(0x2F) -- V
end

function ArcherScript:null3()
  self:QueueKeyEvent(0x12) -- E
end

function ArcherScript:null2()
  self:QueueKeyEvent(0x10) -- Q
end

function ArcherScript:null()
  self:QueueKeyEvent(0x11) -- W
  --self:QueueKeyEvent(0x14) -- T
end

function ArcherScript:GetClientTime()
  return self.mainsystem:GetClientTime()
end

function ArcherScript:QueueKeyEvent(key)
  local t = { vk = key, 
              state = 0, -- 0 awaiting, 1 = down, 2 = up (finished)
			  t = self:GetClientTime() 
			}
  self.queuedkeys[#self.queuedkeys+1] = t
end

function ArcherScript:KeyPressManager()
  for i = 1, #self.queuedkeys do
    local t = self.queuedkeys[i]
	if t.state == 0 then
	  local interval = self:GetClientTime() - self.time_queue
	  if interval > 50 then
	    t.state = 1
	    self.app:KeyDown(t.vk)
	    self.time_queue = self:GetClientTime()
	  end
	elseif t.state == 1 then
	  local interval = self:GetClientTime() - t.t
	  if interval > 50 then
	    self.app:KeyUp(t.vk)
		t.state = 2
	  end
    end    	
  end 
end

function ArcherScript:AttackManager(target)

   local dist = self:GetDistance(target)
   local pos = target:GetPos()
   local _floor = math.abs(pos.z - self.myPC:GetPos().z)/100
  
   if dist > 1 and 
   _floor < 0.3 then
  
     local out = Vector3(0,0,0)
	 if self.camera:WorldToScreen(pos, out) then
		local screen = Vector2(out.x,out.y)
		self.game:Move2D(screen)
	 end
   end
   
   if _floor > 1 then -- 1m above or below of local pc
   
     -- can't hit :((
     return
   end
      
   if dist > 8 then
     -- enemy too far	 
	 --print("too far")
     return
   end

   if dist < 7	 then	    -- enemy only in Macro1 (4m range)
     self:Macro1()
	 return
   end
   
   local spirit = self.myPC:GetSpirit()
   
   --print(string.format("attack!! %d", self:GetClientTime()))

   -- got him in my attack range!!   
   if spirit > 15 then --check if can use holyblast
	  self:Macro1()
	  else -- no spirt enough :((
     --self:null()
	end
	end


function ArcherScript:SkillManager(target)
  local t = self:GetClientTime() - self.time_lastheal
  if t < 400 then
    return
  end

  local health = self.myPC:GetHealth()
  local maxHealth = self.myPC:GetMaxHealth()
    
  local percent = 70
  local minHealth = (percent/100)*maxHealth
  
  --print(string.format("%f %f", health, minHealth))
  
  --print("min health %f", minHealth)

    self:BufManager()
    self:AttackManager(target)
    
	
	self.time_lastheal = self:GetClientTime()  
end	

function ArcherScript:Macro()
  --self:QueueKeyEvent(0x14) -- T
end

function ArcherScript:BufManager()
  local t = self:GetClientTime() - self.time_bufmanager
  if t < 6000*1 then --every 30s
    return
  end
  --self:null3()
  --self:null2()
  --self:null1()
  --self:null()
  self.time_bufmanager = self:GetClientTime()
end

function ArcherScript:DrawArea(camera, range, color, pos)
  local step = (math.pi * 2) / 30 -- 30 is the precision, a higher value will increase a lot the cpu usage
  local a = 0.0;
  
  local sp = Vector3(0,0,0)
  local ep = Vector3(0,0,0)
	
  local oldpos = Vector3(0,0,0)
  local newpos = Vector3(0,0,0)
  
  if not camera:WorldToScreen(pos, newpos) then --first checks if the object is in screen space
    return
  end
        
  repeat  
    oldpos.x = (range * math.cos(a)) + pos.x
    oldpos.y = (range * math.sin(a)) + pos.y
    oldpos.z = pos.z
	
	a = a + step
	
	newpos.x = (range * math.cos(a)) + pos.x
	newpos.y = (range * math.sin(a)) + pos.y
	newpos.z = pos.z
  	    		
	if camera:WorldToScreen(newpos, sp) and camera:WorldToScreen(oldpos, ep) then	  
	  self.dx:Draw2DLine(sp.x,sp.y,ep.x,ep.y,1, color)
	end		
  until a >= math.pi * 2
end

function ArcherScript:GetDistance(obj)
  local p1 = self.game:GetMyPC():GetPos()
  local p2 = obj:GetPos()

  local fLen = (p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y) + (p2.z - p1.z) * (p2.z - p1.z);
  if fLen > 0 then
	return math.sqrt(fLen) / 100
  end
  return 0
end

function ArcherScript:ListObjects()
  if not self.enabled then
    return
  end
  local x = 10
  local y = 100 
  local olddist = 999
  local target = nil
  
  self.fontObjectList:Draw(x,y,0,0, clYellow, string.format("count %d", #self.objects))
  
  local out = Vector3(0,0,0)
      
  for i = 1, #self.objects do
   
    local pc = self.objects[i]
	local oid = pc:GetOID()
     
	if pc:GetType() ~= 2 and  --drops are type 2 then we ignore them
	   oid > 0x10000 and  --npcs oids are usually < 0x10000, not a safe way but works
	   pc:GetHealth() > 0 and --ignore if dead
	   pc:GetMaxHealth() > 150000.0 
	   then --this check is for identifying targets in lulu village map, also, without this pets and players are also listed (an uid will be added soon)	   
	   if oid ~= self.myPC:GetOID() then	    
	    
		 local dist = self:GetDistance(pc)
	     local pos = pc:GetPos()
		 		 
		 y = y + 10
         self.fontObjectList:Draw(x,y,0,0, clYellow, string.format("%02.0f M", dist))
		 
		 if self.camera:WorldToScreen(pos, out) then		  
		   self.fontObjectList:Draw(out.x,out.y,0,0, clGreen, string.format("%1.0fM", dist))
         end
		 
	     if dist < olddist then
	       olddist = dist
		   target = pc
	     end
	   end
	end
  end  
  
  -- check if our target is visible on screen
  
  if target then 
    local pos = target:GetPos()
	local out = Vector3(0,0,0)
    if self.camera:WorldToScreen(pos, out) then
	  self:DrawArea(self.camera, 1*100, clRed, pos) -- 1m radius
	  return target
	end
  end  
end

function ArcherScript:OnUpdate()
  --self.fontDesc:Draw(100,200,0,0, clGreen, string.format("MapID - %u", self.game:GetCurrentMapID()))
  
  local color = clRed
  local sBotStatus = "OFF"
  
  if self.enabled then
    sBotStatus = "ON"
    color = clGreen
    self.fontObjectList:Draw(10,90,0,0, color, string.format("Archer Bot %s", sBotStatus))
  end
  
  if not self.enabled then
    return
  end

  
  self.myPC = self.game:GetMyPC()
  if not self.myPC then
    return
  end
  
  self.state = self.myPC:GetSubState()
  self.camera = self.game:GetCamera()
  
  self.objects = self.game:GetObjects()
  
  local out = Vector3(0,0,0)  
  local pos = self.myPC:GetPos()
    	
  if self.camera:WorldToScreen(pos, out) then
    self.fontObjectList:Draw(out.x,out.y,0,0, clYellow, string.format("%d", self.state))
	self:DrawArea(self.camera, 4*100, clLightBlue, pos) --4m radius
	self:DrawArea(self.camera, 10*100, clYellow, pos) --8m radius
  end    
  
  local target = self:ListObjects()
  
  if not self.enabled then
    return
  end  
  
  if not target then
    return
  end
  
  self:SkillManager(target)
 
  self:KeyPressManager()
end

function ArcherScript:WindowProc(msg)
   if msg.message == WM_KEYUP then
    if msg.wParam == VK_F3 then
      self.enabled = not self.enabled
	  self:KeyPressManager()
	end
  elseif msg.message == WM_MOUSEMOVE then
    self.mouse.x = LOWORD(msg.lParam)
	self.mouse.y = HIWORD(msg.lParam)
  end	
end

function ArcherScript:Disable()
  self.enabled = false
end

function ArcherScript:Enable()
  self.enabled = true
end


--------------- // -------------

function ArcherScript_OnUpdate()
  g_ArcherScript:OnUpdate()
end

function ArcherScript_WindowProc(msg)
  g_ArcherScript:WindowProc(msg)
end

function Initialize()
  g_ArcherScript = ArcherScript(g_App)  
  g_App:RegisterEventListener(EVENT_FRAMERENDER_UPDATE, ArcherScript_OnUpdate)
  g_App:RegisterEventListener(EVENT_WINDOWPROC, ArcherScript_WindowProc)  
end

Initialize()
