--region UICountDownTip.lua
--倒计时tip
--此文件由[HS]创建生成


UICountDownTip = UIBase:New{Name ="UICountDownTip"}
local M = UICountDownTip

local Log = iTrace.Log
--注册的事件回调函数
M.EndCb = Event()

function M:InitCustom()
	local name = "倒计时tip"
	local go = self.gbj
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
   	self.Container = T(trans, "Container")
   	self.Time = C(UILabel, trans, "Container/Time")
	self.Label = C(UILabel, trans, "Container/Label")
	self.cause = C(UILabel, trans, "Container/cause")  
   	self.Timer = ObjPool.Get(iTimer)
	self.Timer.invlCb:Add(self.InvCountDown, self)
    self.Timer.complete:Add(self.EndCountDown, self)
end

function M:UpdateData(time, des)
	self.cause.text="";	
	self:UpdateLabel(des)
	self:UpdatTime(time)
end

function M:UpdateCause(des)
	self.cause.text=des;
end

function M:UpdatTime(time)
	if self.Timer == nil then
		return;
	end
	if self.Container == nil then
		return;
	end
	if self.Timer.running then
		self.Timer:Stop();
	end
	self.Timer.seconds = time
    self.Timer:Start()
	self:UpdateTimeLabel()
	self.Container:SetActive(true)
end

function M:UpdateTimeLabel()
	if self.Time then
		if(self.Timer == nil) then
			return;
		end
		local time = self.Timer:GetRestTime();
		time = math.round(time);
		self.Time.text = tostring(time);
	end
end

function M:UpdateLabel(des)
	if StrTool.IsNullOrEmpty(des) then
		Log("hs", "传入的描述为空")
		return
	end
	if self.Label then
		self.Label.text = des
	end
end

function M:InvCountDown()
	self:UpdateTimeLabel()
end

function M:EndCountDown()
	if self.Container then
    	self.Container:SetActive(false)
    end
	self.EndCb()
	self.IsStart = false
end

function M:EndDown()
	if self.Container then
    	self.Container:SetActive(false)
    end
	self.Timer.seconds=0;
	self.IsStart = false;
end


function M:DisposeCustom()
	if self.Timer then
		self.Timer:AutoToPool()
	end
	self.Timer = nil
	self.EndCb:Clear()
	self.Container = nil
	self.Time = nil
	self.Label = nil

end

return M
--endregion
