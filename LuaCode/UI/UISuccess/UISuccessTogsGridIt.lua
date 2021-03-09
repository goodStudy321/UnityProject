--[[
 	authors 	:Liu
 	date    	:2018-8-31 11:29:29
 	descrition 	:成就界面Togs下的Grid下的Togs
--]]

UISuccessTogsGridIt = Super:New{Name = "UISuccessTogsGridIt"}

local My = UISuccessTogsGridIt

function My:Init(root, cfg)
    local des = self.Name
    local CG, FindC = ComTool.Get, TransTool.FindChild
    UITool.SetLsnrSelf(root, self.OnTog, self, des)

    self.lab = CG(UILabel, root, "lab")
    self.lab1 = CG(UILabel, root, "lab1")
    self.mark = FindC(root, "mark", des)
    self.action = FindC(root, "Action", des)
    self.tog = ComTool.GetSelf(UIToggle, root, self.Name)
    self.go = root.gameObject
    self.cfg = cfg

    self:HideTog()
    self:IsShowAction()
end

--点击Tog
function My:OnTog(go)
    local id = self.cfg.k
    local succ = UISuccess
    SuccessInfo.tabIndex = id
    succ.mod1.go:SetActive(false)
    succ.mod2.go:SetActive(false)
    succ.mod3.go:SetActive(true)
    succ.mod3:UpData(id)
end

--隐藏Tog
function My:HideTog()
    local id = self.cfg.k
    if id == 101 then
        self.go:SetActive(false)
    end
end

--设置遮罩状态
function My:SetMarkState()
    local id = self.cfg.k
    if id % 100 == 1 then
        self.tog.value = true
        SuccessInfo.tabIndex = id
    end
end

--初始化文本
function My:UpLab()
    local cfg = self.cfg
    local total = self:GetTotalCount()
    local count = self:GetTagCount()
    local str = string.format("%s（%s/%s）", cfg.s, count, total)
    self.lab.text = str
    self.lab1.text = str
end

--获取标签页的数量
function My:GetTagCount()
    local count = 0
    local list = self:GetIdList()
    for i,v in ipairs(list) do
        local key = tostring(v)
        if SuccessInfo.getDic[key] then
            count = count + 1
        end
    end
    return count
end

--根据标签页获取成就ID列表
function My:GetIdList()
    local list = {}
    local tag = self.cfg.k
    for k,v in pairs(SuccessCfg) do
        if tag == v.tagType then
            table.insert(list, v.id)
        end
    end
    return list
end

--判断是否显示红点
function My:IsShowAction()
    local list = self:GetIdList()
    local info = SuccessInfo
    for i,v in ipairs(list) do
        local key = tostring(v)
        local cond = SuccessCfg[key].condition
        local isGet, count = SuccessInfo:IsGet(key)
        if count >= cond and not info.getDic[key] and isGet then
            self:UpAction(true)
            return
        end
    end
    self:UpAction(false)
end

--更新红点状态
function My:UpAction(state)
    self.action:SetActive(state)
end

--获取标签页总的数量
function My:GetTotalCount()
    local count = 0
    local tag = self.cfg.k
    for k,v in pairs(SuccessCfg) do
        if tag == v.tagType then
            count = count + 1
        end
    end
    return count
end

--清理缓存
function My:Clear()
    self.lab = nil
    self.lab1 = nil
    self.mark = nil
    self.tog = nil
    self.go = nil
    self.cfg = nil
end

-- 释放资源
function My:Dispose()
    self:Clear()
end

return My