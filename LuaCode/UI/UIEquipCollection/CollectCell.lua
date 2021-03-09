--[[
中间格子
]]
CollectCell=Super:New{Name="CollectCell"}
local My = CollectCell

function My:Init(go)
    if not self.cellPos then 
        self.cellPos={Vector3.New(-44.8,190.6,0),Vector3.New(106,127.2,0), Vector3.New(173.6,-26.4,0),Vector3.New(109.1,-182,0),
        Vector3.New(-45,-247,0),Vector3.New(-199.9,-180.2,0),Vector3.New(-263.6,-26.4,0),Vector3.New(-200,131,0),Vector3.New(-105,18.2,0),Vector3.New(2,-75,0)}
    end
    if not self.list then self.list={} end
    if not self.effList then self.effList={} end
    self.go=go
    local trans = go.transform
    local TF = TransTool.FindChild
    for i=1,10 do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(trans,0.85,nil,nil,nil,self.cellPos[i])
        cell.trans.name=tostring(i)
        self.list[i]=cell
    end
    for i=1,10 do
        local eff = TF(trans,"eff/UI_qq"..i)
        self.effList[i]=eff
    end
    UITool.SetLsnrClick(trans,"Tip",self.Name,self.ShowTip,self)
end

function My:UpData(id)
    self:CleanData()
    local data = EquipCollData[id]
    local idList = data.idList
    local rank,star,qua=data.rank,data.star,data.qua
    for i,v in ipairs(idList) do
        local wear = EquipMgr.hasEquipDic[tostring(i)]
        local cell = self.list[i]
        local eff = self.effList[i]
        local info = EquipCollectionMgr.infoDic[id]
        local hasActive ,iscan= true ,true
        local maxActive = self:IsMaxNum(info,data)
        if maxActive==false then 
            hasActive=EquipCollectionMgr.IsHasActive(info,i)
            if hasActive==false then
                iscan=EquipCollectionMgr.IsCanActive(wear,rank,star,qua)
            end
        end
        local cellGo =cell.trans.gameObject
        if iscan==false then 
            UITool.SetGray(cellGo,true)
            UITool.SetGray(cell.Icon.gameObject,true)
            cell:UpData(v,nil,false)
        else 
            UITool.SetNormal(cellGo) 
            UITool.SetNormal(cell.Icon.gameObject) 
            cell:UpData(v)
        end
        eff:SetActive(hasActive==true)
    end
end

function My:IsMaxNum(info,data)
    if not info or not info.suit_num then return false end
    local suit_num = info.suit_num
    local is_active = info.is_active or false
    local numList = data.numList
    local maxNum = numList[#numList]
    return suit_num==maxNum and is_active==true
end

function My:EffActive(id)
    local info = EquipCollectionMgr.infoDic[id]
    if not info then return end
    local ids = info.ids
    if not ids then return end
    local data = EquipCollData[id]
    local maxActive = self:IsMaxNum(info,data)
    if maxActive==true then 
        for i,v in ipairs(self.effList) do
            v:SetActive(true)
        end
    else
        for i,v in ipairs(ids) do
            self.effList[v]:SetActive(true)
        end
    end
end

function My:ShowTip()
    local temp=InvestDesCfg["20"]
    if not temp then iTrace.eError("xiaoyu","投资文本为空 id: 20")return end
    UIComTips:Show(temp.des, Vector3(-192.1,-62.3,0),nil,nil,5,400,UIWidget.Pivot.TopLeft);
end

function My:CleanData()
    for i,v in ipairs(self.effList) do
        v:SetActive(false)
    end
end

function My:Dispose()
    for i,v in ipairs(self.list) do
        v.iscan=nil
        v:DestroyGo()
    end
    ListTool.Clear(self.effList)
    ListTool.ClearToPool(self.list)
end