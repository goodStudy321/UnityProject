--[[
聊天界面点击玩家头像弹出
--]]
PlayerInfo=Super:New{Name="PlayerInfo"}
local My = PlayerInfo

function My:Ctor()
    self.btnList={}
end

function My:Init(go)
    local CG=ComTool.Get
	local TF = TransTool.FindChild
    self.go=go
    local trans = go.transform

    self.grid=CG(UIGrid,trans,"Grid",self.Name,false)
    local U = UITool.SetBtnSelf
    for i=1,9 do
        local name="btn"..i
        local btn = TF(self.grid.transform,name)
        U(btn,self[name],self,self.Name)
        self.btnList[i]=btn
    end
    self.nameLab=CG(UILabel,trans,"name",self.Name,false)
    self.family=CG(UILabel,trans,"family",self.Name,false)
    self.lv=CG(UILabel,trans,"lv",self.Name,false)
    self.work=CG(UILabel,trans,"work",self.Name,false)
    self.icon=CG(UISprite,trans,"icon",self.Name,false)
    self.black=CG(UILabel,trans,"Grid/btn9/Label",self.Name,false)

    UITool.SetLsnrClick(trans,"Mask",self.Name,self.Close,self)
   
end

function My:UpData(info)
    if info.rId==User.MapData.UIDStr then 
        return 
    end

    self:Open()
    self.rId=info.rId
    self:IsBlack()

    local rN = info.rN
    local lv = info.lv
    local work = UIMisc.GetWork(info.cg)
    
    self.nameLab.text=rN
    self.lv.text="等级："..lv
    --self.family.text=FamilyMgr:GetFamilyNameById(id)
    self.work.text="职业："..work
    self.icon.spriteName="TX_0"..info.cg
    if self.isblack==true then 
        self.black.text="移出黑名单" 
    else
        self.black.text="加入黑名单"
    end
end

-- --是否在好友列表
-- function My:IsFriend()
--     local list = FriendMgr.FriendList
--     for i,v in ipairs(list) do
--         if v.id==self.rId then return true end
--     end
--     return false
-- end

--是否在黑名单
function My:IsBlack()
    local list = FriendMgr.BlackList
    for i,v in ipairs(list) do
        if v.ID==self.rId then self.isblack=true return end
    end
    self.isblack=false
end

function My:btn1()
    -- body

    self:Close()
end

--加为好友
function My:btn2()
    FriendMgr:ReqAddFriend(self.rId)
    UITip.Log("已发送申请")
    self:Close()
end

function My:btn3()
    -- body
    self:Close()
end

--查看信息
function My:btn4()
    UserMgr:ReqRoleObserve(self.rId) 
end

--邀请组队
function My:btn5()
    TeamMgr:ReqInviteTeam(self.rId)
    UITip.Log("已发送邀请")
    self:Close()
end

function My:btn6()
    -- body
    self:Close()
end

--申请入队
function My:btn7()
    TeamMgr:ReqTeamApply(0,self.rId)
    UITip.Log("已发送申请")
    self:Close()
end

function My:btn8()
    self:Close()
end

--加入黑名单
function My:btn9()
    if self.isblack==true then 
        FriendMgr:ReqFriendDelBlack(self.rId)
    else
        FriendMgr:ReqFriendAddBlack(self.rId)
    end
    self:Close()
end

function My:Open()
    self.go:SetActive(true)
end

function My:Close()
    self.go:SetActive(false)
end

function My:Dispose()
    
end