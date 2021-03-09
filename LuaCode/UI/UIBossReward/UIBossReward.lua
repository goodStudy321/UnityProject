UIBossReward = UIBase:New{Name = "UIBossReward"}

require("UI/UIBossReward/BossRewardCell")

local M = UIBossReward

M.bossList = {}
M.cellList = {}

function M:InitCustom()
    local trans = self.root
    local FC = TransTool.FindChild
    local SC = UITool.SetLsnrClick
    local G = ComTool.Get

    self.des = G(UILabel, trans, "Des")
    self.progress = G(UILabel, trans, "Progress")
    self.bGrid = G(UIGrid, trans, "BossList")
    self.prefab = FC(self.bGrid.transform, "Item")
    self.prefab:SetActive(false)
    self.rGrid = G(UIGrid, trans, "ScrollView/Grid")
    self.btnRewrd = FC(trans, "BtnReward")
    self.btnRewardName = G(UILabel, self.btnRewrd.transform, "Name")
    self.fx = FC(self.btnRewrd.transform, "FX_UI_Button")

    SC(trans, "BtnGo", self.Name, self.OnGo, self)
    SC(trans, "BtnReward", self.Name, self.OnReward, self)
    SC(trans, "BtnClose", self.Name, self.Close, self)
    self:Refresh()
    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    BossRewardMgr.eRefresh[key](BossRewardMgr.eRefresh, self.Refresh, self)
    PropMgr.eGetAdd[key](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function M:OnAdd(action,dic)
    if action == 10376 then
		self.dic=dic
		UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
    end
end

--显示奖励的回调方法
function M:RewardCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:UpdateData(self.dic)
	end
end

function M:Refresh()
    self.data = BossRewardMgr:GetCurGold()
    self:UpdateBossList()
    self:UpdateDes()
    self:UpdateReward()
    self:UpdateBtn()
    self:UpdatePro()
end

function M:UpdateBtn()
    if self.data.hadGet == 1 then
        UITool.SetGray(self.btnRewrd)
        self.fx:SetActive(false)
        self.btnRewardName.text = "已完成"
    elseif self.data.curCount >= self.data.count then
        UITool.SetNormal(self.btnRewrd)
        self.fx:SetActive(true)
        self.btnRewardName.text = "领取奖励"
    else
        UITool.SetGray(self.btnRewrd)
        self.fx:SetActive(false)
        self.btnRewardName.text = "不可领取"
    end
end

function M:UpdateBossList()
    local data = self.data.bossList
    local len = #data
    local list = self.bossList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
  
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.prefab)
            TransTool.AddChild(self.bGrid.transform, go.transform)
            local item = ObjPool.Get(BossRewardCell)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.bGrid:Reposition()
end

function M:UpdateDes()
    self.des.text = string.format("[F4DDBDFF]前往[00FF00FF]%s[-]击败[F21919FF]%s[-]级以上的BOSS:[00FF00FF]%s/%s", self.data.address, UIMisc.GetLv(self.data.level), self.data.curCount, self.data.count)
end

function M:UpdatePro()
    local cur, total = BossRewardMgr:GetProgress()
    self.progress.text = string.format("[F4DDBDFF]【任务进度:[00FF00FF]%s/%s[-]】",cur, total)
end

function M:UpdateReward()
    local data = self.data.rewardList
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
            local item = ObjPool.Get(UIItemCell)
            item:InitLoadPool(self.rGrid.transform)
            item:UpData(data[i].k, data[i].v)
            table.insert(list, item)
        end
    end
    self.rGrid:Reposition()
end

function M:OnGo()
    JumpMgr:InitJump(UIBossReward.Name)
    UIBoss.curType = self.data.sceneType
    UIMgr.Open(UIBoss.Name)
end

function M:OnReward()
    BossRewardMgr:ReqBossRewardGet()
end

function M:DisposeCustom()
    self:SetLsnr("Remove")
    TableTool.ClearDicToPool(self.bossList)
    TableTool.ClearListToPool(self.cellList)
    self.data = nil
    self.dic = nil
    self.isDone = nil
end

return M