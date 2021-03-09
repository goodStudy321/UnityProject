--[[
 	authors 	:Liu
 	date    	:2018-11-1 14:10:00
 	descrition 	:仙魂佩戴界面（背包）
--]]

UIImmSoulWearMod1 = Super:New{Name = "UIImmSoulWearMod1"}

local My = UIImmSoulWearMod1

local AssetMgr = Loong.Game.AssetMgr

local strs = "UI/UIImmortalSoul/UIImmSoulWear/"
require(strs.."UIImmSoulBagIt")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local FindC = TransTool.FindChild
    local SetB = UITool.SetBtnClick
    local str = "bag/Scroll View/Grid"

    local grid = Find(root, str, des)
    local item = FindC(root, str.."/item", des)
    SetB(root, "btn1", des, self.OnComp, self)
    SetB(root, "btn2", des, self.OnDecomp, self)
    self.dAction = FindC(root, "btn2/Action", des)
    self.debris = CG(UILabel, root, "debris/lab")
    self.stone = CG(UILabel, root, "stone/lab")
    self.cellNum = 200
    self.itList = {}
    self.indexList = {}
    self:UpLab()
    self:InitCell(grid, item)
    self:InitBag()
end

--初始化背包
function My:InitBag()
    local info = ImmortalSoulInfo
    local topList = info:GetTopSoulInBag()
	local dic = {}
	for i,v in ipairs(topList) do
		local key = tostring(v.index)
		dic[key] = true
    end
    for i=5, 1, -1 do
        local list = info:GetQuaList(topList, i)
        for i,v in ipairs(list) do
            local index = self:UpBag(v)
            if index then
                table.insert(self.indexList, index)
                self:CreatePrefab()
            end
        end
    end
    for i=5, 1, -1 do
        local bagList = info.bagList
        local list = info:GetQuaList(bagList, i)
        for i,v in ipairs(list) do
            local key = tostring(v.index)
            local cfg = ImmSoulCfg[tostring(v.soulId)]
            if cfg then
                if not dic[key] and cfg.wearType ~= 0 then
                    self:UpBag(v)
                end
            end
        end
    end
    self:InitDebris(info)
    self:UpAction()
end

--初始化仙魂碎片
function My:InitDebris(info)
    local debrisList = info:GetDebris()
    for i=5, 1, -1 do
        local list = info:GetQuaList(debrisList, i)
        for i,v in ipairs(list) do
            self:UpBag(v)
        end
    end
end

--刷新特效
function My:RefreshEff()
    local topList = ImmortalSoulInfo:GetTopSoulInBag()
    local dic = {}
    for i,v in ipairs(topList) do
        local key = tostring(v.index)
        dic[key] = true
    end
    for i,v in ipairs(self.itList) do
        local key = tostring(v.cellId)
        if dic[key] then
            if v.eff == nil then
                table.insert(self.indexList, i)
                self:CreatePrefab()
            end
        else
            v:ClearEff()
        end
    end
end

--创建特效
function My:CreatePrefab()
    AssetMgr.LoadPrefab("FX_xianhunpd", GbjHandler(self.LoadPrefabCb, self))
end

--加载特效回调
function My:LoadPrefabCb(eff)
    local Add = TransTool.AddChild
    local tran = eff.transform
    for i,v in ipairs(self.indexList) do
        local it = self.itList[v]
        if it.cfg then
            it.eff = eff
            Add(it.root, tran)
        end
        table.remove(self.indexList, i)
        break
    end
end

--更新背包
function My:UpBag(v)
    local baseCfg = ImmSoulCfg
    local key1 = tostring(v.soulId)
    local lvCfg, temp = BinTool.Find(ImmSoulLvCfg, v.lvId)
    if baseCfg[key1] and lvCfg then
        local index = self:IsCell()
        if index == nil then return end
        self.itList[index]:SetData(lvCfg, baseCfg[key1].icon, v.index)
        return index
    end
    return nil
end

--判断是否是空格子
function My:IsCell()
	for i,v in ipairs(self.itList) do
		if v.cfg == nil then
			return i
		end
	end
	return nil
end

--初始化仙魂碎片，仙魂石文本
function My:UpLab()
    local info = ImmortalSoulInfo
    self.debris.text = info.debris
    self.stone.text = info.stone
end

--初始化格子
function My:InitCell(grid, item)
    local Add = TransTool.AddChild
    for i=1, self.cellNum do
        local go = Instantiate(item)
        local tran = go.transform
        Add(grid, tran)
        local it = ObjPool.Get(UIImmSoulBagIt)
        it:Init(tran)
        it:ChangeName(i)
        table.insert(self.itList, it)
    end
    item:SetActive(false)
end

--添加实例
function My:AddIt()
    local info = ImmortalSoulInfo
    local len = #info.bagList
    local index = self:UpBag(info.bagList[len])
    self:RefreshEff()
end

--删除实例
function My:RemoveIt(index)
    for i,v in ipairs(self.itList) do
        if v.cellId == index then
            v:UpIcon(false)
            v:ClearCfg()
            break
        end
    end
    self:RefreshEff()
end

--刷新背包
function My:ResetBag()
	for i,v in ipairs(self.itList) do
		v:UpIcon(false)
		v:ClearCfg()
    end
    self:InitBag()
end

--点击合成
function My:OnComp()
    UIImmortalSoul:UpShow(2)
end

--点击分解
function My:OnDecomp()
    local it = UIImmortalSoul
    it:UpShow(3)
end

--更新红点
function My:UpAction()
    local isDecomp = ImmortalSoulInfo:IsDecomp()
    self.dAction:SetActive(isDecomp)
end

--清理缓存
function My:Clear()

end

--释放资源
function My:Dispose()
    self:Clear()
    ListTool.ClearToPool(self.itList)
end

return My