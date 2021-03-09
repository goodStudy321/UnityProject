--region UICellTeamSelect.lua
--Cell 选择副本
--此文件由[HS]创建生成

UICellTeamSelect = baseclass()
local tMgr = TeamMgr
local uMgr = UserMgr

--构造函数
function UICellTeamSelect:Ctor(go)
	self.Name = "UICellTeamSelect"
	self.gameObject = go
	self.trans = self.gameObject.transform
	self.gameObject:SetActive(true)

end

--初始化控件
function UICellTeamSelect:Init()
	local C = ComTool.Get
	local T = TransTool.FindChild
	local trans = self.trans
	local name = self.Name
	self.root = trans
	self.CopyName = C(UILabel, trans, "CopyName", name, false)
	self.Lv = C(UILabel, trans, "Lv", name, false)
	self.Btn = C(UIButton, trans, "Button", name, false)
	self.BtnLabel = C(UILabel, trans, "Button/Label", name, false)
	self.BG = C(UITexture, trans, "BG", name, false)

	self.Icons = {}
	for i=1,3 do
		local temp ={}
		local path = string.format("Icon%s",i)
		local icon = C(UITexture, trans, path, name, false)
		local labPath = string.format("%s/%s",path,"lvLab")
		local GlabPath = string.format("%s/%s",path,"GLv")
		local lvLab = C(UILabel, trans, labPath, name, false)
		local GlvLab = C(UILabel, trans, GlabPath, name, false)
		temp.icon = icon
		temp.lvLab = lvLab
		temp.GlvLab = GlvLab
		table.insert(self.Icons, temp)
	end
	self.IconNames = {}
	local E = UITool.SetLsnrSelf
	if self.Btn then	
		E(self.Btn, self.OnClickBtn, self)
	end
end

--玩家数据
function UICellTeamSelect:UpdateData(data)
	self.Data = data
	if not self.Data then return end
	self:Clean()
	self:UpdateCopyName(self.Data.ID)
	self:UpdateLv()
	self:UpdateBtn()
	self:UpdateIcons()
end

function UICellTeamSelect:UpdateCopyName(copyId)
	local data = self.Data
	if not data then return end
	local list = data.Player
	local capId = data.CaptainId
	if not list then return end
	local len = #list
	for i=1,len do
		local roleid = list[i].ID
		local roleName = list[i].Name
		if capId == roleid and self.CopyName then
			self.CopyName.text = roleName
		end
	end


	-- local copyId = UITeam.selectCopyId
	-- if copyId == nil then
	-- 	return
	-- end
	-- local temp = CopyTemp[tostring(copyId)]
	-- if not temp then return end
	-- if self.CopyName then self.CopyName.text = temp.name end
end

function UICellTeamSelect:UpdateLv(lv)
	local data = self.Data
	if not data then return end

	local min = data.MinLv
	local max = data.MaxLv
	local isGodLv = uMgr:IsGod(min)
	if isGodLv == true then
		local godLv = min - 370
		min = string.format("化神%s",godLv)
	end
	isGodLv = uMgr:IsGod(max)
	if isGodLv == true then
		local godLv = max - 370
		max = string.format("化神%s",godLv)
	end
	if self.Lv then self.Lv.text = string.format( "【%s-%s】", min, max) end
end

function UICellTeamSelect:UpdateBtn()
	local data = self.Data
	if not data then return end
	local des = "申请加入"
	local value = true
	local info = tMgr.TeamInfo
	if info.TeamId ~= nil and data.TeamId == info.TeamId then
		des = "查看"
		value = false
	end
	if self.Btn then
		self.Btn.gameObject:SetActive(value)
	end
	if self.BtnLabel then
		self.BtnLabel.text = des
	end
end

function UICellTeamSelect:UpdateIcons()
	local data = self.Data
	if not data then return end
	local list = data.Player
	if not list then return end
	local len = #list
	for i=1,len do
		local lv = list[i].Lv
		self.roleLv = lv
		local path =string.format( "tx_0%s.png", list[i].Career)
		local del = ObjPool.Get(DelLoadTex)
		del:Add(i)
		del:SetFunc(self.LoadModCb,self)
		self.IconNames[i] = path
		AssetMgr:Load(path, ObjHandler(del.Execute,del))
	end
end

function UICellTeamSelect:LoadModCb(tex,index)
	if not self.Icons then return end
	if not self.roleLv then return end
	local roleLv = self.roleLv 
	local icon = self.Icons[index].icon
	local lvLab = self.Icons[index].lvLab
	local GlvLab = self.Icons[index].GlvLab
	local isGod = uMgr:IsGod(roleLv)
	if icon and lvLab then
		icon.mainTexture = tex
	end
	lvLab.gameObject:SetActive(not isGod)
	GlvLab.gameObject:SetActive(isGod)
	if isGod == true then
		roleLv = roleLv - 370
		GlvLab.text = roleLv
	else
		lvLab.text = string.format( "LV.%s", roleLv)
	end
end

function UICellTeamSelect:UnloadIcon(index)
	if not StrTool.IsNullOrEmpty(self.IconNames[index]) then
		AssetMgr:Unload(self.IconNames[index], ".png", false)
	end
	self.IconNames[index] = nil
end

function UICellTeamSelect:OnClickBtn(go)
	local info = tMgr.TeamInfo
	if info.TeamId then 
		UITip.Error("已经拥有队伍，不能申请加入其它队伍")
		return
	end
	tMgr:ReqTeamApply(self.Data.TeamId, 0)
end

--清除出数据
function UICellTeamSelect:Clean()
	if self.CopyName then self.CopyName.text = "" end
	if self.Lv then self.Lv.text = "" end
	if self.Btn then self.Btn.gameObject:SetActive(false) end
	if self.BtnLabel then self.BtnLabel.text = "" end
	if self.Icons then
		local len = #self.Icons
		for i=1, len do
			local icon = self.Icons[i].icon
			if icon then
				self:UnloadIcon(i)
			end
		end
	end
end

--释放或销毁
function UICellTeamSelect:Dispose(isDestory)
	if isDestory then
		if self.gameObject ~= nil then
			self.gameObject.transform.parent = nil
			GameObject.Destroy(self.gameObject)
		end
	end
	if self.Icons then
		local len = #self.Icons
		while len > 0 do
			local icon = self.Icons[len].icon
			if icon then
				table.remove(self.Icons, len)
				GameObject.Destroy(icon)
			end
			len = #self.Icons
		end
	end
	self.Data = nil
	self.CopyName = nil
	self.Lv = nil
	self.Btn = nil
	self.BtnLabel = nil
	self.gameObject = nil
	self.trans = nil
	self.Name = nil
end
--endregion
