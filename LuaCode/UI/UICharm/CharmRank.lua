--[[
魅力排行
]]
require("UI/UICharm/CharmRankCell")
require("UI/UICharm/FirstCharmRank")

CharmRank=Super:New{Name="CharmRank"}
local My = CharmRank

function My:Init( trans )
    if not self.realIndexDic then self.realIndexDic={} end
    if not self.cellList then self.cellList={} end
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local U = UITool.SetBtnClick
    self.Panel=CG(UIPanel,trans,"Panel",self.Name,false)
    self.scrollView=CG(UIScrollView,trans,"Panel",self.Name,false)
    self.UIContent=CG(UIWrapContent,trans,"Panel/content",self.Name,false)
    self.UIContent.onInitializeItem=function(go,index,realIndex) self:OnUpdateItem(go,index,realIndex) end
    self.pre=TF(self.UIContent.transform,"C")
    
    self.C=TF(trans,"Panel/content/C")
    
    self.firstCell=ObjPool.Get(FirstCharmRank)
    self.firstCell:Init(TF(trans,"first"))
end

function My:UpData()
    self.scrollView:ResetPosition()
    self.Panel.clipOffset=Vector3.zero
    self.Panel.transform.localPosition=Vector3.New(1,-81,0)

    local list =  CharmMgr.ranks
    local tp = CharmMgr.tp
    local count = #list-1
    local min = 4
    if count>min then min=count end
    self.UIContent.minIndex=-min+1
    self.UIContent.maxIndex=0
    
    for i=0,3 do
        local cell=self.cellList[tostring(i)]
        if not cell then
            local go = GameObject.Instantiate(self.C)
            go.name="C"..i
            go:SetActive(true)
            go.transform.parent=self.UIContent.transform
            go.transform.localScale=Vector3.one
            local pos = Vector3.New(0,-104*i,0)
            go.transform.localPosition=pos
            cell= ObjPool.Get(CharmRankCell)
            cell:Init(go)
            self.cellList[tostring(i)]=cell
        end
        local data = list[i+1+1]
        cell:Open()
        if data then 
            cell:UpData(data)
        else
            cell:UpData(i+2)
        end
    end
    

    if #list==0 then 
        self.firstCell:UpData(1)
    else
        local fData = list[1]
        self.firstCell:UpData(fData)
    end 
    self.firstCell:ShowModel(tp)
    self.UIContent:SortAlphabetically()
end


function My:OnUpdateItem(go,index,realIndex)
    local rIndex = realIndex<0 and realIndex*-1 or realIndex
    local cell=self.cellList[tostring(index)]
    if not cell then return end
    local data = CharmMgr.ranks[rIndex+1+1]
    if data then 
        cell:UpData(data)
    else
        cell:UpData(index+2)
    end
end

function My:Dispose( ... )
    TableTool.ClearDicToPool(self.cellList)

end