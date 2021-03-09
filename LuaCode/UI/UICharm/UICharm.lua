--[[
魅力之王
]]
require("UI/UICharm/UIRankReward")
require("UI/UICharm/CharmRank")

UICharm=Super:New{Name="UICharm"}
local My=UICharm

function My:Init(go)
    self.go=go
    local trans = go.transform
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local U = UITool.SetBtnClick

    local left=TF(trans,"leftBg").transform
    self.CharmRank=ObjPool.Get(CharmRank)
    self.CharmRank:Init(left)


    local right=TF(trans,"rightBg").transform
    self.charmLab=CG(UILabel,right,"charmLab/lab",self.Name,false)
    self.rankLab=CG(UILabel,right,"rankLab/lab",self.Name,false)
    self.maleEff=TF(right,"MaleBtn/FX_quanzhuan")
    self.femaleEff=TF(right,"FemaleBtn/FX_quanzhuan")

    self.rewardGo=TF(trans,"UIRankReward")
    U(trans,"charmBtn",self.Name,self.OnCharm,self)
    U(right,"MaleBtn",self.Name,self.OnMale,self)
    U(right,"FemaleBtn",self.Name,self.OnFemale,self)
    U(right,"rewardBtn",self.Name,self.OnReward,self)
    U(trans,"Tip",self.Name,self.OnTip,self)

    self.remainLab=CG(UILabel,trans,"remainLab",self.Name,false)
    self.tipLab=CG(UILabel,trans,"Tip/Label",self.Name,false)
    if not self.timer then 
        self.timer=ObjPool.Get(DateTimer) 
        self.timer.invlCb:Add(self.CountTime,self)
    end
    if not self.timer2 then 
        self.timer2=ObjPool.Get(iTimer) 
        self.timer2.complete:Add(self.ShowReqRank,self)
    end
    self:SetEvent("Add")
    self:InitData()
end

function My:SetEvent(fn)
    CharmMgr.eRank[fn](CharmMgr.eRank,self.UpData,self)
    UserMgr.eUpdateData[fn](UserMgr.eUpdateData,self.OnUpData,self)
    FlowersMgr.eSend[fn](FlowersMgr.eSend,self.OnSendFlo,self)
end

function My:UpData()
    if self.CharmRank then self.CharmRank:UpData() end
    self:ShowCharm()
    self:ShowRank()
end

function My:OnUpData()
    JumpMgr:InitJump(UIHeavenLove.Name,2)
    UIMgr.Close(UIHeavenLove.Name)
	UIMgr.Open(UIOtherInfoCPM.Name)
end

function My:CountTime()
    self.remainLab.text=self.timer.remain
end

function My:InitData()
    local temp = InvestDesCfg["2022"]
    local des = temp.des
    self.tipLab.text=des
end

function My:OpenCustom( ... )
    local info = NewActivMgr:GetActivInfo(2012)
    if info then
        local time = info.endTime-DateTool.GetServerTimeSecondNow()
        self.remainLab.text=DateTool.FmtSec(time)
        self.timer:Stop()
        self.timer.seconds=time
        self.timer:Start()
    end
    self:ShowCharm()
   self:ShowReqRank()
end

function My:OnSendFlo()
    self.timer2:Stop()
    self.timer2.seconds=1
    self.timer2:Start()
end

function My:ShowReqRank( ... )
    if User.instance.MapData.Sex==1 then
        self:OnMale()
    else
        self:OnFemale()
    end
end

function My:ShowCharm()
    self.charmLab.text=tostring(CharmMgr.myCharm)
end

function My:ShowRank()
    local id = User.instance.MapData.UIDStr
    local text="未上榜"
    local ranks = CharmMgr.ranks
    for i,v in ipairs(ranks) do
        if v.role_id==id then
            text=tostring(v.rank)
            break
        end
    end
    self.rankLab.text=text
end

--我要魅力
function My:OnCharm( ... )
    local tab = {}
    local k1 = {}
    k1.k=12540
    local k2 = {}
    k2.k=31000
    table.insert( tab, k1 )
    table.insert( tab, k2 )
    GetWayFunc.GetWayKVList(tab,Vector3.New(222,-153,0))
end

--男神榜
function My:OnMale( ... )
    self.maleEff:SetActive(true)
    self.femaleEff:SetActive(false)
    CharmNetwork.ReqCharmRank(1)
end

--女神榜
function My:OnFemale( ... )
    self.femaleEff:SetActive(true)
    self.maleEff:SetActive(false)
    CharmNetwork.ReqCharmRank(0)
end

--奖励
function My:OnReward( ... )
    if not self.reward then 
        self.reward=ObjPool.Get(UIRankReward) 
        self.reward:Init(self.rewardGo)
    end
    self.reward:Open()
end

function My:OnTip()
    local temp = InvestDesCfg["2023"]
    local des = temp.des
    UIComTips:Show(des, Vector3(-255,-188,0),nil,nil,5,400,UIWidget.Pivot.TopLeft);
end


function My:Open( ... )
    self.go:SetActive(true)
    self:OpenCustom()
end

function My:Close( ... )
    self.go:SetActive(false)
    self.timer:Stop()
end

function My:Dispose()
    self:SetEvent("Remove")
    if self.CharmRank then ObjPool.Add(self.CharmRank) self.CharmRank=nil end
    if self.reward then ObjPool.Add(self.reward) self.reward=nil end
    if self.timer then self.timer:AutoToPool() self.timer=nil end
    if self.timer2 then self.timer2:AutoToPool() self.timer2=nil end
end