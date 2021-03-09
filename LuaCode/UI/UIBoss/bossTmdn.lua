--boss倒计时
bossTmdn = {Name = "bossTmdn"}
local My = bossTmdn
My.eChange = Event()
My.eEnd = Event()

function My:Init( )
    self.Timer = ObjPool.Get(DateTimer);
	self.Timer.invlCb:Add(self.InvCountDown, self);
	self.Timer.complete:Add(self.EndCountDown, self);
	self:InitTime();
end
--初始化地图总时间f
function My:InitTime()
	local mapId = User.instance.SceneId
	if mapId == nil then
		return;
	end
	if mapId == 0 then
		return;
	end
	local mapInfo = SceneTemp[tostring(mapId)];
	if mapInfo == nil then
		return;
	end
	self.mapAllTime = mapInfo.stayTime;
    self.curTime = -1;
    self:SetTime(self.mapAllTime)
end
function My:InvCountDown()
	self:UpdateSlider();
end
--服务器重新设置时间
function My:reTime(  )
    local time = NetBoss.QuitTime;
	if time > 0 then
		self:SetTime(time);
	else
		self:EndCountDown();
	end
end

function My:SetTime(time)
	if self.Timer == nil then
		return;
	end
	if self.mapAllTime == nil then
		return;
	end
	local countTime = self.mapAllTime - time;
	if self.Timer.running then
		self.Timer.cnt = countTime;
		return;
	end
	self.Timer.seconds = self.mapAllTime;
	self.Timer:Start();
	self.Timer.cnt = countTime;
	self:UpdateSlider();
end

function My:UpdateSlider()
	if self.Timer == nil then
		return;
	end
	local min,sec = math.modf(self.Timer.cnt/60);
	if self.curTime == min then
		return;
    end
    self.curTime=min;
    local vl = min*0.01
	self.eChange(vl,min);
end

function My:EndCountDown()
    self.eEnd();
    self:Clear();
end

function My:Clear()
    if self.Timer==nil then
        return
    end
	self.Timer:AutoToPool();
	self.Timer = nil;
    self.mapAllTime = nil;	
    self.curTime = nil;        
end

return My;