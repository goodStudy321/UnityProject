--[[
    集字有礼的实例
]]--

UICollItem = Super:New{Name = "UICollItem"}
local My = UICollItem

function My:Init(root, cfg, i)
    local CG = ComTool.Get
    local des = self.Name
    self.root = root
    self.cfg = cfg
    self.index = i
    self.go = root.gameObject

    self.itemgrid = CG(UIGrid, root, "ItemGrid", des, false)
    self.ItemGrid = TransTool.Find(root, "ItemGrid", des)
    self.itList = {}
    self.rewardList = {}
    -- self.ExBtn = CG(UIButton, root, "ExBtn")
    -- self.ExSpr = CG(UISprite, root, "ExBtn")
    self.btn = TransTool.Find(root, "ExBtn")
    self.btnSp = CG(UISprite, root, "ExBtn")
    self.btnName = CG(UILabel, root, "ExBtn/ExLab")
    self.RemainLab = CG(UILabel, root, "RemainLab")
    self.TexLab = CG(UILabel,root, "TexLabel")
    self.ArrowsSpr = CG(UISprite, root, "ArrowsSpr")
    self.ArrowsItem = TransTool.FindChild(root, "ArrowsSpr", des)
    self.cell = TransTool.FindChild(root, "ItemCell", des)

    UITool.SetLsnrSelf(self.btn, self.OnExBtnClick, self)
    
    self:InitSelf(cfg, root, des)
end

--点击兑换按钮
function My:OnExBtnClick()
    CollWordsMgr:ReqGetCollAward(self.index)
    CollWordsMgr:ReqGetAward()
end

--初始化自身
function My:InitSelf(cfg, root, des)
    self.ArrowsItem:SetActive(false)
    local count = self:InitAwardCount(cfg)
    self:UpCountLab(count)
    self:InitCollItem(cfg, root, des)
    self:InitBtnState()
    CollWordsMgr:ReqGetAward()
end

--初始化集字模块
function My:InitCollItem(cfg, root, des)
    local Add = TransTool.AddChild
    local TF = TransTool.Find
    local List = self.itList
    for i,j in ipairs(cfg.use) do
        local id = j.k
        local num = ItemTool.GetNum(id)
        local need = j.v
        local temp = ItemData[tostring(id)]
        if not temp then return end
        -- local go = GameObject.Instantiate(self.cell)
        -- go.name = "60"..tostring(i)
        -- go:SetActive(true)
        -- t = go.transform
        -- t.parent = self.itemgrid.transform
        -- t.localScale = Vector3.New(0.8, 0.8, 0.8)
        -- t.localPosition = Vector3.zero
        local it = ObjPool.Get(UIItemCell)
        -- it:Init(go)
        it:InitLoadPool(self.itemgrid.transform,0.8)
        it:UpData(temp, num)
        it.trans.name = "60"..tostring(i)
        List[#List+1] = it
        if TransTool.Find(root, "ItemGrid", des).childCount < (#cfg.use)+2 then
            self:CountState(root, des, i, num, need)
        end
        
    end
    --加箭头和兑换的奖励
    local item = Instantiate(self.ArrowsItem)
    item:SetActive(true)
    local rewardTab = self.rewardList
    Add(self.ItemGrid, item.transform)
    for i,v in ipairs(cfg.exchange) do
        local tran = TF(root, "ItemGrid", des)
        local it = ObjPool.Get(UIItemCell)
        it:InitLoadPool(tran, 0.8)
        it:UpData(tonumber(v.k))
        rewardTab[#List+1] = it
    end
end

--初始化按钮状态
function My:InitBtnState()
    local use = self.cfg.use
    local sum = self:GetNumMethod(use)
    if sum >= #use then
        if CollWordsInfo.countDic[self.index]>=1 then
            -- self:CanEx()
            self:UpdateBtnState(1)
        else
            -- self:NoEx()     
            self:UpdateBtnState(2)   
        end
    else
        self:UpdateBtnState(2)  
        -- self:NoEx()
    end
end

function My:UpdateBtnState(state)
    local spBtn = self.btnSp
    local spTab = {"btn_figure_non_avtivity","btn_figure_down_avtivity"}
    if state == 1 then  --可兑换
        self.btnName.text = "[772a2a]兑换[-]"
        -- UITool.SetNormal(self.btn)
    elseif state == 2 then  --不可兑换
        self.btnName.text = "[5d5451]兑换[-]"
        -- UITool.SetGray(self.btn)
    end
    spBtn.spriteName = spTab[state]
end

--公用得到道具数量
function My:GetNumMethod(use)
    local sum = 0
    for i,j in pairs(use) do
        local id = j.k
        local num = ItemTool.GetNum(id)
        if num > 0 then
            sum = sum + 1
        end
    end
    return sum
end

--初始化限制数量
function My:InitAwardCount(cfg)
    for i,j in ipairs(cfg.exchange) do
        local key = tostring(j.k)
        if CollWordsInfo.countDic[key] then
            local temp = CollWordsInfo.countDic[key]
            local count = (temp > 0) and temp or 0
            return count
        else
            return cfg.count
        end
    end
end

--更新数量限制文本
function My:UpCountLab(val)
    local cfg = self.cfg
    local type = cfg.type
    if type==1 then
        self.TexLab.text = "今日个人剩余:"
        self.RemainLab.text = val
    else
        self.TexLab.text = "今日全服剩余:"
        self.RemainLab.text = (cfg.count == 0) and "不限" or val
    end
end

--数量文本
function My:CountState(root, des, i, num, need)
    local Lab = ComTool.Get(UILabel, root, "ItemGrid/60"..i.."/Lab")
    if num>=need then
        Lab.text = string.format("[00C92BFF]%d[-]/[00C92BFF]%d[-]", tostring(num), tostring(need))
    else
        Lab.text = string.format("[FF0000FF]%d[-]/[00C92BFF]%d[-]", tostring(num), tostring(need))
    end
end

--更新数量文本
function My:UpCountState()
    local cfg = self.cfg
    for i,j in ipairs(cfg.use) do
        local num = ItemTool.GetNum(j.k)
        local need = j.v
        self:CountState(self.root, self.Name, i, num, need)
    end
end

--可兑换状态
function My:CanEx()
    self:ChangeBtnIcon(true)
    self.ExBtn.Enabled = true
    --兑换
    -- UITool.SetBtnClick(self.root, "ExBtn", self.Name, self.OnExBtnClick, self)
end

--不可兑换状态
function My:NoEx()
    self:ChangeBtnIcon(false)
    self.ExBtn.Enabled = false
end

--更换按钮颜色
function My:ChangeBtnIcon(isActive)
    local spr = self.ExSpr
    if isActive then
        spr.spriteName = "btn_figure_non_avtivity"
    else
        spr.spriteName = "btn_figure_down_avtivity"
    end
end

function My:ClearIcon()
    if self.itList then
        for k,v in pairs(self.itList) do
            GameObject.Destroy(v.trans.gameObject)
            v:DestroyGo()
            ObjPool.Add(v)
            self.itList[k] = nil
        end
    end
end

function My:ClearReIcon()
    if self.rewardList then
        for k,v in pairs(self.rewardList) do
            if not LuaTool.IsNull(v.trans.gameObject) then
                GameObject.Destroy(v.trans.gameObject)
                v:DestroyGo()
                ObjPool.Add(v)
                self.rewardList[k] = nil
            end
        end
    end
end

--清理缓存
function My:Clear()
    TableTool.ClearUserData(self)
end

--释放资源
function My:Dispose()
    self:ClearIcon()
    self:ClearReIcon()
    -- ListTool.ClearToPool(self.itList)
end

return My