--region UICellSelect.lua
--Cell 
--此文件由[HS]创建生成

UICellSelect = baseclass(UICellQuality)

--构造函数
function UICellSelect:Ctor(go)
	self.Name = "UICellSelect"
end

--初始化控件
function UICellSelect:Init()
	self:Super("Init")
	self.Select = TransTool.FindChild(self.gameObject.transform, "Select")
end

--更新Quality
function UICellSelect:IsSelect(value)
	if self.Select then self.Select:SetActive(value) end
end

--清楚数据
function UICellSelect:Clean()
	self:Super("Clean")
	self:IsSelect(false)
end

--释放或销毁
function UICellSelect:Dispose(isDestory)
	self.Select = nil
	self:Super("Dispose", isDestory)
end
--endregion
