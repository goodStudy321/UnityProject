UIDesView = Super:New{Name = "UIDesView"}

local M = UIDesView

function M:Init(go, func)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf

    self.func = func
    self.go = go
    self.bg = go:GetComponent(typeof(UITexture))
    self.des = G(UILabel, trans, "Des")
    self.countDown = G(UILabel, trans, "CountDown")
    self.btn1 = FC(trans, "Btn1")
    self.btn2 = FC(trans, "Btn2")
    self.btnName1 = G(UILabel, self.btn1.transform ,"Name")
    self.btnName2 = G(UILabel, self.btn2.transform ,"Name")
    S(self.btn1, self.OnClickBtn1, self)
    S(self.btn2, self.OnCkickBtn2, self)
    S(FC(trans, "BtnHelp"), self.OnHelp, self)

    self.texList = {}

    self:CreateTimer()
end


function M:OnHelp()
    if self.actId then
        local cfg = InvestDesCfg[self.actId]
        if cfg and cfg.des then
            UIComTips:Show(cfg.des,Vector3(-65,200,0),16,0,0,0,UIWidget.Pivot.TopLeft)
        end
    end
end

function M:CreateTimer()
    if not self.timer then
        self.timer = ObjPool.Get(DateTimer)
        self.timer.invlCb:Add(self.InvlCb, self)
    end
end

function M:InvlCb()
    if self.countDown and self.timer then
        self.countDown.text = string.format("[69221f]剩余时间：[-][F21919FF]%s[-]", self.timer.remain)
    end
end


function M:UpdateData()
    local index = BenefitMgr.CurPage
    local data = nil
    self.btn2:SetActive(index == BenefitMgr.BossPage)
    self.actId = nil
    if index == BenefitMgr.CreatePage then
        self.actId = "1016"
        data = XsActiveCfg["1016"]
        self.btnName1.text = "创建道庭"
    elseif index == BenefitMgr.BossPage then
        self.actId = "1019"
        data = XsActiveCfg["1019"]
        self.btnName1.text = "个人积分排行榜"
        self.btnName2.text = "道庭积分排行榜"
    elseif index == BenefitMgr.BattlePage then
        self.actId = "1017"
        data = XsActiveCfg["1017"]
        self.btnName1.text = "加入道庭"
    end

    if not data then return end
    AssetMgr:Load("kaifuhuodong_"..index, ".png", ObjHandler(self.SetIcon, self))
    local info = LivenessInfo:GetActInfoById(data.id)
    self:UpdateTImer(info)
    self:UpdateDes( data.detail, info)
end

function M:UpdateDes(str, info)
    if not info then return end
    if info.id == 1017 then
        local day = DateTool.GetDay(TimeTool.GetServerTimeNow()*0.001 - info.sTime)
        str = string.gsub(str, "X", day+1)
    end
    self.des.text = string.format("[69221f]%s[-]", str) 
end

function M:SetIcon(tex)
    if self.texList then
        self.bg.mainTexture = tex
        table.insert(self.texList, tex.name)
    else
        AssetTool.UnloadTex(tex.name)
    end
end

function M:UpdateTImer(info)
    if not info then 
        self:StopTimer()
    else
        local second = info.eTime - TimeTool.GetServerTimeNow()*0.001
        if second <=0 then 
            self:StopTimer()
        else
            self.timer.seconds = second
            self:StartTimer()
        end
    end
end

function M:StopTimer()
    self.timer:Stop()
    self.countDown.gameObject:SetActive(false)
end

function M:StartTimer()
    self.timer:Start()
    self:InvlCb()
    self.countDown.gameObject:SetActive(true)
end

function M:OnClickBtn1()
    local name = self.btnName1.text

    local function Go(page)
        if OpenMgr:IsOpen(OpenMgr.XM) then
            if FamilyMgr:JoinFamily() then
                UIMgr.Open(UIFamilyMainWnd.Name);
            else
                UIMgr.Open(UIFamilyListWnd.Name);
            end
            JumpMgr:InitJump(UIBenefit.Name, page)
        else
            UITip.Log("请先激活道庭系统")
        end
    end

    if name == "创建道庭" then
        Go(BenefitMgr.CreatePage)
    elseif name == "加入道庭" then
        Go(BenefitMgr.BattlePage)
    elseif name == "个人积分排行榜" then
        if self.func then
            self.func(BenefitMgr.Personal)
        end
    end
end


function M:OnCkickBtn2()
    local name = self.btnName2.text
    if name == "道庭积分排行榜" then
        if self.func then
            self.func(BenefitMgr.Famlily)
        end
    end
end

function M:SetActive(bool)
    if self.go then
        self.go:SetActive(bool)
    end
end

function M:Dispose()
    AssetTool.UnloadTex(self.texList)
    self.texList = nil
    if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
    end
    TableTool.ClearUserData(self)
end

return M