--[[
区域
--]]

AreaPanel=Super:New{Name="AreaPanel"}
local My = AreaPanel


function My:Init(go)
    self.go=go
   local U = UITool.SetBtnClick
   local trans = go.transform
   U(trans,"btn1",self.Name,self.OnBtn1,self)
   U(trans,"btn2",self.Name,self.OnBtn2,self)
   UITool.SetLsnrClick(trans,"Mask",self.Name,self.Close,self)
end

function My:UpData(rId)
    self.rId=rId

    self.go.transform.position=ChatInfo.pos
    local pos = self.go.transform.localPosition+Vector3.New(120,0,0)
    self.go.transform.localPosition=pos
end

--查看信息
function My:OnBtn1()
    UserMgr:ReqRoleObserve(self.rId,true)
    self:Close()
end

--屏蔽玩家
function My:OnBtn2()
    ChatMgr.ReqBanAdd(self.rId)
    self:Close()
end

function My:Open()
    self.go:SetActive(true)
end


function My:Close()
    self.go:SetActive(false)
end

function My:Dispose()
    -- body
end