--region UIHeadView.lua
--Date
--此文件由[HS]创建生成

UIHeadView = {}
local M = UIHeadView

--注册的事件回调函数

function M:New(go)
	local name = "UI主界面头像窗口"
	self.gameObject = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Container = T(trans, "Container")

	self.Action = T(trans, "Container/Action")

	self.Gold = C(UILabel, trans, "Container/Gold", name, false)
	self.BindGold = C(UILabel, trans, "Container/BindGold", name, false)
	self.Icon = C(UITexture, trans, "Container/Icon", name, false)
	self.Name = C(UILabel, trans, "Container/Name", name, false)
	self.Level = C(UILabel, trans, "Container/Level", name, false)
	self.LvSP = T(trans, "Container/Level/Sprite")
	self.HPSlider = C(UISlider, trans, "Container/HPSlider", name, false)
	self.HpRateLab=C(UILabel,self.HPSlider.transform,"HpRateLab",name,false)
	self.BuffBtn = T(trans, "Container/BuffBtn")
	self.Fighting = C(UILabel, trans, "Container/Fighting", name, false)
	self.FightStatus = C(UIButton, trans, "Container/FightStatusList", name, false)
	self.CurLabel = C(UILabel, self.FightStatus.transform, "Label", name, false);
	self.RebirthLv = GlobalTemp["91"]
	self.RoleLv = GlobalTemp["90"]
	local EH = EventHandler
	self.SetFightModeUI = EH(self.SetFightType, self)
	--self:UpdateFightType()
	--self:UpdateData()
	self:AddEvent()
	return M
end

function M:AddEvent() 
	local M = EventMgr.Add;
	M("UpdateFightMode", self.SetFightModeUI);
	FightVal.eChgFv:Add(self.UpdateFightValue, self);
	OpenMgr.eShowSysEff:Add(self.ShowSysEff, self)
	UITool.SetLsnrSelf(self.Icon, self.OnClickHead, self)
	UITool.SetLsnrSelf(self.BuffBtn, self.OnClickBuffBtn, self)
	UITool.SetLsnrSelf(self.FightStatus, self.OnClickFightStatus, self)
end

function M:RemoveEvent()
	local M = EventMgr.Remove;
	M("UpdateFightMode", self.SetFightModeUI);
end

function M:OnClickHead()
	UIRole:SelectOpen(1)
	--UIMgr.Open(UIMoneyTreePanel.Name)
	--ActivityMgr.eOpen(ActivityTemp["115"],true)
end

function M:OnClickBuffBtn()
	UIMainMenu:SetBuffTips()
end

function M:OnClickFightStatus()
	UIMgr.Open(UIFightStatus.Name)
end

function M:UpdateData()
	self:UpdateHead()
	self:UpdateName()
	self:UpdateLevel()
	self:UpdateHP()
	self:UpdateFightValue()
	self:UpdateCurrency()
end

function M:UpdateHead()
	local name = string.format("head%s", User.MapData.Category)
	if 	self.Icon and self.Icon.mainTexture ~= nil and self.texName == name then return end
	local path = string.format( "%s.png", name)
	AssetMgr:Load(path,ObjHandler(self.SetIcon, self))
end

function M:SetIcon(texture)
	if self.Icon then
		self.Icon.mainTexture = texture
		self.texName = texture.name
	end
end

function M:UpdateName()
	self.Name.text = User.MapData.Name
end

function M:UpdateLevel()
	self.Level.text = UserMgr:GetLv(true)
    if self.LvSP then
        local rolelv = self.RoleLv.Value3
        local rlv = self.RebirthLv.Value3
        self.LvSP:SetActive(UserMgr:GetRealLv() > rolelv and RebirthMsg.RbLev >= rlv)
    end
end

function M:UpdateHP()
	self.HPSlider.value = User.MapData.HPRation
	self.HpRateLab.text=User.MapData.HpStr.."/"..User.MapData.MaxHpStr;
end

function M:UpdateFightValue()
	local fighting = tostring(User.MapData.AllFightValue)
	if self.Fighting then
		self.Fighting.text = fighting
	end
end

function M:UpdateCurrency()
	local ra = RoleAssets
	local gold = self.Gold
	local bind = self.BindGold
	if gold then gold.text = math.NumToStrCtr(ra.Gold) end
	if bind then bind.text = math.NumToStrCtr(ra.BindGold) end
end

function M:SetFightType(fightMode)
	if fightMode <= -1 then
		return;
	end
	fightMode = fightMode + 1
	local valueStr = GetFightStatusTitle(fightMode);
	if StrTool.IsNullOrEmpty(valueStr) then
		return;
	end
	self.CurLabel.text = valueStr
end

--系统开启特效
function M:ShowSysEff(data, go)
	if not data then return end
	if LuaTool.IsNull(go) == true then return end
	go.transform.parent = self.Container.transform
	go.transform.localScale=Vector3.one
	local fly = ComTool.Add(go, UIFly)
	if fly then
		local pos = go.transform.localPosition
		local tarPos = self.Icon.transform.localPosition
		fly.anchors1 = Vector3.New(pos.x - 100, pos.y + 100,0)
		fly.anchors2 = Vector3.New(pos.x - 200 ,pos.y + 200,0)
		fly.targetPos = tarPos
		fly.time = 1
		fly.endDelay = 0
	end
	local scale = ComTool.Add(go, TweenScale)
	if scale then
		scale.from = go.transform.localScale
		scale.to = Vector3.New(0.8,0.8,0.8)
		scale.duration = 1
	end
	go:SetActive(true)
end

function M:UpdateAction()
	if self.Action then
		local num = SystemMgr.SystemNum
		self.Action:SetActive(num ~= nil and num > 0)
	end
end

function M:Clear( )
	if self.Action then
		self.Action:SetActive(false)
	end
end

function M:Dispose()
	self:RemoveEvent()
	self:Clear()
	if self.texName then
        AssetMgr:Unload(self.texName, ".png", false)
        self.texName = nil
    end
end
--endregion
