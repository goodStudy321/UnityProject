--[[
 	authors 	:Liu
 	date    	:2019-3-19 11:00:00
 	descrition 	:限时活动界面1(排行弹窗)
--]]

UIRankInfoPop = Super:New{Name="UIRankInfoPop"}

local My = UIRankInfoPop

require("UI/UITimeLimitActiv/UIRankInfoPopIt")

function My:Init(root)
    local des = self.name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild
    local str = "ScrollView/Grid"

    self.itList = {}
    self.go = root.gameObject
    
    self.title=CG(UILabel,root,"title")
    self.grid = CG(UIGrid, root, str)
    self.panel = CG(UIScrollView, root, "ScrollView")
    self.item = FindC(root, str.."/rankItem", des)

    SetB(root, "closeBtn", des, self.OnClose, self)

    self:InitRankIt()
    self:UpRankInfo()
end

--初始化排行榜信息
function My:UpRankInfo()
    self:HideRankInfo()
    local info = TimeLimitActivInfo
    local type=TimeLimitActivMgr.type
    local list = info.rankDataDic[tostring(type)]
    if list and #list>1 then
        table.sort(list, function(a,b) return a.rank < b.rank end)
    end
    if list and #list>0 then
        for i,v in ipairs(list) do
            local it = self.itList[i]
            if it then
                it:UpShow(true)
                it:SetRankLab(v.rank, v.val, v.roleName)
            end
        end
    end
    self.grid:Reposition()

    local type=TimeLimitActivMgr.type
    local str=nil
    if type==10012 then
        str="图鉴"
    elseif type==10014 then
        str="翅膀"
    elseif type==10013 then
        str="法宝"
    end
    self.title.text=string.format("%s战力排行",str)
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
        local it = ObjPool.Get(UIRankInfoPopIt)
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
    ListTool.ClearToPool(self.itList)
end

return My