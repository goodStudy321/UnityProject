--region UICell.lua
--Cell基类 只有Icon
--此文件由[HS]创建生成

UICell = baseclass()

--构造函数
function UICell:Ctor(go)
	self.Name = "UICell"
	self.gameObject = go
	self.trans = self.gameObject.transform
	self.gameObject.name = string.gsub(self.gameObject.name,"%(Clone%)","")
	self.gameObject:SetActive(true)
	
	--self.BaseClass.Init(self)
end

--初始化控件
function UICell:Init()
	self.Icon = ComTool.Get(UITexture, self.trans, "Icon", self.Name, false)
	self.IconName = nil
end

--更新Icon
function UICell:UpdateIcon(path)
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

function UICell:SetIcon(tex)
	if self.Icon then
		self.Icon.mainTexture = tex
	end
end

function UICell:UnloadIcon()
	if not StrTool.IsNullOrEmpty(self.IconName) then
		AssetMgr:Unload(self.IconName, ".png", false)
	end
	self.IconName = nil
end

--清楚数据
function UICell:Clean()
	self:UnloadIcon()
	if self.Icon then 
		self.Icon.mainTexture = nil 
	end
	if self.gameObject then 
		self.gameObject:SetActive(false)
		self.gameObject:SetActive(true)
	end
end

function UICell:SetActive(value)
	if not value then value = false end
	if self.gameObject then self.gameObject:SetActive(value) end
end

--释放或销毁
function UICell:Dispose(isDestory)
	if isDestory then
		self.gameObject.transform.parent = nil
		GameObject.Destroy(self.gameObject)
	end
	self.Icon = nil
	self.gameObject = nil
	self.trans = nil
	--self.Name = nil
end
--endregion
