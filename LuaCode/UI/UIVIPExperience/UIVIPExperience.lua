--[[
 	authors 	:Liu
 	date    	:2018-8-28 14:30:00
 	descrition 	:VIP体验界面
--]]

UIVIPExperience = UIBase:New{Name = "UIVIPExperience"}

local My = UIVIPExperience

function My:InitCustom()
    local root, des = self.root, self.Name
    local FindC, SetB = TransTool.FindChild, UITool.SetBtnClick
    local item = FindC(root, "bg1/Scroll View/Grid/item", des)
    local time = 5
    self.timeLab = ComTool.Get(UILabel, root, "timerLab")
    -- SetB(root, "close", des, self.Close, self)
    SetB(root, "sureBtn", des, self.OnClick, self)
    self:InitLabItem(item, des)
    self:CreateTimer()
    self:UpTimerLab(time)
    self:UpTimer(time)
end

--初始化文本项
function My:InitLabItem(item, des)
    local Add, CG = TransTool.AddChild, ComTool.Get
    local Find = TransTool.Find
    local parent = item.transform.parent
    local cfg = VIPLv[1+1]
    for i=1, 23 do
        local arg = cfg["arg"..i]
        local cfg = VIPText[tostring(i)]
        if cfg then
            local text = cfg.text
            if arg ~= nil then
                if i == 16 or i == 17 or i == 21 or i == 22 then
                    arg = arg / 100
                elseif i == 1 then
                    local cfg1 = TitleCfg[tostring(i)]
                    local temp1 = cfg1.name
                    local temp2 = cfg1.atk*10 + cfg1.hp*0.5 + cfg1.arm*10 + cfg1.def*10
                    local list = {temp1, temp2}
                    for i,v in ipairs(list) do
                        text = string.gsub(text, "#", v, 1)
                    end
                end
                text = string.gsub(text, "#", arg, 1)
                local go = Instantiate(item)
                local tran = go.transform
                local lab = CG(UILabel, tran, "lab")
                Add(parent, tran)
                lab.text = text
            end
        end
    end
    item:SetActive(false)
end

--初始化计时器文本
function My:UpTimerLab(time)
    self.timeLab.text = "("..time.."秒之后自动使用)"
end

--点击立即体验按钮
function My:OnClick()
    self:ReqUseItem()
end

--请求使用VIP体验卡
function My:ReqUseItem()
    local mgr = PropMgr
    local uid = mgr.TypeIdById(210004)
    if uid==nil then self:Close() return end
    mgr.eUse:Add(self.RespUseItem, self)
    mgr.ReqUse(uid, 1)
end

--响应使用VIP体验卡
function My:RespUseItem()
    if VIPMgr.GetVIPLv() > 0 and not VIPMgr.isExpire then UITip.Log("您的VIP使用时间增加30分钟") end
    PropMgr.eUse:Remove(self.RespUseItem, self)
    self:Close()
end

--更新计时器
function My:UpTimer(time)
    if self.timer == nil then iTrace.Error("SJ", "没有发现计时器") return end
    local timer = self.timer
    timer.seconds = time
	timer:Start()
end

--创建计时器
function My:CreateTimer()
	self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
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

--重写UIBase方法，持续显示
function My:ConDisplay()
    do return true end
end

--清理缓存
function My:Clear()
    self.timeLab = nil
end
    
--重写释放资源
function My:DisposeCustom()
    self:Clear()
    if self.timer then
		self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
    end
end

return My