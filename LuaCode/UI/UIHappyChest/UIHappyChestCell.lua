
UIHappyChestCell = Super:New{Name = "UIHappyChestCell"}

require("UI/UIHappyChest/HappyChestRewardCell")

local My = UIHappyChestCell

function My:Ctor()
    self.cellList = {}
end

function My:Init(go)
    local trans , des = go.transform, self.Name
    local TFC = TransTool.FindChild
    local TF = TransTool.Find
    local CG = ComTool.Get
    local USB = UITool.SetBtnClick

    self.go = go
    self.curRrdSprite = TF(trans, "curSprite")
    self.openSprite = TF(trans, "openSprite")
    self.closeSprite = TF(trans, "closeSprite")
    self.grid = CG(UIGrid, trans, "Grid")
    self.rewardCellPrefab = TFC(self.grid.transform, "Cell")
    self.rewardCellPrefab:SetActive(false)
    self.btn = TF(trans, "btnGet")
    self.labBtn = CG(UILabel, trans, "btnGet/Label")
    self.redPoint = TF(trans, "btnGet/red")
    self.fxBox = TF(trans,"fx")
    self.fxBtn = TF(trans, "btnGet/FX_UI_Button")

    USB(trans, "btnGet", des, self.OnClickBtn, self) --点击按钮
    self:SetEvent("Add")
end

function My:UpdateBtnState(rewardData)
    local state = 0
    for i = 1, #rewardData do
        if self.rewardID == rewardData[i].id then
            state = rewardData[i].val
        end
    end
    local labBtn = self.labBtn
    if state == 0 then
        self:UpRedPoint(state)
        self:SetFX(state)
        self.fxBtn.gameObject:SetActive(true)
        self.btnState = 0
        labBtn.fontSize = 22
        labBtn.text = string.format("充值满%s元\n可领取", self.data.payCondition)
    elseif state == 1 then
        self:UpRedPoint(state)
        self:SetFX(state)
        self.fxBtn.gameObject:SetActive(false)
        self.btnState = 1
        labBtn.fontSize = 26
        labBtn.text = "可领取"
        self.redPoint.gameObject:SetActive(true)
    elseif state == 2 then
        self:UpRedPoint(state)
        self:SetFX(state)
        self.fxBtn.gameObject:SetActive(false)
        self.btnState = 2
        labBtn.fontSize = 26
        local r, g, b = 27 / 255, 158 / 255, 27 / 255
        local color = Color.SetVar(r, g, b)
        labBtn.color = color
        labBtn.text = "已领取"
        UITool.SetGray(self.btn)
    end
end

function My:SetFX(state)
    local fxBox = self.fxBox
    if state == 0 or state == 1 then
        fxBox.gameObject:SetActive(true)
    elseif state == 2 then
        fxBox.gameObject:SetActive(false)
    end
end

function My:UpRedPoint(state)
    local redPoint = self.redPoint
    if state == 0 then
        redPoint.gameObject:SetActive(false)
    elseif state == 2 then
        redPoint.gameObject:SetActive(false)
    elseif state == 1 then
        redPoint.gameObject:SetActive(true)
    end
end

--点击MsgBox的充值按钮
function My:YesCb()
    VIPMgr.OpenVIP(1)
end
--点击MsgBox的取消按钮
function My:NoCb()
    return ;
end

function My:OnClickBtn()
    local btnState = self.btnState
    if btnState == 0 then
        MsgBox.ShowYesNo("未达到领取条件，是否前往充值",self.YesCb,self,"充值",self.NoCb,self,"取消");
    elseif btnState == 1 then
        local id = self.rewardID
        HappyChestMgr:ReqGet(id)
    end
end

function My:SetEvent(func)
    local mgr = HappyChestMgr
    mgr.eUpBtns[func](mgr.eUpBtns, self.UpdateBtnState, self)
    mgr.eUpBox[func](mgr.eUpBox, self.UpdateBoxData, self)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function My:OnAdd(action,dic)
    if action==10442 then
        self.dic=dic
        UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
    end
end

--显示奖励的回调方法
function My:RewardCb(name)
    local ui = UIMgr.Get(name)
    if(ui)then
        ui:UpdateData(self.dic)
    end
end

function My:UpdateData(data, rewardData, id)
    if not data  then  return end
    self.data = data
    self.rewardID = id
    self:UpdateBtnState(rewardData)
    self:UpdateCells()
    self:UpdateBoxData()
end

-- 更新宝箱状态
function My:UpdateBoxData()
    local state = self.btnState
    if state == 0 then
        self:UpdateBox(false)
    elseif state == 1 or state == 2 then
        self:UpdateBox(true)
    end
end

--根据参数改变当前宝箱状态
function My:UpdateBox(canGet)
    self.openSprite.gameObject:SetActive(canGet)
    self.closeSprite.gameObject:SetActive(not canGet)
end

-- 更新奖励Cells
function My:UpdateCells()
    local data = self.data.award
    local list = self.cellList
    local len = #data
    for i = 1, len do
        local go = Instantiate(self.rewardCellPrefab)
        TransTool.AddChild(self.grid.transform, go.transform)
        local cell = ObjPool.Get(HappyChestRewardCell)
        cell:Init(go)
        cell:SetActive(true)
        cell:UpdateData(data[i])
        table.insert(list, cell)
    end
    self.grid:Reposition()
end

function My:Dispose()
    self.data = nil
    self.rewardID = 0
    self.btnState = nil

    self:SetEvent("Remove")
    TableTool.ClearUserData(self)
    TableTool.ClearDicToPool(self.mCellList)
end

return My