--[[
 	authors 	:Liu
 	date    	:2019-6-12 11:18:00
 	descrition 	:道庭Boss项排行榜
--]]

UIFBossTogRank = Super:New{Name="UIFBossTogRank"}

local My = UIFBossTogRank

require("UI/UIFamilyActiv/UIFBossTogRankIt")

function My:Init(root, type)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.go = root.gameObject
    self.type = type
    self.itList = {}
    self.familyName = nil

    local str = "Scroll View/Grid"
    self.grid = CG(UIGrid, root, str)
    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
    self.item = FindC(root, str.."/item", des)
    self.item:SetActive(false)

    SetB(root, "close", des, self.Close, self)

    self:InitFamilyName()
end

--更新数据
function My:UpData(type)
    local data = FamilyBossInfo.data
    local rank = (type==1) and data.rank1 or data.rank2
    local joinCount = (type==1) and data.joinCount1 or data.joinCount2
    self.lab1.text = "我的道庭排名：未上榜"
    self.lab2.text = string.format("[F4DDBDFF]参与人数：[00FF00FF]%s人", joinCount)
    self:UpItem(rank)
end

--更新排行项
function My:UpItem(rank)
    local Add = TransTool.AddChild
    local list = self.itList
    local gridTran = self.grid.transform
    local num = #rank - #list
    table.sort(rank, function(a,b) return a.rank < b.rank end)

    self:HideItem()
    if num > 0 then
        for i=1, num do
            local go = Instantiate(self.item)
            local tran = go.transform
            go:SetActive(true)
            Add(gridTran, tran)
            local it = ObjPool.Get(UIFBossTogRankIt)
            it:Init(tran)
            table.insert(self.itList, it)
        end
    end
    self:RefreshItem(rank, list)
    self.grid:Reposition()
end

--刷新排行项
function My:RefreshItem(rank, list)
    for i,v in ipairs(rank) do
        local isShow = (i%2) == 0
        list[i]:UpShow(true)
        list[i]:UpData(v.rank, v.name, v.joinCount, v.hurtNum, isShow)
        self:UpFamilyRank(v.name, v.rank)
    end
end

--更新自身道庭排行文本
function My:UpFamilyRank(name, rank)
    if self.familyName and self.familyName == name then
        self.lab1.text = string.format("我的道庭排名：%s", rank)
    end
end

--初始化自身道庭名称
function My:InitFamilyName()
    local fD = FamilyMgr:GetFamilyData()
    self.familyName = fD.Name
end

--隐藏排行项
function My:HideItem()
    for i,v in ipairs(self.itList) do
        v:UpShow(false)
    end
end

--打开
function My:Open(type)
    self.go:SetActive(true)
    self:UpData(type)
end

--关闭
function My:Close()
    self.go:SetActive(false)
end

--清理缓存
function My:Clear()
    self.familyName = nil
end

--释放资源
function My:Dispose()
    self:Clear()
    ListTool.ClearToPool(self.itList)
end

return My