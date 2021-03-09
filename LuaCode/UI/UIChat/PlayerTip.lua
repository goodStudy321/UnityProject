--[[
聊天界面各种小tip呀
--]]
require("UI/UIChat/PlayerInfo")
require("UI/UIChat/AreaPanel")
require("UI/UIChat/TpPanel")
require("UI/UIChat/IgnorePanel")
require("UI/UIChat/VoiceToLab")

PlayerTip=Super:New{Name="PlayerTip"}
local My = PlayerTip


function My:Init(go)
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local trans = go.transform

    self.p1=TF(trans,"PlayerInfo")
    self.p2=TF(trans,"AreaPanel")
    self.p3=TF(trans,"IgnorePanel")
    self.p4=TF(trans,"TpPanel")
    self.p5=TF(trans,"VoiceToLab")

    ChatInfo.eClick:Add(self.OnClick,self)
    UIChat.eSet:Add(self.OnTpPanel,self)
    UIChat.eIgnore:Add(self.OnIgnorePanel,self)
    ChatInfo.eToLab:Add(self.OnToLab,self)   
end

function My:OnClick(info)
    if info==nil then return end
    local rId = info.rId
    if UIChat.cTp==6 then --区域
        local x1,x2 = math.modf(rId/100000000)
        local y1 = x1%100000

        local selfId=tostring(User.instance.MapData.UID)
        local xx1,xx2 = math.modf(tonumber(selfId)/100000000)
        local y2 = xx1%100000

        if y1==y2 then
            self:OnPlayerInfo(info)
        else
            self:OnAreaPanel(rId)
        end       
    else
        self:OnPlayerInfo(info)
    end
end

function My:OnPlayerInfo(info)
    if not self.PlayerInfo then self.PlayerInfo=ObjPool.Get(PlayerInfo) self.PlayerInfo:Init(self.p1) end
    self.PlayerInfo:UpData(info)
end

function My:OnAreaPanel(rId)
    if not self.AreaPanel then self.AreaPanel=ObjPool.Get(AreaPanel) 
        self.AreaPanel:Init(self.p2) 
    end
    self.AreaPanel:Open()
    self.AreaPanel:UpData(rId)
end

function My:OnIgnorePanel()
    if not self.IgnorePanel then self.IgnorePanel=ObjPool.Get(IgnorePanel) self.IgnorePanel:Init(self.p3) end
    self.IgnorePanel:UpData()
    self.IgnorePanel:Open()
end

function My:OnTpPanel()
    if not self.TpPanel then self.TpPanel=ObjPool.Get(TpPanel) self.TpPanel:Init(self.p4) end
    self.TpPanel:Open()
end

function My:OnToLab()
    if not self.VoiceToLab then self.VoiceToLab=ObjPool.Get(VoiceToLab) self.VoiceToLab:Init(self.p5) end
    self.VoiceToLab:Open()
end

function My:Dispose()
    ChatInfo.eClick:Remove(self.OnClick,self)
    UIChat.eSet:Remove(self.OnTpPanel,self)
    UIChat.eIgnore:Remove(self.OnIgnorePanel,self)
    ChatInfo.eToLab:Remove(self.OnToLab,self)
    if self.PlayerInfo then ObjPool.Add(self.PlayerInfo) self.PlayerInfo=nil end
    if self.AreaPanel then ObjPool.Add(self.AreaPanel) self.AreaPanel=nil end
    if self.IgnorePanel then ObjPool.Add(self.IgnorePanel) self.IgnorePanel=nil end
    if self.TpPanel then ObjPool.Add(self.TpPanel) self.TpPanel=nil end
    if self.VoiceToLab then ObjPool.Add(self.VoiceToLab) self.VoiceToLab=nil end
end