--[[
通天排行榜
]]
require("UI/UITongtianRank/SupremeThree")
require("UI/UITongtianRank/TongtianRank")

UITongtianRank=UIBase:New{Name="UITongtianRank"}
local My = UITongtianRank

function My:InitCustom()
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local U = UITool.SetBtnClick
    local trans = self.root

    self.SupremeThreeGO=TF(trans,"SupremeThree")
    self.TongtianRankGO=TF(trans,"TongtianRank")

    self.btn1=CG(UIToggle,trans,"btn1",self.Name,false)
    self.btn2=CG(UIToggle,trans,"btn2",self.Name,false)
    self.btn1Red=TF(trans,"btn1/red")
    U(trans,"CloseBtn",self.Name,self.OnClose,self)
    U(trans,"btn1",self.Name,self.OnBtn1,self)
    U(trans,"btn2",self.Name,self.OnBtn2,self)

    TongtianRankMgr.network.ReqUniverseRank()
    self.tg=nil
    self:OnAdmire()
    self:SetEvent("Add")
end

function My:OnClose()
    self:Close()
	JumpMgr.eOpenJump()
end

function My:OpenTabByIdx(t1,t2,t3,t4)
    if t1==1 then
        self:OnBtn1()
    elseif t1==2 then
        self:OnBtn2()
    end
end

function My:SetEvent(fn)
    TongtianRankMgr.eAdmire[fn](TongtianRankMgr.eAdmire,self.OnAdmire,self)
    UserMgr.eUpdateData[fn](UserMgr.eUpdateData,self.OnUpData,self)
end

function My:OnAdmire()
    self.btn1Red:SetActive(TongtianRankMgr.isRed)
end

function My:OnUpData()
    JumpMgr:InitJump(self.Name,self.tp)
    UIMgr.Close(self.Name)
	UIMgr.Open(UIOtherInfoCPM.Name)
end

function My:OnBtn1()
    self.tp=1
    self.btn1.value=true
    self.btn2.value=false
    if not self.SupremeThree then 
        self.SupremeThree=ObjPool.Get(SupremeThree)
        self.SupremeThree:Init(self.SupremeThreeGO)
        self.SupremeThree:UpData()
    end
    if self.tg and self.tg.Name==self.SupremeThree.Name then return end
    if self.tg then self.tg:Close() end
    self.SupremeThree:Open()
    self.tg=self.SupremeThree
end

function My:OnBtn2()
    self.tp=2
    self.btn1.value=false
    self.btn2.value=true
    if not self.TongtianRank then 
        self.TongtianRank=ObjPool.Get(TongtianRank)
        self.TongtianRank:Init(self.TongtianRankGO)
        self.TongtianRank:UpData()
    end
    if self.tg and self.tg.Name==self.TongtianRank.Name then return end
    if self.tg then self.tg:Close() end
    self.TongtianRank:Open()
    self.tg=self.TongtianRank
end

function My:DisposeCustom()
    self:SetEvent("Remove")
    if self.SupremeThree then ObjPool.Add(self.SupremeThree) self.SupremeThree=nil end
    if self.TongtianRank then ObjPool.Add(self.TongtianRank) self.TongtianRank=nil end
end

return My