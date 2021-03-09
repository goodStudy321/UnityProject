--region UIMyTeamPlayer.lua
--
--此文件由[HS]创建生成

UIMyTeamPlayer = baseclass(UICellTeamBase)
local tMgr = TeamMgr
local uMgr = UserMgr

--构造函数
function UIMyTeamPlayer:Ctor(go)
	self.Name = "UIMyTeamPlayer"
	--self.BaseClass.Init(self)
end

--初始化控件
function UIMyTeamPlayer:Init()
	self:Super("Init")
	local trans = self.trans
	local name = self.Name
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.AddBtn = C(UIButton, trans, "Add", name, false)
	self.InfoRoot = T(trans, "Info")
	self.Name = C(UILabel, trans, "Info/Panel/Name", name, false)
	self.Lv = C(UILabel, trans, "Info/Panel/Lv", name, false)
	self.GLv = C(UILabel, trans, "Info/Panel/GLv", name, false)
	self.CaptainIcon = T(trans, "Info/CaptainIcon")
	self.Select = T(trans, "Info/Select")
	self.ModRoot = T(trans, "Info/Root")
	self.StateLab = C(UILabel, trans, "Info/Panel/Name/StateLab", name, false)
	
	self.ModTool = RoleSkin:New()
	UITool.SetLsnrSelf(self.AddBtn, self.OnClick, self)
end

function UIMyTeamPlayer:UpdateData(data)
	self:Clean()
	self.Data = data
	local info = tMgr.TeamInfo
	local value = info and data and info.CaptId and data.ID == info.CaptId
	local isCapt = info and info.CaptId and tostring(info.CaptId) == User.MapData.UIDStr
	if self.Menu then self.Menu.IsActive = not value and isCapt end
	self:UpdateStatus(true)
	self:UpdateBtn(info and info.TeamId ~= nil and data == nil)
	self:UpdateCaptainIcon(value)
	if data then
		self:UpdateName(data.Name)
		self:UpdateLv(data.Lv)
		self:UpdateOnLineState(data)
		self:UpdateMod(data)
		self.Items2 = {"提升队长","移出队伍"}
		self:UpdateMenuItems(data)
	end
end

function UIMyTeamPlayer:UpdateOnLineState(data)
	local strLab = ""
	local colorLab = nil
	local isOnline = data.IsOnline
	local mapId = tostring(data.MapId)
	local sceneData = SceneTemp[mapId]
	local sceneType = sceneData.maptype
	if mapId ~= nil and sceneType == 2 then
		strLab = "副本中"
		colorLab = "[F21919FF]"
	elseif isOnline == true and sceneType ~= 2 then
		strLab = "在线"
		colorLab = "[00FF00FF]"
	elseif isOnline == false then
		strLab = "离线"
		colorLab = "[F4DDBDFF]"
	end
	strLab = string.format("%s%s%s",colorLab,strLab,"[-]")
	self.StateLab.text = strLab
end

function UIMyTeamPlayer:UpdateStatus(isShow)
	if self.InfoRoot then
		self.InfoRoot:SetActive(isShow)
	end
end

function UIMyTeamPlayer:UpdateBtn(value)
	if self.AddBtn then
		self.AddBtn.isEnabled = value
	end
end

function UIMyTeamPlayer:UpdateName(name)
	if self.Name then self.Name.text = name end
end

function UIMyTeamPlayer:UpdateLv(lv)
	if lv == "" then
		self.Lv.text = lv
		return 
	end
	local IsGod = uMgr:IsGod(lv)
	if self.Lv  then self.Lv.text = uMgr:GetToLv(lv) end 
	if self.GLv  then self.GLv.text = uMgr:GetToLv(lv) end 
	self.Lv.gameObject:SetActive(not IsGod)
	self.GLv.gameObject:SetActive(IsGod)
end

function UIMyTeamPlayer:UpdateCaptainIcon(value)
	if self.CaptainIcon then self.CaptainIcon:SetActive(value) end
end

function UIMyTeamPlayer:UpdateMod(data)
	if not data then return end
	local id = (data.Career * 10 + data.Sex) * 1000 + data.Lv

	local roleSkins = data.SkinList
	local skinLen = #roleSkins
	-- if skinLen == 0 then
	-- 	return
	-- end
	local skinTab = {}
	local skinType = nil
	for i = 1,skinLen do
		skinType = self.ModTool:GetPandentType(roleSkins[i])
		if skinType ~= PendantType.Wing then
			skinTab[i] = roleSkins[i]
		end
	end
	self.ModTool.eLoadModelCB:Add(self.LoadModCb, self)
	self.ModTool:Create(self.ModRoot,id,skinTab,data.Sex)
	-- local key = tostring(id)
	-- local att = RoleAtt[key]
	-- if not att then return end
	-- local modId = att.modelId
	-- if self.Model and self.Model.name == att.modelId  then 
	-- 	return
	-- end
	-- local temp = RoleBaseTemp[modId]
	-- if temp then
	-- 	if self.ModTool then
	-- 		self.ModTool.eLoadModelCB:Add(self.LoadModCb, self)
	-- 		self.ModTool:CreateSelfNoWing(self.ModRoot.transform)
	-- 	end
	-- end
end

function UIMyTeamPlayer:LoadModCb(go,modelID)
	self.Model = go
	self.ModelName = go.name
	-- self.Model.name = tostring(modelID)
	--self.Model.transform.parent = self.ModRoot.transform
	self.Model.transform.localPosition = Vector3.zero
	self.Model.transform.localEulerAngles = Vector3.zero
	self.Model.transform.localScale = Vector3.one
	LayerTool.Set(self.Model.transform, 19)
end

function UIMyTeamPlayer:OnClick(go)
	-- tMgr:InvitePutInTeam(self.Index)
	UIMyTeam.InvitePanel.GO:SetActive(true)
	UIMyTeam.InvitePanel:FriendBtn()
end

function UIMyTeamPlayer:ClickMenuTipAction(name, tt, str, index)
	if not tt or tt ~= MenuType.Team then return end
	local data = self.Data
	if not data then return end
	if not self.trans or self.trans.name ~= name then
		return
	end
	tMgr:ClickMenuTip(str, data.ID)
end

function UIMyTeamPlayer:IsSelect(value)
	if self.Select then 
		self.Select:SetActive(value)
	end
end

--清除数据
function UIMyTeamPlayer:Clean()
	self:Super("Clean")
	if self.Menu then self.Menu.IsActive = false end
	self.Data = nil
   	self:UpdateStatus(false)
	self:IsSelect(false)
	self:UpdateName("")
	self:UpdateLv("")
	self.StateLab.text = ""
	self:UpdateCaptainIcon(false)
	self:UpdateBtn(false)
	self.Lv.gameObject:SetActive(true)
	self.GLv.gameObject:SetActive(false)
	if self.ModTool then
		self.ModTool:Clear()
	end
	if self.Model and not StrTool.IsNullOrEmpty(self.ModName) then
		AssetMgr:Unload(self.ModelName, ".prefab", false)
	end
	self.ModelName = nil
	self.Model = nil
end

--释放或销毁
function UIMyTeamPlayer:Dispose(isDestory)
	self:Super("Dispose", isDestory)
	self:Clean()
	if self.ModTool then
		self.ModTool:Dispose()
	end
	self.ModTool = nil
	self.Name = nil
	self.Lv = nil
	self.GLv = nil
	self.StateLab = nil
	self.Career = nil
	self.AddBtn = nil
	self.CaptainIcon = nil
	if isDestory then
		self.gameObject.transform.parent = nil
		GameObject.Destroy(self.gameObject)
	end
end
--endregion
