--[[
    每日累充的充值实例
]]

UIEvrPayItem = Super:New{Name = "UIEvrPayItem"}
local My = UIEvrPayItem

function My:Init(go, cfg)
    local trans = go.transform
    self.root = trans
    local CG = ComTool.Get
    local des = self.Name
    local TF = TransTool.FindChild
    local T = TransTool.Find
    self.cfg = cfg
    self.itList = {}

    self.awardgrid = CG(UIGrid, trans, "AwardGrid", des)
    self.AwardGrid = T(trans, "AwardGrid", des)
    self.cell = TF(trans, "ItemCell", des)
    self.cell.gameObject:SetActive(false)
    self.Btn = T(trans, "GetAdBtn", des)
    self.BtnLab = CG(UILabel, trans, "GetAdBtn/Label", des)

    self:InitSelf(cfg)
end

function My:InitSelf(cfg)
    local day = EvrDayInfo.OpenDay
    local temp = cfg["award"..day]
    local award = (temp) and temp or cfg.award0

    self:InitItem(award)
    self:InitBtnState(cfg.id)
end

function My:InitItem(award)
    self:CleanData()
    local list = self.itList
    for i,j in ipairs(award) do

        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.awardgrid.transform,0.9)
        cell:UpData(j.k, j.v)
        list[#list+1] = cell

        -- local go = GameObject.Instantiate(self.cell)
        -- go:SetActive(true)
        -- t = go.transform       
        -- t.parent = self.awardgrid.transform
        -- t.localScale = Vector3.New(0.9, 0.9, 0.9)
        -- t.localPosition = Vector3.zero
        -- local it = ObjPool.Get(UIItemCell)
        -- it:Init(go)
        -- it:UpData(j.k, j.v)
        -- list[#list+1] = it
    end
    self.awardgrid:Reposition()
end

function My:OnClickPay()
    --UITip.Log("功能暂未开发")
    VIPMgr.OpenVIP(1)
    UIEvrDayPay.CloseM()
end

function My:OnClickGet()
    local id = self.cfg.id
    EvrDayMgr:ReqGetReward(id)
end

function My:InitBtnState(index)
    local val = EvrDayInfo.PayAdDic[index]
    if val==nil then val=1 end
    if val==1 then
        self:PayState()
    elseif val==2 then
        self:GetState()
    elseif val==3 then
        self:HadState()
    end
end

function My:PayState()
    self.BtnLab.text = "立即充值"
    UITool.SetLsnrClick(self.root, "GetAdBtn", self.Name, self.OnClickPay, self)
    self:SetBtnNormal()
end

function My:GetState()
    self.BtnLab.text = "领取"
    UITool.SetLsnrClick(self.root, "GetAdBtn", self.Name, self.OnClickGet, self)
    self:SetBtnNormal()
end

function My:HadState()
    self.BtnLab.text = "已领取"
    UITool.SetGray(self.Btn)
end

function My:SetBtnNormal()
    local wdg = self.Btn:GetComponent(typeof(UIWidget))
    local box = self.Btn:GetComponent(typeof(BoxCollider))
    if box then box.enabled = true end
    if wdg == nil then return end
    local color = wdg.color
    color.r = 1
    wdg.color = color
end

function My:CleanData()
    -- self:ClearIcon()
    if self.AwardGrid.childCount > 0 then
        TransTool.ClearChildren(self.AwardGrid)
    end
end

function My:ClearIcon()
    if self.itList then
        for k,v in pairs(self.itList) do
            -- GameObject.Destroy(v.trans.gameObject)
            v:DestroyGo()
            ObjPool.Add(v)
            self.itList[k] = nil
        end
    end
end

function My:Clear()
    self.awardgrid = nil
    self.AwardGrid = nil
    self.cell = nil
    self.Btn = nil
    self.BtnLab = nil
end

function My:Dispose()
    self:Clear()
end

return My