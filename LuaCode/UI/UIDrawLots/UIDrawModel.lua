--[[

]]
UIDrawModel=UIItemModel:New{Name="UIDrawModel"}
local My = UIDrawModel

function My:Init(go)
    self.root=go.transform
    self.gbj=go
    self:InitCustom()
end

function My:InitCustom()
    local TF = TransTool.FindChild
    if not self.tgList then self.tgList={} end
    self.bg=TF(self.root,"bg").transform
    self.tg1=ObjPool.Get(DisplayModel)
    self.tg1.idName="drawPos"
    self.tg2=ObjPool.Get(DisplayBubble)
    self.tg3=ObjPool.Get(DisplayHead)
    self.tg4=ObjPool.Get(DisplayFoot)
    table.insert( self.tgList,self.tg1)
    table.insert( self.tgList,self.tg2)
    table.insert( self.tgList,self.tg3)
    table.insert( self.tgList,self.tg4)
    for i,v in ipairs(self.tgList) do
        v:Init(TF(self.bg,v.Name))
    end
end

function My:UpData(type_id)
    if self.lastTp then
        local lastTg = self.tgList[self.lastTp]
        lastTg.go:SetActive(false)
    end
    local isTrue = My.IsTrue(type_id)
    if isTrue==false then return end
    self.lastTp=My.tp
    local tg = self.tgList[self.lastTp]
    tg.path=My.path
    tg.go:SetActive(true)
    tg:LoadTex()
end

function My:DisposeCustom( ... )
    self.lastTp=nil
    My.tp=nil
    ListTool.ClearToPool(self.tgList)
end

