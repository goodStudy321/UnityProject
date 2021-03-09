PracRewIt = Super:New{Name = "PracRewIt"}
local My = PracRewIt

function My:Init(obj)
    self.Gbj = obj.gameObject
    local trans = obj.transform
    local name = trans.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
	local US = UITool.SetLsnrSelf
	
	local comIt = TF(trans,"comIt",name)
	self.comRed = TFC(comIt,"red",name)
	self.comMask0 = TFC(comIt,"mask0",name)
	self.comMask = TFC(comIt,"mask",name)
	self.comFlag = TFC(comIt,"flag",name)
	self.comRewBtn = TFC(comIt,"rewardBtn",name)
    self.comRewGrid = CG(UIGrid,comIt,"Grid",name)
    self.comWg = CG(UIWidget,comIt,"fx",name)

	local lvIt = TF(trans,"lvIt",name)
	self.lvLab = CG(UILabel,lvIt,"lvLab",name)

	local spcIt = TF(trans,"spcIt",name)
	self.spcRed = TFC(spcIt,"red",name)
	self.spcMask0 = TFC(spcIt,"mask0",name)
	self.spcMask = TFC(spcIt,"mask",name)
	self.spcFlag = TFC(spcIt,"flag",name)
	self.spcRewBtn = TFC(spcIt,"rewardBtn",name)
	-- self.spcRewBox = CG(BoxCollider,"rewardBtn",name)
    self.spcRewGrid = CG(UIGrid,spcIt,"Grid",name)
    self.spcWg = CG(UIWidget,spcIt,"fx",name)

	self.lvId = 0
	self.comRewIndex = 0
	self.spcRewIndex = 0

	self.comRewardTab = {}
	self.spcRewardTab = {}

	US(self.comRewBtn,self.GetComRewBtn,self,name,false)
	US(self.spcRewBtn,self.GetSpcRewBtn,self,name,false)
end

function My:GetComRewBtn()
	local id = self.lvId
	local index = self.comRewIndex
	if index == 1 then
		PracSecMgr:ReqPracReward(id,1)
	end
end

function My:GetSpcRewBtn()
	local id = self.lvId
	local index = self.spcRewIndex
	if index == 3 then
		PracSecMgr:ReqPracReward(id,2)
	end
end

function My:SetActive(ac)
    self.Gbj:SetActive(ac)
end

function My:UpdateData(data)
	local id = data.id
	local lv = data.lv
	self.lvId = id
    local comRewTab = data.comRew
    local spcRewTab = data.specRew
    self:LoadComEff()
    self:LoadSpcEff()
	self:RefreshComReward(comRewTab)
	self:RefreshSpcReward(spcRewTab)
	self:RefrshComInfo(lv)
    self:RefrshSpcInfo(lv)
    self.lvLab.text = lv .. "级"
end

function My:LoadComEff()
    if self.comEff then
        return
    end
	Loong.Game.AssetMgr.LoadPrefab("FX_UI_Button_Square", GbjHandler(self.LoadComEnd,self))
end

function My:LoadSpcEff()
    if self.spcEff then
        return
    end
	Loong.Game.AssetMgr.LoadPrefab("FX_UI_Button_Rectangle", GbjHandler(self.LoadSpcEnd,self))
end

function My:LoadComEnd(go)
    local root = self.comRed.transform
    self.comEff = go
    go.transform:SetParent(root)
    go.transform.localPosition = Vector3.New(-70,-64,0)
    -- go.transform.localScale = Vector3.one
    -- local eff = go:GetComponent(typeof(UIEffBinding))
    -- eff.specifyWidget = self.comWg
    go:SetActive(true)
end

function My:LoadSpcEnd(go)
    local root = self.spcRed.transform
    self.spcEff = go
    go.transform:SetParent(root)
    go.transform.localPosition = Vector3.New(-65,-123,0)
    -- go.transform.localScale = Vector3.one
    -- local eff = go:GetComponent(typeof(UIEffBinding))
    -- eff.specifyWidget = self.spcWg
    go:SetActive(true)
end

function My:UnloadComEff()
	if self.comEff then 
        AssetMgr:Unload(self.comEff.gameObject.name, ".prefab", false)
		Destroy(self.comEff)
	end
	self.comEff = nil
end

function My:UnloadSpcEff()
	if self.spcEff then 
        AssetMgr:Unload(self.spcEff.gameObject.name, ".prefab", false)
		Destroy(self.spcEff)
	end
	self.spcEff = nil
end

--index : 0:不可领   1：凡品可领  2：仙品可领但未充值  3：仙品可领  4:已领
function My:RefrshComInfo(lv)
	local index = PracSecMgr:IsCanRew(1,lv)
	self.comFlag:SetActive(index == 4)
	self.comMask0:SetActive(index == 0)
	self.comMask:SetActive(index == 4)
	self.comRed:SetActive(index == 1)
	self.comRewBtn:SetActive(index == 1)
	self.comRewIndex = index
end

--index : 0:不可领   1：凡品可领  2：仙品可领但未充值  3：仙品可领  4:已领
function My:RefrshSpcInfo(lv)
	local index = PracSecMgr:IsCanRew(2,lv)
	self.spcFlag:SetActive(index == 4)
	self.spcMask0:SetActive(index == 0)
	self.spcMask:SetActive(index == 4)
	self.spcRed:SetActive(index == 3)
	self.spcRewBtn:SetActive(index == 3)
	self.spcRewIndex = index
end

function My:RefreshComReward(reward)
    local data = reward
    local len = #data
    local itemTab = self.comRewardTab
    local count = #itemTab
    local max = count >= len and count or len
    local min = count + len - max
    for i = 1,max do
        if i <= min then
            itemTab[i]:UpData(data[i].k,data[i].v)
            -- itemTab[i]:UpBind(1)
            itemTab[i]:SetActive(true)
        elseif i <= count then
            itemTab[i]:SetActive(false)
        else
            local item = ObjPool.Get(UIItemCell)
            item:InitLoadPool(self.comRewGrid.transform)
            item:UpData(data[i].k,data[i].v)
            -- item:UpBind(1)
            table.insert(self.comRewardTab,item)
        end
    end
    self.comRewGrid:Reposition()
end

function My:RefreshSpcReward(reward)
    local data = reward
    local len = #data
    local itemTab = self.spcRewardTab
    local count = #itemTab
    local max = count >= len and count or len
    local min = count + len - max
    for i = 1,max do
        if i <= min then
            itemTab[i]:UpData(data[i].k,data[i].v)
            -- itemTab[i]:UpBind(1)
            itemTab[i]:SetActive(true)
        elseif i <= count then
            itemTab[i]:SetActive(false)
        else
            local item = ObjPool.Get(UIItemCell)
            item:InitLoadPool(self.spcRewGrid.transform)
            item:UpData(data[i].k,data[i].v)
            -- item:UpBind(1)
            table.insert(self.spcRewardTab,item)
        end
    end
    self.spcRewGrid:Reposition()
end

function My:Dispose()
	self.lvId = 0
	self.comRewIndex = 0
	self.spcRewIndex = 0
    TableTool.ClearListToPool(self.comRewardTab)
    TableTool.ClearListToPool(self.spcRewardTab)
    self:UnloadComEff()
    self:UnloadSpcEff()
    TableTool.ClearUserData(self)
end