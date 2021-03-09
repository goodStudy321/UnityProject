--region UICellSystemItem.lua
--Cell 系统ItemCell
--此文件由[HS]创建生成

UICellSystemItem = baseclass()

--构造函数
function UICellSystemItem:Ctor(go)
	self.Name = "UICellSystemItem"
	self.gameObject = go
	self.trans = self.gameObject.transform
	self.gameObject.name = string.gsub(self.gameObject.name,"%(Clone%)","")
	self.gameObject:SetActive(true)
end

--初始化控件
function UICellSystemItem:Init()
	self.PlayTween = self.gameObject:GetComponent("UIPlayTween")
	self.Step = ComTool.Get(UILabel, self.trans, "Step", self.Name, false)
	self.Quality = ComTool.Get(UILabel, self.trans, "Quality", self.Name, false)
	self.Label = ComTool.Get(UILabel, self.trans, "Label", self.Name, false)
	self.Tag = ComTool.Get(UISprite, self.trans, "Tag", self.Name, false)
end

function UICellSystemItem:UpdateData(data)
	if data == nil then return end
	self.Data = data
	self.Info = self.Data.Info
	if not self.Info then return end
	self:UpdateLabel(self.Info.name)
	self:UpdateStep(self.Info.step)
end

--更新Label
function UICellSystemItem:UpdateLabel(value)
	if self.Label then self.Label.text = value end
end

function UICellSystemItem:UpdateStep(value)
	if self.Step then self.Step.text = "("..value.."阶)" end
end

function UICellSystemItem:IsSelect(value)
	if self.PlayTween then 
		self.PlayTween.gameObject:SetActive(true)
		self.PlayTween:Play(value) 
	end
end

--清楚数据
function UICellSystemItem:Clean()
	if self.Step then self.Step.text = "" end
	if self.Label then self.Label.text = "" end
	if self.Quality then self.Quality.text = "" end
	if self.Tag then self.Tag.spriteName = "" end
end

--释放或销毁
function UICellSystemItem:Dispose(isDestory)
	if isDestory then
		self.gameObject.transform.parent = nil
		GameObject.Destroy(self.gameObject)
	end
	self.gameObject = nil
	self.trans = nil
	self.Name = nil
	self.Step = nil
	self.Quality = nil
	self.Label = nil
	self.Tag = nil
	self.PlayTween = nil
	self.Data = nil
end
--endregion
