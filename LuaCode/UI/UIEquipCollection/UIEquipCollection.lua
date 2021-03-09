--[[
装备收集
]]
require("UI/UIEquipCollection/CollectTab")
require("UI/UIEquipCollection/CollectCell")
require("UI/UIEquipCollection/CollectInfo")
UIEquipCollection=UIBase:New{Name="UIEquipCollection"}
local My = UIEquipCollection

function My:InitCustom()
    local TF = TransTool.FindChild

    self.CollectTab=ObjPool.Get(CollectTab)
    self.CollectTab:Init(TF(self.root,"left"))

    self.CollectCell=ObjPool.Get(CollectCell)
    self.CollectCell:Init(TF(self.root,"Center"))

    self.CollectInfo=ObjPool.Get(CollectInfo)
    self.CollectInfo:Init(TF(self.root,"right"))

    self:SetFunc("Add")
    self.clickId=nil
    self:UpData()
end

function My:SetFunc(fn)
    CollectSelect.eClick[fn](CollectSelect.eClick,self.CollectSelectClick,self)
    EquipCollectionMgr.eUpInfo[fn](EquipCollectionMgr.eUpInfo,self.UpInfo,self)
end

function My:UpData()
    self.CollectTab:UpData()
end

function My:CollectSelectClick(id)
    if self.clickId then
        local last = self.CollectTab.dic[self.clickId]
        last:SelectActive(false)
    end
    self.clickId=id
    self.CollectCell:UpData(id)
    self.CollectInfo:UpData(id)
end

function My:UpInfo(id,tp)
    id=tostring(id)
    self.CollectInfo:UpData(id)
    self.CollectCell:EffActive(id)

    --红点
    self.CollectTab:ShowRed()
    self.CollectInfo:ShowRed()
end

function My:IsOpen()
    return OpenMgr:IsOpen(20)
end

function My:OpenUI()
    local isopen = OpenMgr:IsOpen(20)
    if isopen==false then UITip.Log("系统暂未开启！")return end
    UIMgr.Open(UIEquipCollection.Name)
end

function My:DisposeCustom()
   if self.CollectTab then ObjPool.Add(self.CollectTab) self.CollectTab=nil end
   if self.CollectCell then ObjPool.Add(self.CollectCell) self.CollectCell=nil end
   if self.CollectInfo then ObjPool.Add(self.CollectInfo) self.CollectInfo=nil end
    self.clickId=nil
    self:SetFunc("Remove")
end

return My