UIOnWay = UIBase:New{Name="UIOnWay"}
local My = UIOnWay
function My:InitCustom()
    Hangup:Pause(My.Name)
    --常用工具
    local tip = "UIOnWay"
	local root = self.root
    local CG = ComTool.Get

    self.time=CG(UILabel,root,"bg/lab_time",tip)
    self.close=CG(UIButton,root,"bg/btn_close",tip)
    
    self:ClickEvent()
    self.Timer=ObjPool.Get(iTimer)
	self.Timer:Start(5,1);
    self.Timer.invlCb:Add(self.InvCountDown, self);
    self.Timer.complete:Add(self.closeClick, self);
    self:InvCountDown()
end

function My:ClickEvent()
   local US = UITool.SetLsnrSelf
   US(self.close, self.closeClick, self)
end

function My:InvCountDown(  )
    if self.Timer == nil then
		return;
    end
    local time = math.ceil(self.Timer:GetRestTime())
    self.time.text=time
end

function My:closeClick()
    self:Close();
     Hangup:Resume(My.Name)
     Hangup:SetAutoHangup(true);
     MissionMgr:AutoExecuteActionOfType(1)
end

function My:Clear()
    if self.Timer~=nil then
        self.Timer:AutoToPool();
        self.Timer = nil;
    end
end

return My
