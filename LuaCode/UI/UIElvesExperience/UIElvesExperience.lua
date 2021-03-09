UIElvesExperience = UIBase:New{Name = "UIElvesExperience"}

local My = UIElvesExperience

function My:InitCustom()
    local root,des = self.root,self.Name
    local FindC,SetB = TransTool.FindChild,UITool.SetBtnClick
    local time = 10
    SetB(root,"experBtn",des,self.OnClick,self)
    self.desLab = ComTool.Get(UILabel,root,"desLab")
    self.dataLab = ComTool.Get(UILabel,root,"dataLab")
    self.autoLab = ComTool.Get(UILabel,root,"autoLab")
    self.autoDesLab = ComTool.Get(UILabel,root,"autoDesLab")
    self.timeLab = ComTool.Get(UILabel,root,"timeLab")
    self:InitLab()
    self:CreateTimer()
    self:UpTimerLab(time)
    self:UpTimer(time)
end

--初始化文本
function My:InitLab()
    self.desLab.text = "打怪经验提升"
    self.dataLab.text = "50%"
    self.autoLab.text = "自动拾取"
    self.autoDesLab.text = "掉落物品"
end

--更新计时器
function My:UpTimer(time)
    if self.timer == nil then
        iTrace.eError("GS","没有发现计时器")
        return
    end
    local timer = self.timer
    timer.seconds = time
    timer:Start()
end

--创建计时器
function My:CreateTimer()
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown,self)
    timer.complete:Add(self.EndCountDown,self)
end

--间隔倒计时
function My:InvCountDown()
    local times = self.timer:GetRestTime()
    local time = math.floor(times)
    self:UpTimerLab(time)
end

--结束倒计时
function My:EndCountDown()
    self:ReqUseItem()
end

--初始化计时器文本
function My:UpTimerLab(time)
    if LuaTool.IsNull(self.timeLab) then return end 
    self.timeLab.text = "(" .. time .. "秒之后自动使用)"
end

--点击立即体验按钮
function My:ReqUseItem()
    local mgr = PropMgr
    mgr.ReqUse(40003,1,1)
    -- self:OpenUIShowPendant()
    self:Close()
end

--点击立即体验按钮
function My:OnClick()
    self:ReqUseItem()
end

function My:OpenUIShowPendant()
	UIMgr.Open(UIShowPendant.Name, self.OpenModCb, self)
end

function My:OpenModCb(name)
	local temp = GlobalTemp["109"].Value2
	if not temp then return end
	local ui = UIMgr.Get(name)
	if ui then
		ui:ShowPendantItem(temp)
	end
end

--重写UIBase方法，持续显示
function My:ConDisplay()
    do return true end
end

--清理缓存
function My:Clear()
    self.timeLab = nil
    self.desLab = nil
    self.dataLab = nil
    self.autoLab = nil
    self.autoDesLab = nil
end

--重写释放资源
function My:CloseCustom()  --DisposeCustom   CloseCustom
    self:Clear()
    if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
    end
end

return My