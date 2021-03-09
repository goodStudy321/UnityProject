
GoodByeSingleCell = Super:New{Name = "GoodByeSingleCell"}

require("UI/UIGoodByeSingle/GoodByeSingleRewardCell")

local My = GoodByeSingleCell

My.mCellList = {}

function My:Init(go)
    local trans = go.transform
    local TFC = TransTool.FindChild
    local TF = TransTool.Find
    local CG = ComTool.Get
    local USB = UITool.SetBtnClick

    self.btnGet = TF(trans, "btnGet")
    self.sprBtnGet = CG(UISprite, trans, "btnGet")
    self.cntGet = TF(trans, "cntGet")
    self.labGet = CG(UILabel, trans, "btnGet/Label")
    self.grid = CG(UIGrid, trans, "Grid")
    self.rwdPrefab = TFC(self.grid.transform, "Cell")
    self.rwdPrefab:SetActive(false)
    self.redPoint = TF(trans, "btnGet/red")

    USB(trans, "btnGet", self.Name, self.OnClickBtn, self)
    self:SetEvent("Add")
end

function My:SetEvent(func)
    local mgr = GoodByeSingleMgr
    mgr.eUpCellBtn[func](mgr.eUpCellBtn, self.UpBtn, self)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function My:OnAdd(action,dic)
    if action==10451 then
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

--刷新cell数据
function My:UpdateData(data)
    if not data  then  return end
    self.data = data
    self.id = data.id
    local id = self.id
    self:UpBtn(id)
    self:UpRewardData()
end

--刷新奖励数据
function My:UpRewardData()
    local dataList = self.data.giftList
    local len = #dataList
    local grid = self.grid
    for i = 1, len do
        local go = Instantiate(self.rwdPrefab)
        local trans = go.transform
        TransTool.AddChild(grid.transform, go.transform)
        trans.localScale = Vector3.one
        trans.localPosition = Vector3.zero
        local cell = ObjPool.Get(GoodByeSingleRewardCell)
        cell:Init(go)
        cell:SetActive(true)
        cell:UpdateData(dataList[i])
        self.mCellList[i] = cell
    end
    self.grid:Reposition()
end

--根据id刷新按钮状态
function My:UpBtn(id)
    if id ~= self.id then
        return
    end
    local mgr = GoodByeSingleMgr
    local btnGet = self.btnGet
    local cntGet = self.cntGet
    local labGet = self.labGet
    local redPoint = self.redPoint
    local btnType = mgr:UpBtnType(id)
    if btnType then
        if btnType.val == 1 then
            btnGet.gameObject:SetActive(true)
            cntGet.gameObject:SetActive(false)
            labGet.text = "领取"
            redPoint.gameObject:SetActive(true)
            --mgr.eRed(true, 4)
        elseif btnType.val == 2 then
            btnGet.gameObject:SetActive(true)
            cntGet.gameObject:SetActive(false)
            labGet.text = "已领取"
            redPoint.gameObject:SetActive(false)
            --local sprBtn = self.sprBtnGet
            --sprBtn.spriteName = "btn_figure_down_activity"
            --local color = Color.SetVar(252, 244, 244)
            --labGet.color = color
            UITool.SetGray(btnGet)
        end
    else
        btnGet.gameObject:SetActive(false)
        cntGet.gameObject:SetActive(true)

    end
end

--点击按钮事件
function My:OnClickBtn()
    local labGet = self.labGet
    if labGet.text == "领取" then
        local mgr = GoodByeSingleMgr
        local id = self.id
        mgr:ResqGet(id)
    end
end


--释放
function My:Dispose()
    self.data = nil
    self.id = nil
    self.dic = nil
    self:SetEvent("Remove")
    TableTool.ClearUserData(self)
    TableTool.ClearDicToPool(self.mCellList)
end

return My