--[[
    福利界面
--]]
require("UI/UIOpenService/UICollWords")
require("UI/UIBenefit/UICmmView")
require("UI/UIOpenService/UIAccuPay")
require("UI/UIBenefit/UICouple")
-- require("UI/UIBenefit/UIJourneys")
require("UI/UIDayTarget/UIDayTarget")

UIBenefit = UIBase:New{Name = "UIBenefit"}
local My = UIBenefit

local togList = {}
local collWords = nil
local cDic = {}
local actId = {1003, 1016, 1019, 1017, 1005, 1022, 1036}
local redPoints = {}

function My:InitCustom()
    local trans=self.root
	local TF=TransTool.FindChild
    local CG=ComTool.Get
    
    local grid = TF(trans,"Grid").transform
    for i=1,#actId do
        local tg = CG(UIToggle, grid, "Tog"..i, self.Name, false)
        tg.gameObject:SetActive(LivenessInfo:IsOpen(actId[i]))
        togList[i] = tg   
        redPoints[i] = TF(tg.transform, "RedPoint")
        self:UpdateRedPoint(BenefitMgr:GetRedPointState(i), i)
        UITool.SetLsnrClick(trans, "Grid/Tog"..i, self.Name, self.Onclick, self)
    end
    self.tgrid = CG(UIGrid, trans, "Grid", self.Name)
    self.collWords = TF(trans, "CollWords")
    self.accuPay = TF(trans, "AccuPay")
    self.couple = TF(trans,"Couple")
    self.mDayTarget = TF(trans, "DayTarget")
    self.bg = TF(trans,"bg1")
    self.tgrid:Reposition()
    UITool.SetBtnClick(self.root,"CloseBtn",self.Name,self.Close,self)

    self.cmmView = ObjPool.Get(UICmmView)
    self.cmmView:Init(TF(trans, "CmmView"))

    self:SetLsnr("Add")
end

function My:SetLsnr(key)
    PropMgr.eGetAdd[key](PropMgr.eGetAdd, self.OnAdd, self)
    BenefitMgr.eUpdateData[key](BenefitMgr.eUpdateData, self.UpdateData, self)
    BenefitMgr.eUpdateRedPoint[key](BenefitMgr.eUpdateRedPoint, self.UpdateRedPoint, self)
    BenefitMgr.eUpdataRank[key](BenefitMgr.eUpdataRank, self.UpdataRank, self)
end

--道具添加
function My:OnAdd(action,dic)
	if action >= 10338 and action <= 10340 then		
		self.dic=dic
		UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	end
end

--显示奖励的回调方法
function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:UpdateData(self.dic)
	end
end

function My:UpdataRank(type)
    local mgr = BenefitMgr
    if mgr.CurPage == mgr.BossPage then
        self.cmmView:UpdateRankView(type)
    end
end

function My:UpdateRedPoint(state, id)
    if redPoints[id] then
        redPoints[id]:SetActive(state)
    end
end

function My:UpdateData(page)
    if BenefitMgr.CurPage == page then
        self.cmmView:UpdateData(BenefitMgr:GetBenefitData(page))
    end
end

function My:Show(tp)
    local isOpen = LivenessInfo:IsOpen(1005) --集字有礼活动是否开启
    if isOpen == false and tp == BenefitMgr.CollectWord then 
        UITip.Error("活动未开启")
        return 
    end
    self.tp = tp
    UIMgr.Open(self.Name, self.OpenCb, self)
end

function My:OpenCb()
    self:SetDefTp(self.tp) 
end

function My:OpenCustom()
    -- self:SetDefTp(7)  
end

function My:OpenTabByIdx(t1, t2, t3, t4)
    if not t1 then return end
    self.tp = t1
    self:SetDefTp(self.tp)  
end

function My:Onclick(go)
    local tp = tonumber(string.sub(go.name, 4))
    self:SwitchTg(tp)
end


function My:SetDefTp(tp)
    if tp and togList[tp] and togList[tp].gameObject.activeSelf then
        self:SwitchTg(tp)
    else
        for i=1,#togList do
            if togList[i].gameObject.activeSelf then
                self:SwitchTg(i)
                break
            end
        end
    end
end

function My:SwitchTg(tp)
    if self.curTp==tp then return end
    self.curTp=tp
    BenefitMgr.CurPage = tp
    togList[tp].value=true
    if self.curC then self.curC:Close() end
    local c=cDic[tostring(tp)]
    if tp ~= 6 and tp ~= 7 then self.bg:SetActive(true) else self.bg:SetActive(false) end
    if c then
        self.curC=c
    else
        if tp==BenefitMgr.AccuPage then --开服累充
            self:OAccuPay(c)
        elseif tp==BenefitMgr. CreatePage  --开宗立派
            or tp == BenefitMgr. BossPage  --猎杀BOSS
            or tp == BenefitMgr. BattlePage   --道庭争霸
        then
            self.cmmView:UpdateData(BenefitMgr:GetBenefitData(tp))
            return
        elseif tp==BenefitMgr.CollectWord then --集字有礼
            self:OCollWords(c)
        elseif tp == BenefitMgr.Couple then -- 神仙眷侣
            self:OCouple(c)
        elseif tp == BenefitMgr.DayTarget then --开服目标
            self:ODayTarget(c)
        end
    end
    self.cmmView:SetActive(false)
    self.curC:Open()
end

--开服累充
function My:OAccuPay(c)
    if not c then
		c = ObjPool.Get(UIAccuPay)
		c:Init(self.accuPay)
		cDic["1"]=c
	end
	self.curC=c
end

--集字有礼
function My:OCollWords(c)
    if not c then
        local info = LivenessInfo:GetActInfoById(1005)
        c = ObjPool.Get(UICollWords)
        c:Init(self.collWords, info)
        cDic["5"] = c
    end
    self.curC = c
end

-- 神仙眷侣
function My:OCouple(c)
    if not c then
        c = ObjPool.Get(UICouple)
        c:Init(self.couple)
        cDic["6"] = c
    end
    self.curC = c
end


--开服目标
function My:ODayTarget(c)
    if not c then
        c = ObjPool.Get(UIDayTarget)
        c:Init(self.mDayTarget)
        cDic["7"] = c
    end
    self.curC = c
end

function My:CloseCustom()
    self.curTp = nil
    if self.curC  and self.curC.Close then
        self.curC:Close()
        self.curC = nil
    end
    for k,v in pairs(cDic) do
        ObjPool.Add(v)
        cDic[k] = nil
    end
end

function My:DisposeCustom()
    self:SetLsnr("Remove")
    ObjPool.Add(self.cmmView)
    self.cmmView = nil
    self.tp = nil
end

return My