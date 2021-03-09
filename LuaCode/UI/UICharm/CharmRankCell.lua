--[[
魅力排行榜格子
]]

CharmRankCell=Super:New{Name="CharmRankCell"}
local My = CharmRankCell

function My:Init(go)
    self.go=go
    local trans = go.transform
    local CG = ComTool.Get
    self.icon=CG(UISprite,trans,"icon",self.Name,false)
    self.nameLab=CG(UILabel,trans,"nameLab",self.Name,false)
    self.charmLab=CG(UILabel,trans,"charmLab",self.Name,false)
    self.LvLab=CG(UILabel,trans,"LvLab",self.Name,false)
    self.Lv=CG(UISprite,trans,"Lv",self.Name,false)
    UITool.SetBtnClick(trans,"send",self.Name,self.OnSend,self)
    UITool.SetBtnClick(trans,"icon",self.Name,self.OnIcon,self)
    self.str=ObjPool.Get(StrBuffer)
    self:InitCustom()
end

function My:InitCustom( ... )
    -- body
end

--data number就是rank
function My:UpData(data)
    self.data=data
    local sex = -2
    local name = nil
    local charm = 0
    local rank = nil
    if type(data)=="table" then
        sex = data.sex
        name=self:GetName(data)
        charm = data.charm
        rank = data.rank

    else
        name="虚位以待"
        rank=data
    end
    self.icon.spriteName="TX_0"..(sex+1)
    self.nameLab.text=name
    self.charmLab.text=string.format( "%s (魅力值)",charm)
    local lvTX = ""
    if rank>3 then
        self.str:Dispose()
        self.str:Apd("第"):Apd(UIMisc.NumToStr(rank)):Apd("名") 
        lvTX=self.str:ToStr()
    end
    local lvSP = rank<=3 and "mlzw_font_0"..rank or nil
    self.LvLab.text=lvTX
    self.Lv.spriteName=lvSP

    self:UpDataCustom(data)
end

function My:GetName(data)
    local text=string.format( "%s  %s",data.server_name,data.role_name)
    return text
end

function My:UpDataCustom(data)
    
end

--送花
function My:OnSend()
    if type(self.data)=="number" then return end
    local isFriend = FriendMgr:IsFriend(self.data.role_id)
    local id = User.instance.MapData.UIDStr
    if isFriend==false and self.data.role_id~=id then
        UITip.Log("请先添加对方为好友")
        return 
    end
    UIMgr.Open(UIFlowers.Name)
end

function My:OnIcon()
    if type(self.data)=="number" then return end
    local iscross = UserMgr:CheckIsCross(self.data.server_name)
    local id = tonumber(self.data.role_id)
    UserMgr:ReqRoleObserve(id,iscross)
end

function My:Open( ... )
    self.go:SetActive(true)
end

-- function My:Close( ... )
--     self.go:SetActive(false)
-- end

function My:Dispose( ... )
   if self.str then ObjPool.Add(self.str) self.str=nil end
end