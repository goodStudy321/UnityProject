TreasureRewardBox = UIBase:New{Name = "TreasureRewardBox"}
local My = TreasureRewardBox

function My:InitCustom()
	local msg = "寻宝奖励框"
	local root = self.root
    local CG = ComTool.Get
    local US = UITool.SetBtnClick
    local UC = UITool.SetLsnrSelf
    local TFC = TransTool.FindChild
	self.bg = CG(UISprite, root, "bg", msg)
	local tran = self.bg.transform
	self.msgLbl = CG(UILabel, root, "msg", msg)
	self.noBtn = CG(UIButton, tran, "noBtn", msg)
	self.noLbl = CG(UILabel, tran, "noBtn/Label", msg)
	self.yesBtn = TFC(tran, "yesBtn", msg)
    self.yesLbl = CG(UILabel, tran, "yesBtn/Label", msg)
    self.Grid = CG(UIGrid, root, "Grid", msg)
    self.Tex = CG(UITexture,root, "tex", msg)
    self.cellList = {}
    UC(self.yesBtn,self.OnClickYes,self)
    US(root, "CloseBtn", self.Name, self.OnClickClose, self)
    AssetMgr:Load("qyrk_ad", ".png", ObjHandler(self.SetIcon, self))
    self:UpdateCell()
end


function My:SetIcon(tex)
    if self.Tex then
        self.textName = tex.name
        self.Tex.mainTexture = tex
    end
end

function My.OpenTreasure()
    UIMgr.Open(TreasureRewardBox.Name)
end

function My:OnClickYes()
    self:Close()
    local isPathing = TreasureMapMgr.isPathing
	if isPathing then
        QuickUseMgr.YesCb()
        return
    end
    TreasureMapMgr:OnStartDig()
    UIMgr.Open(UICollection.Name)
end

function My:OnClickClose()
	self:Close()
end

function My:UpdateCell()
    local id = tostring(TreasureMapMgr.usePropId)
    local cfg = TreasureCfg[id]
    local rewards = cfg.rewards
    if rewards == nil then iTrace.eError("GS","请检查【藏宝图】奖励配置") return end
    local len = #rewards
    local list = self.cellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
    local propid = 0
    local propNum = 0
  
    for i=1, max do
        if i <= min then
            propid = rewards[i].k
            propNum = rewards[i].v
            list[i]:UpData(propid,propNum)
            list[i].trans.gameObject:SetActive(true)
        elseif i <= count then
            list[i].trans.gameObject:SetActive(false)
        else
            propid = rewards[i].k
            propNum = rewards[i].v
            local cell = ObjPool.Get(Cell)
            cell:InitLoadPool(self.Grid.transform,0.8)
            cell:UpData(propid,propNum)
            cell.trans.gameObject:SetActive(true)
            table.insert(list, cell)
        end
    end
    self.Grid:Reposition()
end

function My:CloseCustom()

end

function My:DisposeCustom()
    if self.textName then
        AssetTool.UnloadTex(self.textName.name)
        self.textName = nil
    end
    TableTool.ClearListToPool(self.cellList)
end

return My
