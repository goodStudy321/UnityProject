--[[
 	authors 	:Liu
 	date    	:2019-3-19 11:00:00
 	descrition 	:限时活动界面4
--]]

UIActivMenu4 = Super:New{Name="UIActivMenu4"}

local My = UIActivMenu4

local str = "UI/UITimeLimitActiv/"
require(str.."UIActivMenu4AwardIt")
require(str.."UIActivMenu4CondIt")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local FindC = TransTool.FindChild
    local str1 = "Container/Scroll View/Grid"
    local str2 = "countBg/Scroll View/Grid"
    
    self.itList = {}
    self.mList = {}
    self.go = root.gameObject

    self.timeLab = CG(UILabel, root, "Countdown")
    self.lab = CG(UILabel, root, "countBg/titleBg/lab")
    self.tex = CG(UITexture, root, "countBg/titleBg/tex")
    self.grid1 = CG(UIGrid, root, str1)
    self.grid2 = CG(UIGrid, root, str2)
    self.item1 = FindC(root, str1.."/Cell", des)
    self.item2 = FindC(root, str2.."/item", des)

    self:InitLab()
    self:InitAItem()
    self:InitMItem()
    self:InitTex()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    local it = UITimeLimitActiv
    it.eUpTimer[func](it.eUpTimer, self.RespUpTimer, self)
end

--响应更新计时器
function My:RespUpTimer(remain)
    self.timeLab.text = string.format("[E5B45FFF]活动倒计时:[FFE9BDFF]%s", remain)
end

--初始化贴图
function My:InitTex()
    self.texName = ""
    local info = TimeLimitActivInfo
    local idList = info.idList
    local type = info:GetOpenType()
    if type == idList[1] then
        self.texName = "jump_icon1.png"
    elseif type == idList[2] then
        self.texName = "jump_icon3.png"
    elseif type == idList[3] then
        self.texName = "jump_icon2.png"
    end
    if StrTool.IsNullOrEmpty(self.texName) then return end
    AssetMgr:Load(self.texName, ObjHandler(self.SetIcon, self))
end

--设置贴图
function My:SetIcon(tex)
    if self.tex then
        self.tex.mainTexture = tex
        for i,v in ipairs(self.mList) do
            v:SetIcon1(tex)
        end
    end
end

--初始化文本
function My:InitLab()
    local info = TimeLimitActivInfo
    local mana=info.mana
    self.lab.text = string.format("[EE9A9EFF]当前灵力值:[F39800FF]%s", mana)
end

--初始化奖励项
function My:InitAItem()
    local Add = TransTool.AddChild
    local info = TimeLimitActivInfo
    local list = info:GetCfgList(TimeLimitManaCfg)
    for i,v in ipairs(list) do
        local item = Instantiate(self.item1)
        local tran = item.transform
        Add(self.grid1.transform, tran)
        local it = ObjPool.Get(UIActivMenu4AwardIt)
        it:Init(tran, v)
        table.insert(self.itList, it)
    end
    self.item1:SetActive(false)
    self:UpBtns()
end

--更新按钮
function My:UpBtns()
    local info = TimeLimitActivInfo
    local dic = info:GetBtnState(3)
    for i,v in ipairs(self.itList) do
        local key = tostring(v.cfg.id)
        local state = (dic) and dic[key] or nil
        v:UpBtnState(state)
    end
    self.grid1:Reposition()
end

--初始任务项
function My:InitMItem()
    local Add = TransTool.AddChild
    local info = TimeLimitActivInfo
    local dic = info:GetBtnData(info.manaType)
    if dic == nil then return end
    for k,v in pairs(dic) do
        local cfg = self:GetCfg(tonumber(k))
        if cfg then
            local item = Instantiate(self.item2)
            local tran = item.transform
            item.name = cfg.mType
            Add(self.grid2.transform, tran)
            local it = ObjPool.Get(UIActivMenu4CondIt)
            it:Init(tran, cfg, v)
            table.insert(self.mList, it)
        end
    end
    self.item2:SetActive(false)
end

--根据id获取配置
function My:GetCfg(id)
    for i,v in ipairs(TimeLimitMissionCfg) do
        if v.mType == id then
            return v
        end
    end
    return nil
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--清理缓存
function My:Clear()
    AssetMgr:Unload(self.texName,false)
    ListTool.ClearToPool(self.itList)
    ListTool.ClearToPool(self.mList)
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
end

return My