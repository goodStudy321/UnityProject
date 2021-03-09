require("UI/Robbery/UIListSpModItem")
local SMIT = UIListSpModItem

SpItemCom = SpiriteModItem:New{Name = "SpItemCom"}

local My = SpItemCom
--点击事件 data:战灵基础配置信息(SpiriteCfg), lv:当前战灵等级
--根据战灵id和战灵等级可获取战灵登记表信息 
--战灵等级表配置：SpiriteLvCfg
--获取等级配置方法：Robbery:GetCurSpiriteCfg(spId,lv)   参数--->spId:战灵id   lv:战灵等级
My.eClickCell = Event()
--当前战灵ID
My.curSpirId = 0;

--item：战灵模板prefab
--grid:模板prefab父节点
--modParent：模型父节点
--self.items：模板prefab列表  k:战灵Id, v:prefab组件信息
function My:Init(item,grid,modParent)
    self.item = item
    self.gridItem = grid
    self.modelRoot = modParent
    self.items = {}
    self:InitSpiriteItem()
end

function My:InitSpiriteItem()
    local item = self.item
    local Inst = GameObject.Instantiate
    local robSevInfo = RobberyMgr.SpiriteInfoTab
    local tabTemp = {}
    for k,v in pairs(SpiriteCfg) do
        table.insert(tabTemp,v)
    end
    table.sort(tabTemp,function(a,b) return a.spiriteId < b.spiriteId end)
    local len = #tabTemp
    for i = 1,len do
        local go = Inst(item)
        local date = tabTemp[i]
        self:AddItem(date,go,robSevInfo)
    end
    self.gridItem:Reposition()
end

function My:AddItem(info,go,robSevInfo)
    if go == nil then return end
    local trans = go.transform
    local it = ObjPool.Get(SMIT)
    it:Init(go)
    it.root.name = info.spiriteId
    go.gameObject:SetActive(true)
    local modId = tostring(info.spiriteId)
    self.items[modId] = it
    TransTool.AddChild(self.gridItem.transform,trans)
    UITool.SetLsnrSelf(trans, self.OnClickItem, self, nil, false)
    it:InitData(info)
    if robSevInfo.spiriteTab ~= nil and robSevInfo.spiriteTab[info.spiriteId] ~= nil then
        it:SetLock(false)
    end
end

--选中默认战灵
function My:SltDefault()
    local spId = self.curSpirId
    if spId == nil or spId == 0 then    --默认选中第一个
        self:OnClickItem(self.items["10101"].root) 
    else
        self:OnClickItem(self.items[tostring(spId)].root) --默认选中传入
    end
end

function My:OnClickItem(go)
    local modRoot = self.modelRoot
    local key = go.name
	local item = self.items[key]
	if not item then return end
	if self.SelectItem then
        self.SelectItem:IsSelect(false)
        self.SelectItem:SetActive(false,self.curClickSpCfg.uiMod,modRoot)
	end
    self.curClickSpCfg = SpiriteCfg[key]
	self.SelectItem = item
    self.SelectItem:IsSelect(true)
	local data = SpiriteCfg[key]
    if not data then return end
    --模型显示
    item:SetActive(true,data.uiMod,modRoot)
    local spId = data.spiriteId
    --true:未解锁  false:已解锁
    local isLock = RobberyMgr:IsLockSp(spId)
    local spiriteInfo = RobberyMgr.SpiriteInfoTab
    local lv = 1
    if isLock == false then
        lv = spiriteInfo.spiriteTab[spId].lv
    else
        lv = 1
    end
    self:SetName(modRoot,data.name,lv)
    self.curSpirId = spId;
    self.eClickCell(data,lv)
end

function My:SetName(modRot,name,curLv)
    local trans = modRot.transform
    local CG = ComTool.Get
    local nameLab = CG(UILabel,trans,"curName/lab")
    local lvLab = CG(UILabel,trans,"curName/lvLab") 
    local lvLa = string.format("Lv.%s",curLv)
    nameLab.text = name
    lvLab.text = lvLa
end

--设置战灵红点 
--spId:战灵id,ac:红点状态
function My:SetRed(spId,ac)
    local spId = tostring(spId)
    local item = self.items[spId]
    if not item then return end
    item.actionGo:SetActive(ac)
end

function My:Clear()
    if self.items then
        for k,v in pairs(self.items) do
            v:Dispose()
            ObjPool.Add(v)
            self.items[k] = nil
        end
    end
end

function My:Dispose()
    self:Clear()
    self.item = nil
    self.gridItem = nil
    self.modelRoot = nil
    self.curClickSpCfg = nil
    self.SelectItem = nil
    self.curSpirId = nil;
end

return My