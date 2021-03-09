--[[
 	authors 	:Liu
 	date    	:2018-11-2 14:30:00
 	descrition 	:仙魂合成界面（Toggles）
--]]

UIImmSoulCompTogs = Super:New{Name = "UIImmSoulCompTogs"}

local My = UIImmSoulCompTogs

local strs = "UI/UIImmortalSoul/UIImmSoulComp/"
require(strs.."UIImmSoulCompTogsIt")

function My:Init(root, list, index)
    local des = self.Name
    local CG = ComTool.Get
    local CGS = ComTool.GetSelf
    local FindC = TransTool.FindChild
    local SetS = UITool.SetLsnrSelf
    local ED = EventDelegate

    local lab1 = CG(UILabel, root, "lab1")
    local lab2 = CG(UILabel, root, "lab2")
    local item = FindC(root, "Tween/Grid/item", des)
    SetS(root, self.OnTog, self, des)
    self.up = FindC(root, "up", des)
    self.down = FindC(root, "down", des)
    self.table = CG(UITable, root, "Tween/Grid")
    self.tog = CGS(UIToggle, root, des)
    self.playTween = CGS(UIPlayTween, root, des)
    ED.Add(self.playTween.onFinished, ED.Callback(self.Complete, self))
    self.index = index
    -- self.isInit = true
    self.itList = {}
    self.go = root.gameObject
    self:InitLab(index, lab1, lab2)
    self:InitTogs(item, list)
end

--点击Tog
function My:OnTog(go)
    self:UpSprState()
    ImmortalSoulInfo:SetTogIndex(self.index)
end

--初始化文本
function My:InitLab(index, lab1, lab2)
    local info = ImmortalSoulInfo
    lab1.text = info.compTypeList[index]
    lab2.text = info.compTypeList[index]
end

--更新贴图状态
function My:UpSprState()
    local state = self.up.activeSelf
    self.down:SetActive(state)
    self.up:SetActive(not state)
end

--初始化所有Tog
function My:InitTogs(item, list)
    local Add = TransTool.AddChild
    local parent = item.transform.parent
    for i,v in ipairs(list) do
        local go = Instantiate(item)
        local tran = go.transform
        local it = ObjPool.Get(UIImmSoulCompTogsIt)
        local key = tostring(v)
        local compCfg = ImmSoulCompCfg[key]
        local num = compCfg.sortId + 1000
        go.name = num
        Add(parent, tran)
        if compCfg == nil then return end
        it:Init(tran, compCfg, num)
        table.insert(self.itList, it)
    end
    table.sort(self.itList, function (a,b) return a.num < b.num end)
    for i,v in ipairs(self.itList) do
        v:SetIndex(i)
        -- if i == 1 and self.index == 1 then
        --     v:SetTogState(true)
        -- end
    end
    item:SetActive(false)
end

--重置Tog状态
-- function My:ResetTog()
--     if self.index == 1 and self.isInit then
--         self.itList[1]:SetTogState(false)
--         self.isInit = false
--     end
-- end

--快捷打开分页
function My:OpenTab(tabIndex)
    self:UpSprState()
    self.playTween:Play(true)
    for i,v in ipairs(self.itList) do
        if v.index == tabIndex then
            v:SetTogState(true)
        end
        v:SetAlpha(0)
    end
end

--响应动画播放完成
function My:Complete()
    for i,v in ipairs(self.itList) do
        v:SetAlpha(v.alpha)
    end
    self.table:Reposition()
    self.tog.value = true
    local ED = EventDelegate
	ED.Remove(self.playTween.onFinished, ED.Callback(self.Complete, self))
end

--清理缓存
function My:Clear()
	-- self.isInit = true
end

--释放资源
function My:Dispose()
    self:Clear()
    ListTool.ClearToPool(self.itList)
    if self.go then
        Destroy(self.go)
    end
end

return My