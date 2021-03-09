UIIdentification = UIBase:New{Name = "UIIdentification"}

local M = UIIdentification
local mgr = IdentifyMgr

function M:InitCustom()
    self:InitUserData()
end

function M:SetLsnr(key)
    
end

function M:InitUserData()
    local SC = UITool.SetLsnrClick
    local G = ComTool.Get
    local US = UITool.SetLsnrSelf
    local TFC = TransTool.FindChild
    local des = self.Name

    local root = self.root
    self.identifyBtn = TFC(root,"grid/BtnOK",des)
    self.touristBtn = TFC(root,"grid/BtnTourist",des)
    self.closeBtn = TFC(root,"BtnClose",des)
    self.grid = G(UIGrid,root,"grid")

    self.name = G(UIInput, root, "NameInput")
    self.identify = G(UIInput, root, "IdentifyInput")

    self.closeBtn:SetActive(false)

    US(self.identifyBtn,self.Send,self)
    US(self.touristBtn,self.Tourist,self)
    US(self.closeBtn,self.Close,self)
end

--0:表示无要求 1:宽松版 2:严格版本

function M:OpenCustom()
    local addState = IdentifyMgr.AddState
    if addState ~= 2 then
        self.identifyBtn:SetActive(true)
        self.touristBtn:SetActive(false)
        -- self.closeBtn:SetActive(true)
        self.grid:Reposition()
    elseif addState == 2 then
        self:OpenCb()
    end
end

function M:OpenCb()
    --" 1：能进行游客模式选择    2：正在进行游客模式直接要认证   3：游客模式结束直接要认证"
    local touristIndex = IdentifyMgr.TouristIndex
    -- local touristIndex = 2
    if touristIndex == 1 then
        self.identifyBtn:SetActive(true)
        self.touristBtn:SetActive(true)
        -- self.closeBtn:SetActive(true)
    elseif touristIndex == 2 then
        self.identifyBtn:SetActive(true)
        self.touristBtn:SetActive(false)
        -- self.closeBtn:SetActive(false)
    elseif touristIndex == 3 then
        self.identifyBtn:SetActive(true)
        self.touristBtn:SetActive(true)
        -- self.closeBtn:SetActive(false)
    end
    self.grid:Reposition()
end

function M:ShowMsgBox()
    local min = IdentifyMgr.CostMin
    -- local min = 60
    MsgBox.ShowYes(string.format("游客模式时间已超过%s分钟，请实名登记后再继续游戏",min),nil,nil,"返回标题界面")
end

function M:Send()
    IdentifyMgr:ReqRoleAddictAuth(self.identify.value, self.name.value)
end

function M:Tourist()
    local touristIndex = IdentifyMgr.TouristIndex
    -- local touristIndex = 3
    if touristIndex == 3 then
        self:ShowMsgBox()
    else
        self:Close()
        -- IdentifyMgr:ReqChoseTourist(true)
    end
end

return M