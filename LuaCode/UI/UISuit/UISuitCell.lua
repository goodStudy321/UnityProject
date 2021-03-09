UISuitCell=BaseCell:New{Name="UISuitCell"}
local My = UISuitCell
My.eClick=Event()
My.eLoadEnd=Event()

function My:Init(parent,partId)
    self.partId=partId
    self.parent=parent
    local data = SuitStarData[tostring(partId)]
    if not data then iTrace.eError("xioayu","套装升星表为空 id: "..partId)return end
    self.data=data
    LoadPrefab(self.Name,GbjHandler(self.LoadCb,self))
end

function My:UpData()
    local partId = self.partId
    local data =  self.data
    self.go.name=tostring(data.part)
    local iconPath = data.icon
    local rank = data.rank>0 and data.rank.."阶" or ""
    self:CustomData(nil,iconPath,rank)
    if data.rank==0 then
        UITool.SetGray(self.Icon.gameObject,false)
    else
        UITool.SetNormal(self.Icon.gameObject)
    end
end

function My:LoadCb(go)
    go.transform.parent=self.parent.transform
    go:SetActive(false)
    go:SetActive(true)
	go.transform.localPosition=Vector3.zero
    go.transform.localScale=Vector3.one
    self:InitCustom(go)
    self:UpData()
    self:IsClick(self.isClick)
    My.eLoadEnd()
end

function My:InitCustom(go)
    self.go=go
    local CG = ComTool.Get
	local TF = TransTool.FindChild
    local trans = go.transform
    self.lab=CG(UILabel,trans,"Lab",self.Name,false)
    self.Icon=CG(UITexture,trans,"Icon",self.Name,false)
    self.Select=TF(trans,"Select")
    self.red=TF(trans,"red")
    self.s1=TF(trans,"s1")
    self.s2=TF(trans,"s2")
    self.h1=TF(trans,"h1")
    self.h2=TF(trans,"h2")
    AssetMgr:SetPersist(self.s1.name, ".prefab",true)
    AssetMgr:SetPersist(self.s2.name, ".prefab",true)
    AssetMgr:SetPersist(self.h1.name, ".prefab",true)
    AssetMgr:SetPersist(self.h2.name, ".prefab",true)
    UITool.SetLsnrSelf(go,self.OnClickGo,self,self.Name,false)
end

function My:IsRed(active)
    self.red:SetActive(active)
end

function My:OnClickGo()
    My.eClick(self.partId,self)
end

function My:IsClick(state)
    self.Select:SetActive(state)
end

function My:ShowLeftLine(ish,iss)
    self.h2:SetActive(ish)
    self.s2:SetActive(iss)
end

function My:ShowRightLine(ish,iss)
    self.h1:SetActive(ish)
    self.s1:SetActive(iss)
end

function My:HideLine()
    self:ShowLeftLine(false,false)
    self:ShowRightLine(false,false)
end

function My:Dispose()
    self:IsRed(false)
    self:HideLine()
    if self.isClick then self.isClick=nil end
    self.go.name=self.Name
    GbjPool:Add(self.go)
end