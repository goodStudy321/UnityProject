--[[
 	authors 	:Liu
 	date    	:2018-5-2 10:27:40
 	descrition 	:排行榜弹窗
--]]

UIRankActivPop = Super:New{Name = "UIRankActivPop"}

local My = UIRankActivPop

require("UI/UIRankActiv/UIRankActivPopIt")

function My:Init(root)
    local des = self.name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild
    local str = "ScrollView/Grid"


    self.grid = CG(UIGrid, root, str)
    self.panel = CG(UIScrollView, root, "ScrollView") --
    self.item = FindC(root, str.."/rankItem", des) --排行榜
    self.go = root.gameObject
    self.itList = {}

    SetB(root, "closeBtn", des, self.OnClose, self)
    
    self:InitRankIt()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    RankActivMgr.eRankInfo[func](RankActivMgr.eRankInfo, self.RespRankInfo, self)
end

--响应排行信息
function My:RespRankInfo()
    local index = UIRankActiv.id
    if index == 0 then return end
    self:HideRankInfo()
    local list = RankActivInfo.rankDataList
    table.sort(list, function(a,b) return a.rank < b.rank end)
    for i,v in ipairs(list) do
        local it = self.itList[i]
        if it then
            it:UpShow(true)
            it:SetRankLab(v.rank, v.val, v.roleName, index)
        end
    end
    self.grid:Reposition()
    -- local type=TimeLimitActivMgr.type
    -- local list = RankActivInfo.rankDataDic[tostring(type)]
    -- if list and #list>1 then 
    --     table.sort(list, function(a,b) return a.rank < b.rank end)
    -- end
    -- if list then 
    --     for i,v in ipairs(list) do
    --         local it = self.itList[i]
    --         if it then
    --             it:UpShow(true)
    --             it:SetRankLab(v.rank, v.val, v.roleName, index)
    --         end
    --     end
    -- end
    -- self.grid:Reposition()
end

--隐藏排行信息
function My:HideRankInfo()
    for i,v in ipairs(self.itList) do
        v:UpShow(false)
    end
    self.grid:Reposition()
    self.panel:ResetPosition()
end

--初始化排行榜项
function My:InitRankIt()
    local Add = TransTool.AddChild
    local parent = self.item.transform.parent
    for i=1, 50 do
        local go = Instantiate(self.item)
        local tran = go.transform
        Add(parent, tran)
        local it = ObjPool.Get(UIRankActivPopIt)
        it:Init(tran)
        table.insert(self.itList, it)
    end
    self.item:SetActive(false)
end

--点击关闭
function My:OnClose()
    self:UpShow(false)
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--清理缓存
function My:Clear()

end

--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
    ListTool.ClearToPool(self.itList)
end

return My