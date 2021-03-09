--region UIPicCollectGroupPro.lua
--Date
--此文件由[HS]创建生成


UIPicCollectGroupPro = Super:New{Name="UIPicCollectGroupPro"}
local M = UIPicCollectGroupPro
local PCMgr = PicCollectMgr

function M:Init(go)
	self.Root = go
	local name = "图鉴套牌属性"
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Title = C(UILabel, trans, "Step", name, false)
	self.Pros = ObjPool.Get(UIPicCollectPros)
	self.Pros:Init(T(trans, "Pros"))
	self.Pros.GroupPro = true
	
	self.ABtn = C(UIButton, trans, "Button", name, false)
	self.ABtnLab = C(UILabel, trans, "Button/Label", name, false)
	self.Action = T(trans, "Button/Action")

	local E = UITool.SetLsnrSelf
	E(self.ABtn, self.OnClickABtn, self)
end

function M:UpdatePic(tkey, gkey, temp)
	self.Temp = temp
	self.Num = PCMgr:GetStepActiveNum(tkey, gkey)
	self:UpdateTitle(self.Num, temp)
	self:UpdatePros(temp)
	self:UpdateActive()
	self:UpdateAction()
end

function M:UpdateTitle(num, temp)
	local limit = temp.stars
	if self.Title then
		self.Title.text = string.format("%s （激活卡片总星数：%s/%s）", temp.title, num , limit)
	end
end

function M:UpdatePros(temp)
	if self.Pros then
		self.Pros:UpdateProTemp(temp)
	end
end

function M:UpdateActive()
	local temp = self.Temp
	local isActive = false
	local isEnabled = false
	if temp then
		isActive = PCMgr:GetGroupActive(temp.id)
		isEnabled = isActive == false and  self.Num >= self.Temp.stars
	end
	local txt = "激活"
	if isActive == true then txt = "已激活" end
	if self.ABtnLab then
		self.ABtnLab.text = txt
	end
	if self.ABtn then
		self.ABtn.Enabled = isEnabled
	end
end

function M:OnClickABtn(go)
	local temp = self.Temp
	if not temp then
		UITip.Error("没有选中需要激活的卡组")
		return
	end
	PCMgr:ReqActiveGroupPic(temp.id)
end

function M:UpdateAction()
	local temp = self.Temp
	if not temp then return end
	local action = self.Action
	if action then
		action:SetActive(PCMgr:GetGroupProToRed(temp.id))
	end
end

function M:Clear()
	self.Temp  = nil
end

function M:Dispose()
	self:Clear()
	if self.Pros then
		self.Pros:Dispose()
		ObjPool.Add(self.Pros)
	end
	local root = self.Root
	if LuaTool.IsNull(root) == false then
		root.transform.parent = nil
		Destroy(root)
	end
end
--endregion
