--region UICellSmallTeamPlayer.lua
--Cell 
--此文件由[HS]创建生成

UICellSmallTeamPlayer = baseclass(UICellTeamBase)
local M = UICellSmallTeamPlayer

M.Items1 = {"我的队伍","离开队伍"}
M.Items2 = {"提升队长","移出队伍","离开队伍"}

local tMgr = TeamMgr
local uMgr = UserMgr

--构造函数
function M:Ctor(go)
	self.Name = "UICellSmallTeamPlayer"
end

--初始化控件
function M:Init()
	-- self:Super("Init")
	local name = self.Name
	local trans = self.trans
	local C = ComTool.Get
	local T = TransTool.FindChild
	local TF = TransTool.Find
	self.Icon = C(UITexture, trans, "Icon", name, false)
	self.IconObj = TF(trans,"Icon",name)
	self.Label = C(UILabel, trans, "Label", name, false)
	self.Cap = TF(trans, "Cap",name)
	--self.Career = C(UILabel, trans, "Career", name, false)
	self.Lv = C(UILabel, trans, "Lv", name, false)
	self.GLv = C(UILabel,trans,"GLv",name,false)
	if self.Menu then self.Menu.IsActive = true end
end

function M:UpdateData(data)
	local value = false
	if self.Data and self.Data.ID == data.ID then
		value = true
	end
	self.Data = data
	if not self.Data then self:Clean() return end
	if value == false then self:UpdateIcon(self.Data.Career) end
	self:UpdateLabel(self.Data.Name)
	--self:UpdateCareer(self.Data.Career)
	self:UpdateCap(self.Data.ID)
	self:UpdateLv(self.Data.Lv)
	self:UpdateLabel(self.Data.Name)
	self:UpdateMenuItems(data)
end

function M:RestIcon()
	if not self.Data then return end
	self:UpdateIcon(self.Data.Career)
end

function M:UpdateIcon(value)
	local path = string.format( "tx_0%s.png", value)
	if StrTool.IsNullOrEmpty(path) then return end
	self:UnloadIcon()
	self.IconName = path
	AssetMgr:Load(path,ObjHandler(self.SetIcon, self))
end

function M:SetIcon(tex)
	if self.Icon then
		self.Icon.mainTexture = nil
		if LuaTool.IsNull(self.IconObj) == false then
			self.IconObj.gameObject:SetActive(false)
			self.IconObj.gameObject:SetActive(true)
		end
		self.Icon.mainTexture = tex
	end
end

--更新Label
function M:UpdateLabel(value)
	if self.Label then
		if value ~= 0 then
			self.Label.text = value
		else
			self.Label.text = ""
		end
	end
end

function M:UpdateCap(id)
	if LuaTool.IsNull(self.Cap) then return end
	if self.Cap then
		self.Cap.gameObject:SetActive(tostring(TeamMgr.TeamInfo.CaptId) == id)
	end
end

--更新career
function M:UpdateCareer(career)
	if self.Career then
		self.Career.text = UserMgr:GetCareerName(career)
	end
end

--更新lv
function M:UpdateLv(Lv)
	local IsGod = uMgr:IsGod(Lv)
	self.Lv.text = uMgr:GetToLv(Lv)
	self.GLv.text = uMgr:GetToLv(Lv)
	self.Lv.gameObject:SetActive(not IsGod)
	self.GLv.gameObject:SetActive(IsGod)
end

function M:ClickMenuTipAction(name, tt, str, index)
	if not tt or tt ~= MenuType.Team then return end
	local trans = self.trans
	if LuaTool.IsNull(trans) or self.trans.name ~= name then
		return
	end
	tMgr:ClickMenuTip(str, self.Data.ID)
end

--清楚数据
function M:Clean()
	self:Super("Clean")
	--if self.Career then self.Career.text = "" end
	if self.Lv then self.Lv.text = "" end
	if self.GLv then 
		self.GLv.text = ""
		self.GLv.gameObject:SetActive(false)
	 end
end

--释放或销毁
function M:Dispose(isDestory)
	self.Data = nil
	self.OnClickMenuTipAction = nil
	--self.Career = nil
	self.Lv = nil
	self.GLv = nil
	self:Super("Dispose", isDestory)
	--LuaTool.TableDestory(self)
end
--endregion
