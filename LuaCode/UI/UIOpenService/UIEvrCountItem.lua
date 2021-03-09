--[[
    每日累充的次数实例
]]

UIEvrCountItem = Super:New{Name = "UIEvrCountItem"}
local My = UIEvrCountItem

function My:Init(go, cfg, index)
    local trans = go.transform
    self.root = trans
    local CG = ComTool.Get
    local F = TransTool.Find
    local TF = TransTool.FindChild
    local des = self.Name
    self.cfg = cfg
    self.index = index
    self.itList = {}

    self.CouLab = CG(UILabel, trans, "CouLab", des)
    self.DayLab = CG(UILabel, trans, "CouLab/Label", des)
    self.Btn = F(trans, "GetCouBtn", des)
    self.Btn1 = TF(trans, "GetedBtn", des)
    -- self.BtnSpr = CG(UISprite, trans, "GetCouBtn", des)
    -- self.BtnLab = CG(UILabel, trans, "GetCouBtn/Label", des)
    self.cell = TF(trans, "ItemCell", des)
    self.cell.gameObject:SetActive(false)
    self.CouItem = CG(UIWidget, trans, "CouItem", des)

    self:InitSelf(cfg, trans, des)
end

function My:InitSelf(cfg, root, des)
    self:InitItem(cfg, root, des)
    self:InitCountLab(cfg)
    self:InitBtnState(cfg)
end

function My:InitItem(cfg, root, des)
    local list = self.itList
    for i,j in ipairs(cfg.award) do

        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.CouItem.transform,0.8)
        cell:UpData(j.k, j.v)
        list[#list+1] = cell

        -- local go = GameObject.Instantiate(self.cell)
        -- go:SetActive(true)
        -- t = go.transform
        -- t.parent = self.CouItem.transform
        -- t.localScale = Vector3.New(0.8, 0.8, 0.8)
        -- t.localPosition = Vector3.zero
        -- local it = ObjPool.Get(UIItemCell)
        -- it:Init(go)
        -- it:UpData(j.k, j.v)
        -- list[#list+1] = it
    end
end

function My:InitCountLab(cfg)
    local count = cfg.id
    local amount = cfg.amount
    self.CouLab.text = string.format("累计%s天\n充值%s元宝", count, amount)
    local day = 0
    local dic = EvrDayInfo.CountAdDic
    for i,j in ipairs(dic) do
        if j>1 then
            day = day+1
        end
    end
    if day >= count then
        self.DayLab.text = string.format("（[00C92BFF]%d/%d[-]）", day, count)
    else
        self.DayLab.text = string.format("（[FF0000FF]%d/%d[-]）", day, count)    
    end
end

function My:InitBtnState(cfg)
    local val = EvrDayInfo.CountAdDic[cfg.id]
    if val==nil then val=1 end
    if val==1 then
        self:NoState()
    elseif val==2 then
        self:CanState()
    elseif val==3 then
        self:HadState()
    end
end

function My:OnClickGet()
    EvrDayMgr:ReqGetCountReward(self.index)
    -- self:HadState()
    -- EvrDayInfo.CountAdDic[self.index] = 3
end

function My:NoState()
    UITool.SetGray(self.Btn)
    self:ChangeBtnIcon(true)
end

function My:CanState()
    self:ChangeBtnIcon(true)
    UITool.SetLsnrClick(self.root, "GetCouBtn", self.Name, self.OnClickGet, self)
    local wdg = self.Btn:GetComponent(typeof(UIWidget))
    local box = self.Btn:GetComponent(typeof(BoxCollider))
    if box then box.enabled = true end
    if wdg == nil then return end
    local color = wdg.color
    color.r = 1
    wdg.color = color
end

function My:HadState()
    local box = self.Btn:GetComponent(typeof(BoxCollider))
    if box then box.enabled = false end
    self:ChangeBtnIcon(false)
end

function My:ChangeBtnIcon(isAct)
    -- local spr = self.BtnSpr
    -- local lab = self.BtnLab
    -- if isAct then
    --     lab.text = "领取"
    --     spr.spriteName = "btn_receive_none"
    -- else
    --     lab.text = ""
    --     spr.spriteName = "word_seal"
    -- end
    self.Btn.gameObject:SetActive(isAct)
    self.Btn1:SetActive(not isAct)
end

-- function My:ClearIcon()
--     if self.itList then
--         for k,v in pairs(self.itList) do
--             v:UnloadTex()
--         end
--     end
-- end

function My:ClearItem()
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
    self.CouLab = nil
    self.DayLab = nil
    self.Btn = nil
    -- self.BtnSpr = nil
    -- self.BtnLab = nil
    self.cell = nil
    self.CouItem = nil
end

function My:Dispose()
    self:ClearItem()
    self:Clear()
end