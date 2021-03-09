--[[
 	authors 	:Liu
 	date    	:2018-8-17 12:00:00
 	descrition 	:VIP投资项
--]]

UIVIPInvestItem = Super:New{Name="UIVIPInvestItem"}

local My = UIVIPInvestItem

function My:Init(root, cfg)
    local CG, des = ComTool.Get, self.Name
    local FindC = TransTool.FindChild
    local item = FindC(root, "Grid/item", des)
    self.tipLab = CG(UILabel, root, "Tips")
    self.getBtn = FindC(root, "BtnGet", des)
    self.getSpr = FindC(root, "HadGet", des)
    self.btnSpr = CG(UISprite, root, "BtnGet", des)
    self.btnLab = CG(UILabel, root, "BtnGet/lab", des)
    self.go = root.gameObject
    self.cfg = cfg
    self.cellList = {}
    UITool.SetBtnSelf(self.getBtn.transform, self.OnGetBtn, self, des)
    self:UpBtnState()
    self:InitItem(item)
end

--更新按钮状态
function My:UpBtnState()
    local mgr = VIPInvestMgr
    local days = mgr.rDays
    local now = mgr.nowDay
    local cfg = self.cfg
    if mgr.isReset then self:HideBtn(true, false) end
    local index = cfg.id % 100
    if now > index then
        self:HideBtn(false, true)
        self.go.name = cfg.id + 2000
    elseif now < index then
        CustomInfo:SetBtnState(self.getBtn, false)
        self.btnSpr.spriteName = "btn_figure_down_avtivity"
        self.btnLab.text = "[5d5451]领取[-]"
    else
        if mgr.isAward then
            self:HideBtn(false, true)
            self.go.name = cfg.id + 2000
        else
            CustomInfo:SetBtnState(self.getBtn, true)
            self.btnSpr.spriteName = "btn_figure_non_avtivity"
            self.btnLab.text = "[772a2a]领取[-]"
        end
    end
    self.tipLab.text = "[ee9a9e]投资后第[00ff00]"..index.."[-]天领取"
end

--初始化奖励项
function My:InitItem(item)
    local Add = TransTool.AddChild
    local parent = item.transform.parent
    for k,v in pairs(self.cfg.awards) do
        local go = Instantiate(item)
        local tran = go.transform
        Add(parent, tran)
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(tran, 0.8)
        cell:UpData(v.k, v.v)
        table.insert(self.cellList, cell)
    end
    item:SetActive(false)
end

--隐藏按钮
function My:HideBtn(state1, state2)
    self.getBtn:SetActive(state1)
    self.getSpr:SetActive(state2)
end

--点击领取按钮
function My:OnGetBtn()
    VIPInvestMgr:ReqGetAward()
end

--清理缓存
function My:Clear()
    self.cfg = nil
    TableTool.ClearUserData(self)
end
    
--释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearListToPool(self.cellList)
end

return My