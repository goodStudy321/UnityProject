--region UIDialogItem.lua
--Date
--此文件由[HS]创建生成

UIDialogItem = baseclass()

local M = UIDialogItem

--构造函数
function M:Ctor(go)
	local title = "UIDialogItem"
	self.Go = go
	self.trans = go.transform
end

function M:Init()
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Name = C(UILabel, self.trans, "Name", title, false)
	self.Talk = C(UILabel, self.trans, "Talk", title, false)
	self.Icon = C(UITexture, self.trans, "Icon", title, false)
end

function M:UpdateData(type, name, talk, path)
	self.Name.text = name
	self.Talk.text = talk
	self:UpdateIcon(path)
end

function M:UpdateIcon(path)
	if self.Icon then
		self:UnloadIcon()
		if StrTool.IsNullOrEmpty(path) then	
			self.Icon.mainTexture = nil
			self.Icon.gameObject:SetActive(false)
			self.Icon.gameObject:SetActive(true)
			return
		end
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

function M:SetActive(value)
	if self.Go then
		self.Go:SetActive(value)
	end
end

--清楚数据
function M:Clean()
	self:SetIcon(nil)
	self:SetActive(false)
	self:UnloadIcon()
end

--释放或销毁
function M:Dispose(isDestory)
end
--endregion
