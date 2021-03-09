UICopyTowerZH = Super:New{Name = "UICopyTowerZH"}

require("UI/UICopy/CopyBuyView")

local M = UICopyTowerZH

local vMgr = VIPMgr
local cMgr = CopyMgr

function M:Ctor()
    self.starList = {}
    self.cellList = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local F = TransTool.Find
    local S = UITool.SetLsnrSelf

    self.go = go

    self.remainCount = G(UILabel, trans, "RemainCount")
    self.btnAdd = FC(self.remainCount.transform, "BtnAdd")

    local right = F(trans, "Right")
    self.btnEnter = FC(right, "Enter")
    self.floor = G(UILabel, right, "Floor")
    self.curGrid = G(UIGrid, right, "CurGrid")
    self.des = FC(right, "Bg/Des")
    self.eff = FC(trans, "UI_tx_H")

    self.targetGrid = G(UIGrid, trans, "Container/TargetGrid")
    self.lock = FC(trans, "Container/TargetGrid")

    local floorBg = F(trans, "FloorBg")
    self.curFloor = G(UILabel, floorBg, "CurFloor")

    for i=1,3 do
        local star = FC(floorBg, "Star"..i)
        table.insert(self.starList, star)
    end

    self.buyView = ObjPool.Get(CopyBuyView)
    self.buyView:Init(FC(trans, "BuyView"))

  
    S(self.btnAdd, self.OnAdd, self, self.Name, false)
    S(self.btnEnter, self.OnEnter, self, self.Name, false)
    S(self.des, self.OnDes, self, self.Name, false)

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    cMgr.eUpdateCopyData[key](cMgr.eUpdateCopyData, self.UpdateCopyData, self)
end

function M:UpdateCopyData()
    self:UpdateRemainCount()
    self:UpdateBuyView()
end

function M:UpdateBuyView()
	if not self.temp then return end
	self.buyView:UpdateData()
end

function M:OnDes()
    local str = InvestDesCfg["1500"].des
    if not str then return end
    UIComTips:Show(str, Vector3(-152, -290, 0))
end

function M:OnAdd()
    if not self.temp then return end
    if self.buyView then
		self.buyView:Open(self.temp)
	end
end

function M:OnEnter()
    if self.temp then
        SceneMgr:ReqPreEnter(self.temp.id, true, true)
    end
end


function M:UpdateData()
    local data, isOpen, floor = cMgr:GetCurCopy(CopyType.ZHTower)
    if not data then return end
    self.temp = data.Temp
    self:UpdateCurReward()
    self:UpdateTargetReward()
    self:UpdateRemainCount()
    self:UpdateCurFloor(floor)
    self:UpdateStar(data.Star)
end

function M:UpdateStar(star)
    star = star or 0
    local list = self.starList
    for i=1,#list do
        list[i]:SetActive(i<=star)
    end
end

function M:UpdateCurReward()
    --特殊处理，坑爹需求
    local data = {}
    local temp = {}
    temp.k = self.temp.sor3[1].k
    temp.v = self.temp.sor3[1].v + self.temp.sor0[1].v
    data[1] = temp
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
			cell:InitLoadPool(self.curGrid.transform)
			cell:UpData(data[i].k, data[i].v)
			table.insert(list, cell)
        end
    end
    self.curGrid:Reposition()
end

function M:UpdateTargetReward()
    local cfg = ZHTowerPartOpen
    local data = nil
    local copyId = self.temp.id
    for i=1,#cfg do
        if copyId<= cfg[i].copyId then
            data = cfg[i]
            break
        end
    end
    if data then
        self.floor.text = string.format("通关%s层解锁铸魂:%s", data.copyId-50000, data.partName)
        if not self.cell then
            self.cell = ObjPool.Get(UIItemCell)
            self.cell:InitLoadPool(self.targetGrid.transform)
        end
        self.cell:UpData(data.itemId)
    else
        self.floor.text = "已解锁所有铸魂部位"
        self.targetGrid.gameObject:SetActive(false)
        self.lock:SetActive(true)
    end
end

function M:UpdateRemainCount()
    local data = cMgr.Copy[cMgr.ZHTower]
    if not data then return end
    local all = data.Buy + data.itemAdd + self.temp.num 
    local remian = all - data.Num
    self.remainCount.text = string.format("剩余次数:(%s/%s)", remian, all)
end

function M:UpdateCurFloor(floor)
    self.curFloor.text = string.format("第%s层", floor)
end


function M:SetActive(bool)
    self.go:SetActive(bool)
end

function M:Open()
    self:SetActive(true)
    self:UpdateData()
    self:SetEff(true)
end

function M:Close()
    self:SetActive(false)
    self:SetEff(false)
end

function M:SetEff(state)
	self.eff:SetActive(state)
end

function M:Dispose()
    self:SetLsnr("Remove")
    self.temp = nil
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
    end
    self.cell = nil
    ObjPool.Add(self.buyView)
    self.buyView = nil
    TableTool.ClearDic(self.starList)
    TableTool.ClearListToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M