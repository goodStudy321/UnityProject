--[[

]]
SuitEquipCell=BaseCell:New{Name="SuitEquipCell"}
local My = SuitEquipCell
My.eClick=Event()

function My:Ctor()
    self.starList={}
end

function My:Init(parent,suitId)
    self.parent=parent
    self.suitId=suitId
    local data = SuitAttData[tostring(suitId)]
    if not data then iTrace.eError("xiaoyu","套装属性表为空 id: "..suitId)return end
    self.data=data
    LoadPrefab(self.Name,GbjHandler(self.LoadCb,self))
end

function My:UpData()
    local suitId=self.suitId
    local data=self.data
    local iconPath = data.icon
    local starLv = data.star
    self:CustomData(nil,iconPath,data.suitName,starLv)
    self:IsClick(self.isClick)
    self:CheckActive()
end

function My:LoadCb(go)
    go.transform.parent=self.parent.transform
    go:SetActive(false)
    go:SetActive(true)
	go.transform.localPosition=Vector3.zero
    go.transform.localScale=Vector3.one
    self.parent:Reposition()
    self:InitCustom(go)
    self:UpData()
end

function My:CheckActive()
    local rbLv = RebirthMsg.RbLev
    local rb = self.data.rbLev
    self.active=rbLv>=rb and true or false
    self.starGrid:SetActive(self.active)
    self.ActiveRbLv:SetActive(self.active==false)
    if self.active==false then
        local lab=self.ActiveRbLv:GetComponent(typeof(UILabel))
        lab.text=UIMisc.ToNum(rb).."转可激活"
    end
end

function My:InitCustom(go)
    self.go=go
    local CG = ComTool.Get
	local TF = TransTool.FindChild
    local trans = go.transform
    self.lab=CG(UILabel,trans,"Name",self.Name,false)
    self.Icon=CG(UITexture,trans,"Icon",self.Name,false)
    self.bg=CG(UISprite,trans,"bg",self.Name,false)
    self.ActiveRbLv=TF(trans,"ActiveRbLv")
    UITool.SetLsnrSelf(go,self.OnClickGo,self,self.Name)
    self.starGrid=TF(trans,"Grid")
    local grid = self.starGrid.transform
    for i=1,5 do
        local star = CG(UISprite,grid,"s"..i,self.Name,false)
        self.starList[i]=star
    end
end

function My:IsClick(state)
    self.bg.spriteName=state==true and "ty_a15" or "ty_a3"
end

function My:OnClickGo()
    My.eClick(self.suitId,self)
end

function My:Dispose()
    if self.isClick then self.isClick=nil end
    self.go:SetActive(false)
    GbjPool:Add(self.go)
    ListTool.Clear(self.starList)
end

