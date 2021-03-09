--region UICellLabel.lua
--Cell 有UILabel的类
--此文件由[HS]创建生成

UICellLabel = baseclass(UICell)

--构造函数
function UICellLabel:Ctor(go)
	self.Name = "UICellLabel"
end

--初始化控件
function UICellLabel:Init()
	self:Super("Init")
	self.Label = ComTool.Get(UILabel, self.trans, "Label", self.Name, false)
end

--更新Label
function UICellLabel:UpdateLabel(value)
	if self.Label then
		if value ~= 0 then
			self.Label.text = value
		else
			self.Label.text = ""
		end
	end
end

--清楚数据
function UICellLabel:Clean()
	self:Super("Clean")
	if self.Label then self.Label.text = "" end
end

--释放或销毁
function UICellLabel:Dispose(isDestory)
	self:Super("Dispose", isDestory)
	self.Label = nil
end
--endregion
