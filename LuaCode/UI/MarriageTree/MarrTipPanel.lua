MarrTipPanel = UIBase:New{Name = "MarrTipPanel"}

local M = MarrTipPanel

local US = UITool.SetLsnrSelf

function M:InitCustom()
    local root = self.root

    local C = ComTool.Get
    local T = TransTool.FindChild

    self.Btn1 = T(root,"type1")
    self.Btn2 = T(root,"type2")

    self.closeBtn = T(root,"closeBtn")
    US(self.closeBtn,self.ClickToClose,self,self.Name)

    self.yesBtn = T(root,"type1/yesBtn")
    US(self.yesBtn,self.ClickToYes,self,self.Name)

    self.okBtn = T(root,"type2/yesBtn")
    US(self.okBtn,self.ClickToClose,self,self.Name)

    self.noBtn = T(root,"type1/noBtn")
    US(self.noBtn,self.ClickToClose,self,self.Name)

    self.yesBtnLb = C(UILabel,root,"type1/yesBtn/Label")
    self.noBtnLb = C(UILabel,root,"type1/noBtn/Label")
    self.okBtnLb = C(UILabel,root,"type2/yesBtn/Label")
    self.tipLb = C(UILabel,root,"Label")

    self.texBg = C(UITexture,root,"bg")
    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    MarriageTreeMgr.eChangeTaBtn[key](MarriageTreeMgr.eChangeTaBtn,self.Close,self)
end

function M:ClickToClose()
    self:Close()
end

function M:ClickToYes()
    if self.isReqStatus == true then
        self:Close()
        UIMarry:OpenTab(4)
        UIMgr.Open(MarrTipPanel.Name)
        local taName = MarryInfo.data.coupleInfo.name
        MarrTipPanel:ChangeBtnLbAndLb(true,false,"即将为你的另一半"..taName.."种下一棵姻缘树，种植花费520元宝","确定","取消")
    else
        local gold = RoleAssets.Gold
        if gold >= 520 then
            MarriageTreeMgr:ReqForTaTree()
        else
            self:Close()
            StoreMgr.JumpRechange()
        end
    end
end

function M:ChangeBtnLbAndLb(isBtn1,isBtn2,tipLb,yesBtnLb,noBtnLb,isReqStatus)
    if self.Btn1 then self.Btn1:SetActive(isBtn1) end
    if self.Btn2 then self.Btn2:SetActive(isBtn2) end
    self.tipLb.text = tipLb
    if isBtn1 == true then
        self.yesBtnLb.text = yesBtnLb
        self.noBtnLb.text = noBtnLb
    end
    if isBtn2 == true then
        self.okBtnLb.text = yesBtnLb
    end
    if isReqStatus then
        self.isReqStatus = isReqStatus
    end
end

function M:Clear()
    self:SetLsnr("Remove")
    self.isReqStatus = nil
end

return M