BossKillOut = UIBase:New{Name="BossKillOut"}
local My = BossKillOut

function My:InitCustom()
    --常用工具
    local tip = "BossKillOut"
	local root = self.root
    local CG = ComTool.Get

    self.Time=CG(UILabel,root,"Container/lab_Time",tip)

    self.Timer = ObjPool.Get(iTimer)
	self.Timer.invlCb:Add(self.UpdateTimeLabel, self)
    self.Timer.complete:Add(self.EndCountDown, self)
    self.cfg.cleanOp=0;
    My.openLisnr("Add")
end
--场景改变
function My.openLisnr(func)
    EventMgr[func]("BegChgScene", My.EndCountDown)
  end
function My:UpdateData( time )
	if self.Timer == nil then
		return;
	end
	if self.Timer.running then
		self.Timer:Stop();
	end
	self.Timer.seconds = time
    self.Timer:Start()
	self:UpdateTimeLabel()
end

function My:UpdateTimeLabel()
	if self.Time then
		if(self.Timer == nil) then
			return;
		end
		local time = self.Timer:GetRestTime();
		time = math.round(time);
		self.Time.text = tostring(time);
	end
end
function My:EndCountDown()
    SceneMgr:QuitScene();
end

function My:ChangeSecne(  )
    self.Timer.seconds=0;
    self.IsStart = false
    My.cfg.cleanOp=1;
    self:Close()
end

function My:Clear()
    if self.Timer then
		self.Timer:AutoToPool()
	end
	self.Timer = nil
	self.Time = nil
	self.Label = nil
    My.openLisnr("Remove")
end

return My
