--[[
 	authors 	:Liu
 	date    	:2018-4-10 15:09:28
 	descrition 	:活跃度奖励项
--]]

UILiveAwardIt = Super:New{Name="UILiveAwardIt"}

local My = UILiveAwardIt

local BoxCollider = UnityEngine.BoxCollider

--初始化奖励物品
function My:Init(root, cfg)
    local des = self.Name

    self.root = root
    self.cfg = cfg

    self.label = ComTool.GetSelf(UILabel, root)
    self.collider = ComTool.Get(BoxCollider, root, "AwardItem")
    self.awardTran = TransTool.Find(root, "AwardItem", des)
    self.eff = TransTool.FindChild(root, "FX_UI_Button_01", des)
    self.sprite = ComTool.GetSelf(UISprite , self.awardTran.transform);
    self.sprite.depth = 33;
    UITool.SetBtnClick(root, "AwardItem", des, self.OnItemClick, self)

    self:InitCell()
    self:InitLab()
    self:SetMaskState(false)
end

--初始化Cell
function My:InitCell()
    for i,v in ipairs(self.cfg.award) do
        self.cell = ObjPool.Get(UIItemCell)
        self.cell:InitLoadPool(self.awardTran, 0.8)
        self.cell:UpData(v.k, v.v, false)
        UITool.SetAllGray(self.awardTran, true)
    end
end

--点击奖励物品
function My:OnItemClick()
    local id = self.cfg.id
    local info = LivenessInfo
    if info.liveness < id then return end
    local key = tostring(id)
    if info.awardDic[key] then
        UITip.Log("奖励已领取")
        return
    end
    LivenessMgr:ReqGetAWard(id)
end

--初始化文本
function My:InitLab()
    local id = self.cfg.id
    local isHig = LivenessInfo.liveness >= id
    local color = (isHig) and "[F39800FF]" or "[B1A495FF]"
    self.label.text = string.format("%s%s", color, id)
end

--高亮状态
function My:BrightState()
    local id = self.cfg.id
    local key = tostring(id)
    local info = LivenessInfo
    if info.liveness >= id and not info.awardDic[key] then
        UITool.SetAllNormal(self.awardTran)
        self.label.text = string.format("[F39800FF]%s", id)
        self:SetEffState(true)
    elseif LivenessInfo.awardDic[key] then
        self:GetedState()
    end
end

--已领取状态
function My:GetedState()
    UITool.SetAllNormal(self.awardTran)
    self:SetMaskState(false)
    self:SetEffState(false)
end

--设置遮罩状态
function My:SetMaskState(state)
    self.collider.enabled = state
end

--设置特效状态
function My:SetEffState(state)
    self.eff:SetActive(state)
end

--清理缓存
function My:Clear()
    AssetMgr:Unload(self.eff.name, false)
    Destroy(self.eff)
end

--释放资源
function My:Dispose()
    self:Clear()
    UITool.SetAllNormal(self.root.gameObject)
    self.cell:DestroyGo()
    ObjPool.Add(self.cell)
    self.cell = nil
end

return My