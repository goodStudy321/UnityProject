--[[
    闭关修炼界面
]]
require("UI/Robbery/StateExpFly")
UIPrayPanel = Super:New{Name = "UIPrayPanel"}
local M = UIPrayPanel

local ED = EventDelegate

function M:Init(root)
    self.go = root.gameObject
    local C = ComTool.Get
    local T = TransTool.FindChild
    local US = UITool.SetLsnrSelf
    local UC = UITool.SetLsnrClick

    local root = self.go.transform
    self.timesLb = C(UILabel,root,"getBtn/numLab")
    self.timesLb.gameObject:SetActive(false)
    self.moneyGbj = T(root,"getBtn/money")
    self.iconLb = C(UILabel,root,"getBtn/money/num")
    self.btn = T(root,"getBtn")
    self.btnLb = C(UILabel,root,"getBtn/lab")
    self.action = T(root,"getBtn/action")
    self.desBtn = C(BoxCollider, root,"pryDes")
    UC(root, "getBtn", "prayBtn", self.OnRetreat, self)

    self.allTimesLb = C(UILabel,root,"pryDes/des")
    -- self.timeLb = C(UILabel,desTrans,"time")

    US(self.desBtn, self.OnClickStDBtn, self)

    local flyExp = T(root,"flyExp")
    self.flyExpAct = ObjPool.Get(StateExpFly)
	self.flyExpAct:Init(flyExp)

    self:ShowData()
    self:SetLsner("Add")
end

function M:SetLsner(key)
    PrayMgr.eChangeRes[key](PrayMgr.eChangeRes,self.ShowData,self)
    VIPMgr.eVIPEnd[key](VIPMgr.eVIPEnd,self.ShowData,self)
    PrayMgr.eUpdataData[key](PrayMgr.eUpdataData,self.ShowData,self)
end

function M:OnClickStDBtn(go)
    local desInfo = InvestDesCfg["1021"]
    local str = desInfo.des
    UIComTips:Show(str, Vector3(392,-78,0),nil,nil,nil,nil,UIWidget.Pivot.TopRight)
end

-- function M:UpShow(value)
--     self.go:SetActive(value)
-- end

function M:OpenTabByIdx(t1, t2, t3, t4)
	-- body
end

function M:ShowFlyExp()
    if self.flyExpAct then
        self.flyExpAct:UpdateFlyExp()
    end
end

function M:OnRetreat()
    -- LvAwardMgr:UpAction(5,false)
    local curTimes,resTimes,icon,getExp = PrayMgr:GetData()
    local isOpen = PrayMgr:IsOpen()
    if isOpen == false then
        UITip.Error("还未达到开启条件")
        return
    end
    if RoleAssets.Gold < self.spend and getExp > 0 then
        StoreMgr.JumpRechange()
        return
    end
    PrayMgr:ReqReward()
end

function M:ShowData()
    local curTimes,resTimes,icon,getExp = PrayMgr:GetData()
    local str = string.format("闭关(%s/%s)",resTimes,curTimes)
    -- self.btnLb.text = "闭关"
    self.action:SetActive(false)
    self.moneyGbj:SetActive(true)
    if getExp == 0 then
        -- self.btnLb.text = "首次免费"
        str = "首次免费"
        self.action:SetActive(true)
        self.moneyGbj:SetActive(false)
    end
    self.btnLb.text = str
    if resTimes <= 0 then
        UITool.SetGray(self.btn,true)
    else
        UITool.SetNormal(self.btn)
    end
    self.spend = getExp
    local allTimes = PrayMgr:GetAllTimes()
    local time = GlobalTemp["139"].Value2[2]
    -- self.timesLb.text = resTimes.."/"..curTimes
    -- self.iconLb.text = icon.."元宝"
    self.iconLb.text = getExp
    self.allTimesLb.text = "[FDC580]每次闭关可获得[-][F9AB47]60[-][00FF00](+"..allTimes..")[-][FDC580]分钟经验收益[-]"
    -- self.timeLb = time.."分钟"
end


function M:Dispose()
    if self.flyExpAct then
		ObjPool.Add(self.flyExpAct)
        self.flyExpAct = nil
	end
    self:SetLsner("Remove")
end

return M