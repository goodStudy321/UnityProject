DemonBuffView = Super:New{Name = "DemonBuffView"}

local M = DemonBuffView

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf
    
    self.mGo = go
    self.mBtnClose = FC(trans, "BtnClose")
    self.mBtnNo = FC(trans, "BtnNo")
    self.mBtnYes = FC(trans, "BtnYes")
    self.mDes = G(UILabel, trans, "Des")
    self.mAttr = G(UILabel, trans, "Attr")
    self:InitAttr()

  
    S(self.mBtnClose, self.Close, self)
    S(self.mBtnNo, self.OnNo, self)
    S(self.mBtnYes, self.OnYes, self)
end

function M:Open()
    self:SetActive(true)
    self:UpdateData()
end

function M:InitAttr()
    local buffId = GlobalTemp["125"].Value3
    local buff = BuffTemp[tostring(buffId)].valueList[1]
    local prop = PropName[buff.k]
    local val = buff.v
    if prop.show == 1 then
        val = string.format("%s%%", val*0.0001*100)
    end
    self.mAttr.text = string.format("[F5DDBCFF]%s[00FF00FF]+%s", prop.Text, val)
end

function M:UpdateData()
    local list = GlobalTemp["125"].Value1
    local len = #list
    local value = list[len].value
    local count = DemonMgr:GetAddbuffTime()
    for i=1,len do
        if count <= list[i].id then
            value = list[i].value
            break
        end
    end
    self.mCost = value
    self.mDes.text = string.format("[B29E81FF]是否消耗%s元宝获得复仇buff？", value)
end

function M:Close()
    self:SetActive(false)
end

function M:OnNo()
    self:SetActive(false)
end

function M:OnYes()
    if RoleAssets.IsEnoughAsset(3, self.mCost) then
        DemonMgr:ReqDemonBossCheer()
    else
        UITip.Log("元宝不足")
        self:Close()
    end
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:Dispose()
    self.mCost = 0
    TableTool.ClearUserData(self)
end

return M