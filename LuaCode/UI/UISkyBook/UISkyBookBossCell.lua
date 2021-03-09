--region UISkyBossCell.lua
--
--此文件由[HS]创建生成

UISkyBookBossCell = Super:New{Name="UISkyBookBossCell"}
local M = UISkyBookBossCell
--初始化控件
function M:Init(go)
	self.GO = go
	local name = go.name
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.Icon = C(UITexture, trans, "Icon", name, false)
	self.Status = T(trans, "Status")
	self.Temp = nil
	UITool.SetLsnrSelf(go, self.OnClick, self, nil, false)
end

function M:UpdateData(temp, satisfy)
	self.Temp = temp
	self:UpdateIcon(temp.icon)
	if not satisfy then return end
	for i,v in ipairs(satisfy) do
		if temp.id == v then
			self:SetStatus(true)
		end
	end
end

--更新Icon
function M:UpdateIcon(path)
	if self.Icon then
		if StrTool.IsNullOrEmpty(path) then	
			self.Icon.mainTexture = nil
			self.Icon.gameObject:SetActive(false)
			self.Icon.gameObject:SetActive(true)
			return
		end
		self:UnloadIcon()
		self.IconName = path
		AssetMgr:Load(path,ObjHandler(self.SetIcon, self))
	end
end

function M:SetIcon(tex)
	if self.Icon then
		self.Icon.mainTexture = tex
	end
end

function M:UnloadIcon()
	if not StrTool.IsNullOrEmpty(self.IconName) then
		AssetMgr:Unload(self.IconName, ".png", false)
	end
	self.IconName = nil
end

function M:SetStatus(value)
	if self.Status then
		self.Status:SetActive(value)
	end
	if self.Icon then
		local color = Color.New(1,1,1,1)
		if value == true then color = Color.New(0,1,1,1) end
		self.Icon.color = color 
	end
end

function M:OnClick(go)
	if self.Temp then
		local key = tostring(self.Temp.id)
    	local temp = SBCfg[key]
		if temp then
			UIBoss.ChoseBossCell(temp.id)
		end
	end
	UIMgr.Close(UISkyBook.Name)
	UIMgr.Open(UIBoss.Name)
end

--清楚数据
function M:Clean()
	self:UnloadIcon()
	self.Temp = nil
	if self.Icon then 
		self.Icon.mainTexture = nil 
	end
	if self.GO then 
		self.GO:SetActive(false)
		self.GO:SetActive(true)
	end
end

function M:SetActive(value)
	if not value then value = false end
	if self.GO then self.GO:SetActive(value) end
end

--释放或销毁
function M:Dispose()
	self:Clean()
	self.GO.transform.parent = nil
	GameObject.Destroy(self.GO)
	self.Icon = nil
	self.Status = nil
	self.GO = nil
	--self.Name = nil
end
--endregion
