ComCell = Super:New{Name = "ComCell"}

local M = ComCell

function M:Ctor()
    self.cellList = {}
end

function M:Init(go)
    local root = go.transform
    local G = ComTool.Get
    local F = TransTool.Find

    self.go = go
    self.des = G(UILabel, root, "Des")
    self.remainCount = G(UILabel, root, "RemainCount")
    self.btn = G(UISprite ,root, "Btn")
    self.box = G(BoxCollider, root, "Btn")
    self.btnName = G(UILabel, self.btn.transform, "Name")
    self.grid = G(UIGrid, root, "Grid")

    UITool.SetLsnrSelf(self.btn, self.OnClick, self)
end

function M:UpdateData(data)
    if not data then return end
    self.data = data
    self.des.text = data.des
    self.remainCount.text = string.format("剩余数量：%s", data.remainCount)
    local state = data.totalCount>0
    self.remainCount.gameObject:SetActive(state)
    self.btn.transform.localPosition = state and Vector3(381,11,0) or Vector3(381,0,0)
    self:UpdateCellData(data.rewardList)
    self:UpdateBtnState(data.state)
end


function M:UpdateBtnState(state)
    if state == 1 then
        self.btnName.text = "[5d5451]领取[-]"
        self.btn.spriteName = "btn_figure_down_avtivity"
        self.box.enabled = false
    elseif state == 2 then
        self.btnName.text = "[772a2a]领取[-]"
        self.btn.spriteName = "btn_figure_non_avtivity"
        self.box.enabled = true
    elseif state == 3 then
        self.btnName.text = "[5d5451]已领取[-]"
        self.btn.spriteName = "btn_figure_down_avtivity"
        self.box.enabled = false
    end
end

function M:UpdateCellData(data)
    local len = #data
    local list = self.cellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max

    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpData(data[i].k, data[i].v)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local cell = ObjPool.Get(UIItemCell)
            cell:InitLoadPool(self.grid.transform)
            cell:UpData(data[i].k, data[i].v)
            table.insert(list, cell)
        end
    end
    self.grid:Reposition()
end

function M:OnClick()
    if not self.data then return end
    local mgr = BenefitMgr
    local page = mgr.CurPage
    if page == mgr.CreatePage then
        mgr:ReqFamilyCreateReward(self.data.id)
    elseif page == mgr.BattlePage then
        mgr:ReqFamilyBattleReward(self.data.id)
    elseif page == mgr.BossPage then
        mgr:ReqHuntBossReward(self.data.id)
    end
end


function M:SetActive(bool)
    if self.go then
        self.go:SetActive(bool)
    end
end

function M:Dispose()
    self.data = nil
    TableTool.ClearUserData(self)
    TableTool.ClearListToPool(self.cellList)
end


return M