--[[
 	authors 	:Liu
 	date    	:2019-04-17 16:20:00
 	descrition 	:任务条件项
--]]

UIJourneysCondIt = Super:New{Name = "UIJourneysCondIt"}

local My = UIJourneysCondIt

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.cfg = cfg
    self.go = root.gameObject
    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
    self.spr = CG(UISprite, root, "sprBg/spr1")
    self.sprLab = CG(UILabel, root, "sprBg/lab")
    self.btnLab = CG(UILabel, root, "btn/lab")
    self.btn = FindC(root, "btn", des)
    self.complete = FindC(root, "complete", des)

	SetB(root, "btn", des, self.OnBtn, self)
	
    self:InitDesLab()
    self:InitIcon()
end

--初始化icon
function My:InitIcon()
	local cfg = self.cfg
	self.spr.spriteName = cfg.icon
	self.sprLab.text = cfg.iconName
end

--更新条件次数
function My:UpCondCount(count)
	local cfg = self.cfg
	local isMax = (count >= cfg.count)
	local val = (isMax) and cfg.count or count
	self.lab2.text = string.format("%s/%s", val, cfg.count)
	local num = (isMax) and 500000 or 100000
	self:SetBtnState(isMax)
	self:ChangeName(num)
end

--设置按钮状态
function My:SetBtnState(state)
	self.complete:SetActive(state)
	self.btn:SetActive(not state)
end

--初始化名字
function My:ChangeName(num)
	self.go.name = self.cfg.id + num
end

--初始化描述文本
function My:InitDesLab()
	local cfg = self.cfg
	local type = cfg.type
	local str = ""
    if type == 100101 then
        str = string.format(cfg.des, cfg.mana)
    else
        str = string.format(cfg.des, cfg.cond, cfg.mana)
    end
	self.lab1.text = str
end

--点击按钮
function My:OnBtn()
    local cfg = self.cfg
    local type = cfg.type
    local isShowTips = false

    if type == 100101 then--充值
        if not UITabMgr.Pattern2(1002) then VIPMgr.OpenVIP(1) else isShowTips = true end
            
    elseif type == 100108 then--日常任务
        self:MissionTrigger(MissionType.Turn)

    elseif type == 100123 then--结婚
		if MarryInfo:IsOpen() then UIMarry:OpenTab(1) else isShowTips = true end

    elseif type == 100124 then--护送
        if CustomInfo:IsJoinFamily() then
            if FamilyEscortMgr:GetOpenStatus() then
                UIMgr.Open(UIFamilyEscort.Name)
            else
                UITip.Log("活动未开启")
            end
        end
        
    else
        UITabMgr.Open(cfg.jumpInfo)
    end

	if isShowTips then
		UITip.Log("系统未开启")
		return
	end

    JumpMgr:InitJump(UIBenefit.Name,BenefitMgr.Journeys)
end

--任务触发
function My:MissionTrigger(type)
    Hangup:SetAutoHangup(true);
    MissionMgr:AutoExecuteActionOfType(type)
end

--清理缓存
function My:Clear()
    
end

-- 释放资源
function My:Dispose()
    self:Clear()
end

return My