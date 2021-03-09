--[[
 	authors 	:Liu
 	date    	:2018-6-2 11:55:00
 	descrition 	:道庭答题排行榜
--]]

UIFamilyAnswerRank = Super:New{Name = "UIFamilyAnswerRank"}

local My = UIFamilyAnswerRank

local FRankIt = require("UI/UIFamilyAnswer/UIFamilyRankItem")

function My:Init(root)
    local des,str = self.Name,"Grid"
    self.itDic = {}
    self.grid = ComTool.Get(UIGrid, root, str)
    self.gridTran = TransTool.Find(root, str, des)
    self.rnakItem = TransTool.FindChild(root, str.."/rankItem", des)
    self.rnakItem:SetActive(False)
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    FamilyAnswerMgr.eUpRank[func](FamilyAnswerMgr.eUpRank, self.RespUpRank, self)
end

--响应更新排行榜
function My:RespUpRank(allRankDic)
    local ui = UIMgr.Get(UIFamilyAnswer.Name)
    if not ui then return end
    local itDic = self.itDic
    local Add = TransTool.AddChild
    for k,v in pairs(allRankDic) do
        if itDic[v.name] then
            local it = itDic[v.name]
            it.go.name = v.rank + 1000
            it:SetRankItem(v.rank, v.name, v.score)
        else
            local item = Instantiate(self.rnakItem)
            item:SetActive(true)
            item.name = v.rank + 1000
            local tran = item.transform
            Add(self.gridTran, tran)
            local it = ObjPool.Get(FRankIt)
            it:Init(tran)
            it:SetRankItem(v.rank, v.name, v.score)
            itDic[v.name] = it
        end
    end
    self.grid:Reposition()
end

--清理缓存
function My:Clear()
    self.grid = nil
    self.gridTran = nil
    self.rnakItem = nil
end

--释放资源
function My:Dispose()
    self:SetLnsr("Remove")
    TableTool.ClearDicToPool(self.itDic)
end

return My