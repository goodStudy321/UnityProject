--[[
通天排行榜
]]
require("UI/UITongtianRank/TongtianCell")
TongtianRank=Super:New{Name="TongtianRank"}
local My = TongtianRank
local Ynum = 8  --最多创建数量
My.lvColor={"[FFA133]","[AD77FF]","[70B0FF]"}

function My:Init(go)
    if not self.realIndexDic then self.realIndexDic={} end
    if not self.cellDic then self.cellDic={} end
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local U = UITool.SetBtnClick
    local trans = go.transform
    self.go=go
    self.UIContent=CG(UIWrapContent,trans,"Panel/UIWrapContent",self.Name,false)
    self.C=TF(trans,"Panel/UIWrapContent/C")
    self.None=TF(trans,"None")
    self.selfItem=ObjPool.Get(TongtianCell)
    self.selfItem:Init(TF(trans,"selfItem"))

    self.afterCell=nil
    self:SetEvent("Add")
end

function My:SetEvent(fn)
    TongtianCell.eClick[fn](TongtianCell.eClick,self.OnClick,self)
end

function My:OnClick(cell)
    if self.afterCell ==cell then self.afterCell:InfoBtnState(false) self.afterCell=nil return end
    if self.afterCell then self.afterCell:InfoBtnState(false) end
    self.afterCell=cell
end

function My:UpData()
    local list = TongtianRankMgr.rankList
    local count = #list
    self.UIContent.transform.localPosition=count==1 and Vector3.New(0,220,0) or Vector3.New(0,160,0)
    if count>0 then 
        local min = count
        self.UIContent.minIndex=-min+1
        self.UIContent.maxIndex=0

        self.None:SetActive(false)
        for i=0,Ynum-1 do
            local go = GameObject.Instantiate(self.C)
            go:SetActive(true)
            go.transform.parent=self.UIContent.transform
            go.transform.localScale=Vector3.one
            local pos = Vector3.New(0,-60*i,0)
            go.transform.localPosition=pos
            local cell = ObjPool.Get(TongtianCell)
            cell:Init(go)
            self.cellDic[tostring(i)]=cell

            local data = TongtianRankMgr.rankList[i+1]
            if data then
                cell:Open()
                cell:UpData(data)
            else
                cell:Close()
            end
        end
    end
    local data = self:FindSelf()
    if self.selfItem then self.selfItem:UpData(data)end
    self.UIContent.onInitializeItem=function(go,index,realIndex) self:OnUpdateItem(go,index,realIndex) end
end

function My:FindSelf()
    local data = nil
    for i,v in ipairs(TongtianRankMgr.rankList) do
        if v.role_id==User.instance.MapData.UIDStr then
            data=v
            break
        end
    end
    return data
end

function My:OnUpdateItem(go,index,realIndex)
    local list = self.realIndexDic
    local rIndex=realIndex<0 and realIndex*-1 or realIndex
    list[tostring(index)]=rIndex
    local cell = self.cellDic[tostring(index)]
    if not cell then return end
    local data = TongtianRankMgr.rankList[rIndex+1]
    if not data then return end
    cell:UpData(data)
end


function My:Open( ... )
    self.go:SetActive(true)
end

function My:Close( ... )
    self.go:SetActive(false)
end

function My:Dispose( ... )
    self:SetEvent("Remove")
    if self.selfItem then ObjPool.Add(self.selfItem) self.selfItem=nil end
    TableTool.ClearDic(self.realIndexDic)
    TableTool.ClearDicToPool(self.cellDic)
end