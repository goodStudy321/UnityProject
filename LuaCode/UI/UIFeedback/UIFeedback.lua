-- require("UI/UIFeedback/UIConnPanel")
require("UI/UIFeedback/UIFeedbackItem")
UIFeedback = Super:New{Name = "UIFeedback"}

local M = UIFeedback

local C = ComTool.Get
local T = TransTool.FindChild

function M:Init(trans)
    self.objTrans = trans
    self.obj = self.objTrans.gameObject
    
    self.itemSV = C(UIScrollView,self.objTrans,"SV",tip,false)
    self.table = C(UITable,self.objTrans,"SV/Table")
    self.item = T(self.objTrans,"SV/Table/Item_99")

    UITool.SetLsnrClick(self.objTrans, "connBtn", "", self.ClickToConn, self)

    self.items = {}

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    FeedbackMgr.eONewData[key](FeedbackMgr.eONewData, self.ShowData, self)
    FeedbackMgr.eReSet[key](FeedbackMgr.eReSet, self.ReSet, self)
end


function M:Open()
    self.obj:SetActive(true)
end
function M:Close()
    self.obj:SetActive(false)
end

function M:ClickToConn()
    UIMgr.Open(UIConnPanel.Name)
end

function M:ShowData()
    self.data = FeedbackMgr:GetSelfList()
    local num = #self.data
    if self.data == nil or #self.data <= 0 then
        self:ReNewData(0)
    end
    self:ReNewData(num)

    for i=1,num do
        self.items[i]:InitAndLink(self.data[i],function ()
            self:ClickSelItem(self.data[i].num)
        end)
    end
end

function M:ClickSelItem(index)
    local data = self.data
    for i=1,#data do
        if self.data[i].num == index then
            self.items[i]:SelSign(true)
        else
            self.items[i]:SelSign(false)
        end
    end
end

function M:Clone()
    local cloneObj = GameObject.Instantiate(self.item)
	local parent=self.table.gameObject.transform
	local trans = cloneObj.transform
	local strans = self.item.transform
	TransTool.AddChild(parent,trans)
	trans.localPosition = strans.localPosition
	trans.localRotation = strans.localRotation
	trans.localScale = strans.localScale
	cloneObj:SetActive(true)

	local cell = ObjPool.Get(UIFeedbackItem)
	cell:Init(cloneObj)

	local newName = ""
	if #self.items + 1 >= 100 then
		newName = string.gsub(self.item.name, "99", tostring(#self.items + 1))
	elseif #self.items + 1 >= 10 then
		newName = string.gsub(self.item.name, "99", "0"..tostring(#self.items + 1))
	else
		newName = string.gsub(self.item.name, "99", "00"..tostring(#self.items + 1))
	end
	cloneObj.name = newName

	self.items[#self.items + 1] = cell
	return cell
end

function M:ReNewData(num)
    local len = #self.items
        for i=1,len do
            self.items[i]:Show(false)
        end
    local realNum = num
    if realNum <= len  then
        for i=1,realNum do
            self.items[i]:Show(true)
        end
    else
        for i=1,len do
            self.items[i]:Show(true)
        end
        local needNum = realNum - len
        for i=1,needNum do
            self:Clone()
        end
    end
    self:ReSet()
end

function M:ReSet()
    self.table:Reposition()
end

function M:Dispose()
    self:SetLsnr("Remove")
    TableTool.ClearDic(self.data)
    TableTool.ClearDicToPool(self.items)
    TableTool.ClearUserData(self)
    self.items = nil
end

return M