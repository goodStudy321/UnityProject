--[[
 	authors 	:Liu
 	date    	:2018-5-1 14:59:40
 	descrition 	:答题奖励界面
--]]

UIAnswerAward = Super:New{Name = "UIAnswerAward"}

local My = UIAnswerAward

require("UI/UIAnswer/UIAnswerAwardIt")

function My:Init(root)
    local des = self.Name
    local str = "ScrollView/Grid"
    local gridTran = TransTool.Find(root, str, des)
    local aItem = TransTool.FindChild(root, str.."/rankItem", des)
    self.go = root.gameObject
    self.itList = {}
    UITool.SetBtnClick(root, "closeBtn", des, self.OnClose, self)
    self:InitItem(aItem, gridTran)
end

--初始化奖励项
function My:InitItem(aItem, gridTran)
    local Add = TransTool.AddChild
    for i,v in ipairs(AnswerAwardCfg) do
        local item = Instantiate(aItem)
        local tran = item.transform
        Add(gridTran, tran)
        local it = ObjPool.Get(UIAnswerAwardIt)
        it:Init(tran, v)
        table.insert(self.itList, it)
    end
    aItem:SetActive(false)
end

--点击关闭按钮
function My:OnClose()
    self.go:SetActive(false)
end

--清理缓存
function My:Clear()

end

--释放资源
function My:Dispose()
    self:Clear()
    ListTool.ClearToPool(self.itList)
end

return My