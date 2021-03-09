--region UICellButton.lua
--Cell 系统ItemCell
--此文件由[HS]创建生成

UICellButton = Super:New{Name="UICellButton"}
local M = UICellButton

--初始化控件
function M:Init(go)
	self.Go = go
	go:SetActive(true)
	local C = ComTool.Get
	local T = TransTool.FindChild
	local F = TransTool.Find
	local trans = go.transform
	local name = self.Name
	self.Cell = ObjPool.Get(UIItemCell)
	self.Cell:InitLoadPool(F(trans,"CellRoot"), 0.75)
	self.Btn1 = T(trans, "Button1")
	self.Btn2 = T(trans, "Button2")
	self.btnBg1 = T(self.Btn1.transform, "Background")
	self.NameL = C(UILabel, trans, "Label", name, false)
	self.Des = C(UILabel, trans, "Des", name, false)
	--self.Cost = C(UILabel, trans, "Cost", name, false)
	UITool.SetLsnrSelf(self.Btn1, self.ClickBtn1, self)
	UITool.SetLsnrSelf(self.Btn2, self.ClickBtn2, self)
	
end

function M:ClickBtn1(go)
	if not self.Item then
		iTrace.eError("hs", string.format("未从道具表找到指定id:%s",id)) 
		return 
	end
	local id = self.Item.id
	local num = PropMgr.TypeIdByNum(id)
	local uid = PropMgr.TypeIdById(id)
	if num == 0 then
		UITip.Log(string.format("您没有%s,无法使用", self.Item.name))
		return
	end
	if uid ==0 then return end
	local buffId = User:GetBuffIdBySrID(204)
	if buffId ~=0 and buffId ~= self.Item.uFxArg[1] then
		MsgBox.ShowYesNo(string.format("已有经验药效果，是否使用%s替换？（替换后经验加成时间将重新计算）", self.Item.name),self.YesCb,self,"确定")
	else
		PropMgr.ReqUse(uid,1)
	end
end

function M:YesCb()
	local uid = PropMgr.TypeIdById(self.Item.id)
	PropMgr.ReqUse(uid,1)
end

function M:ClickBtn2(go)
	local item  = self.Item
	if not item then return end
	local id = item.id
	if not id  then return end
	StoreMgr.TypeIdBuy(id, 1)
end

function M:UpdateItem(item)
	if not item then
		 return 
	end
	self.Item = item
	local cell = self.Cell
	if cell then
		cell:UpData(item)
	end
	self:UpdateName(item.name)
	self:UpdateDes(item.uFxArg[1])
	self:UpdateItemList()
end

function M:UpdateName(value)
	if self.NameL then
		self.NameL.text = value
	end
end

function M:UpdateDes(value)
	local des = ""
	if not value then
		value = 0
	 end
	local buff = BuffTemp[tostring(value)]
	if buff then
		value = buff.valueList[1].v
	end
	if self.Des then
		self.Des.text = string.format("[998868]经验 [00FF00FF]+%s%%[-][-]", value*0.01)
	end
end

function M:UpdateItemList()
	if not self.Item then return end
	local id = self.Item.id
	local qp = self.Item.quickprice
	local num = 0

	local num = PropMgr.TypeIdByNum(id)

	if id == 31000 then
		if self.Btn1 then
			self.Btn1:SetActive(num > 0)
		end
		if self.Btn2 then
			self.Btn2:SetActive(num <= 0)
		end
	else
		self.Btn1:SetActive(true)
		self.Btn2:SetActive(false)
		if num > 0 then
			UITool.SetNormal(self.btnBg1)
		else
			UITool.SetGray(self.btnBg1)
		end
	end
	
	if self.Cell then
		self.Cell:UpLab(num)
	end
end



--释放或销毁
function M:Dispose()
	self.Cell:DestroyGo()
	ObjPool.Add(self.Cell)
	self.Cell = nil
	self.Item = nil
	TableTool.ClearUserData(self)
end
--endregion
