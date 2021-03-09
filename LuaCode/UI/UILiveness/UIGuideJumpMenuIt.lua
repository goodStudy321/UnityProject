--[[
 	authors 	:Liu
 	date    	:2019-4-13 19:02:00
 	descrition 	:引导跳转项
--]]

UIGuideJumpMenuIt = Super:New{Name="UIGuideJumpMenuIt"}

local My = UIGuideJumpMenuIt

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local SetB = UITool.SetBtnClick
	local FindC = TransTool.FindChild

	self.starList = {}
	self.go = root.gameObject

	self.icon = CG(UISprite, root, "iconBg/icon")
	self.name = CG(UILabel, root, "title")
	self.des = CG(UILabel, root, "des")
	self.item = FindC(root, "Grid/star", des)

	SetB(root, "btn", des, self.OnBtn, self)

	self:InitStar()
end

--更新数据
function My:UpData(cfg)
	self.cfg = cfg
	self.icon.spriteName = cfg.icon
	self.name.text = cfg.name
	self.des.text = cfg.des
	self:UpStar(cfg)
end

--点击前往按钮
function My:OnBtn()
	JumpMgr:Clear()
	local id = self.cfg.id
	local O = UIMgr.Open
	if id == 104 then--道庭仓库 
		if CustomInfo:IsJoinFamily() then
			UIMgr.Open(UIFamilyDepotWnd.Name)
		end
	elseif id == 202 then--日常任务
		if LuaTool.Length(MissionMgr.TurnList) > 0 then
			self:MissionTrigger(MissionType.Turn)
		else
			UITip.Log("系统未开启")
		end
	elseif id == 205 then--野外挂机
		LivenessMgr:AutoHangup()
	elseif id == 301 then--月卡投资
		VIPMgr.OpenVIP(2)
	elseif id == 302 then--巅峰投资
		if LvInvestMgr:IsOpen() then
			VIPMgr.OpenVIP(8)
		else
			local lv = GlobalTemp["31"].Value3
			local str1 = UIMisc.GetLv(lv)
			local str2 = string.format("%s级开启", str1)
			UITip.Log(str2)
		end
	elseif id == 303 then--每日签到
		if SignMgr.isOpen or LivenessInfo:IsOpen(1002) then
			UILvAward:OpenTab(2)
		else
			UITip.Log("系统未开启")
		end
	elseif id == 304 then--成就奖励
		if SuccessInfo.isOpen then
			O(UISuccess.Name)
		else
			UITip.Log("系统未开启")
		end
	elseif id == 105 then--装备合成
		UICompound:SwitchTg(3)
	else
		UITabMgr.Open(self.cfg.jumpInfo)
	end
	UIGuideJump:Close()
end

--任务触发
function My:MissionTrigger(type)
    Hangup:SetAutoHangup(true);
    MissionMgr:AutoExecuteActionOfType(type)
end

--更新星级
function My:UpStar(cfg)
	local count = cfg.star
	for i,v in ipairs(self.starList) do
		v:SetActive(false)
	end
	for i,v in ipairs(self.starList) do
		v:SetActive(count >= i)
	end
end

--初始化星级
function My:InitStar()
	local Add = TransTool.AddChild
	local FindC = TransTool.FindChild
	local parent = self.item.transform.parent
	for i=1, 5 do
		local item = Instantiate(self.item)
		local tran = item.transform
		Add(parent, tran)
		local star = FindC(tran, "spr", self.Name)
		table.insert(self.starList, star)
	end
	self.item:SetActive(false)
end

--更新名字
function My:UpName(num)
	self.go.name = num + 1000
end

--更新显示
function My:UpShow(state)
	self.go:SetActive(state)
end

--清理缓存
function My:Clear()
    
end

--释放资源
function My:Dispose()
    
end

return My