--[[


--]]

TpPanel=Super:New{Name="TpPanel"}
local My = TpPanel

function My:Init(go)
    if not self.list then self.list={} end
    if not self.list2 then self.list2={} end
    self.go=go
    local trans = go.transform
    local U=UITool.SetLsnrClick
    local CG = ComTool.Get
    for i=0,6 do
        if i~=4 then 
            local tog = CG(UIToggle,trans,"Grid/Tg"..i,self.Name,false)
            tog.value=ChatMgr.tpDic[tostring(i)]
            self.list[tostring(i)]=tog
            U(trans,"Grid/Tg"..i,self.Name,self.OnTg,self)
        end
    end

    for i=1,6 do
        local tog = CG(UIToggle,trans,"Grid2/Tg"..i,self.Name,false)
        tog.value=ChatMgr.quaDic[tostring(i)]
        self.list2[tostring(i)]=tog
        U(trans,"Grid2/Tg"..i,self.Name,self.OnTg2,self)
    end
    U(trans,"CloseBtn",self.Name,self.Close,self)
end

function My:OnTg(go)
    local tp = string.sub(go.name,3)
    local tog= self.list[tp]
    local val = tog.value
    ChatMgr.tpDic[tp]=val
    ChatMgr.SetUserData()
end

function My:OnTg2(go)
    local tp = string.sub(go.name,3)
    local tog= self.list2[tp]
    local val = tog.value
    ChatMgr.quaDic[tp]=val
    ChatMgr.SetUserData()
end

function My:Close()
    self.go:SetActive(false)
end

function My:Open()
    self.go:SetActive(true)
end

function My:Dispose()
    TableTool.ClearDic(self.list)
    TableTool.ClearDic(self.list2)
    self.list=nil
    self.list2=nil
    TableTool.ClearUserData(self)
end