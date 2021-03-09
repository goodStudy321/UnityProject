--[[
 	authors 	:Liu
 	date    	:2019-7-24 10:40:00
 	descrition 	:丹药信息弹窗
--]]

UIElixirPop = Super:New{Name = "UIElixirPop"}

local My = UIElixirPop

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local CGS = ComTool.GetSelf
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.proLabList = {}
    self.valLabList = {}

    self.nameLab = CG(UILabel, root, "titleBg/lab")
    self.desLab1 = CG(UILabel, root, "des1")
    self.desLab2 = CG(UILabel, root, "des2")
    self.desLab3 = CG(UILabel, root, "des3")
    self.labGrid = CG(UIGrid, root, "proGrid")
    self.cellTran = Find(root, "cell", des)
    self.redGo = FindC(root, "useBtn/Red", des)
    self.btnGo = FindC(root, "useBtn", des)
    self.labItem = FindC(root, "proGrid/proLab", des)
    self.labItem:SetActive(false)

    self.yPos1 = self.desLab1.transform.localPosition.y

    self:InitLabItem(CG, CGS)
    self:CreateTimer()

    SetB(root, "useBtn", des, self.OnUseBtn, self)
end

--更新数据
function My:UpData(cfg, count)
    self.cfg = cfg
    self.count = count
    self:UpCell(cfg)
    self:UpName(cfg)
    self:UpProLab(cfg)
    self:UpDesLab(cfg)
    self:UpAction(cfg, count)
end

--点击使用按钮
function My:OnUseBtn()
    local cfg = self.cfg
    local count = self.count
    if cfg == nil or count == nil then return end
    local isMax = ElixirMgr:IsMax(cfg.id, cfg.max, cfg.type, cfg.time, cfg.max)
    if isMax then
        if cfg.type == 1 then
            MsgBox.ShowYes("丹药虽好多吃无益\n请尝试使用其他丹药")
            return
        end
        local name, val, id = ElixirMgr:GetDes2Lab(cfg)
        if name == nil or val == nil then return end
        if cfg.type==0 and val < cfg.max then
            -- local str = string.format("已达到当前使用上限\n提升境界至%s可继续使用", name)
            -- MsgBox.ShowYes(str, self.YesCb, self, "立即前往")
            UITip.Error("已达到当前使用上限")
        else
            MsgBox.ShowYes("丹药虽好多吃无益\n请尝试使用其他丹药")
        end
        return
    elseif count < 1 then
        UITip.Log("丹药数量不足")
        GetWayFunc.AdvGetWay(UIElixir.Name,1,cfg.id)
        return
    end
    if cfg.type==0 then
        if self:IsUse(cfg)==false then return end
    end

    ElixirMgr:ReqUse(cfg.id, 1)
end

--点击立即前往
function My:YesCb()
    UIRobbery:OpenRobbery(1)
end

--使用能使用永久丹药
function My:IsUse(cfg)
    local name, val, id = ElixirMgr:GetDes2Lab(cfg)
    local rCfg = RobberyMgr:GetCurCfg()
    if rCfg.id < id then
        -- local str = string.format("已达到当前使用上限\n提升境界至%s可继续使用", name)
        -- MsgBox.ShowYes(str, self.YesCb, self, "立即前往")
        UITip.Error("已达到当前使用上限")
        return false
    else
        return true
    end
end

--更新描述
function My:UpDesLab(cfg)
    local str1 = ""
    local str2 = ""
    local str3 = ""
    local tran = self.desLab1.transform
    self.desLab2.gameObject:SetActive(true)
    self.desLab3.gameObject:SetActive(true)
    self.btnGo:SetActive(true)
    if cfg.type == 0 then
        local name, val, id = ElixirMgr:GetDes2Lab(cfg)
        if name == nil or val == nil then return end
        local count = ElixirMgr:GetElixirCount(cfg.id)

        local isMax = ElixirMgr:IsMax(cfg.id, cfg.max, cfg.type, cfg.time, cfg.max)
        local rCfg = RobberyMgr:GetCurCfg()
        local isShow = not ((val >= cfg.max) and (rCfg.id >= id))
        local y = (isShow==false) and (self.yPos1-18) or self.yPos1
        self.desLab1.transform.localPosition = Vector3(tran.localPosition.x, y, 0)
        self.desLab2.gameObject:SetActive(isShow)
        if isShow or isMax==false then
            self.desLab3.text = "[FDC580FF]使用丹药后永久提升属性"
        else
            self.btnGo:SetActive(false)
            self.desLab3.text = "[FDC580FF]已达到使用上限"
        end

        str1 = string.format("[F4DDBDFF]当前最多可使用[00FF00FF](%s/%s)[F4DDBDFF]个", count, cfg.max)
        str2 = string.format("[F4DDBDFF]角色升至%s,可使用[00FF00FF]%s[F4DDBDFF]个", name, val)
    elseif cfg.type == 1 then
        local sec = ElixirMgr:GetElixirTime(cfg.id)
        str1 = string.format("[F4DDBDFF]使用后属性加成持续%s分钟", cfg.time)
        str2 = "[F4DDBDFF]使用相同丹药可叠加持续时间"
        self.desLab1.transform.localPosition = Vector3(tran.localPosition.x, self.yPos1, 0)
        self:UpTimer(sec)
    end
    self.desLab1.text = str1
    self.desLab2.text = str2
end

--更新名字
function My:UpName(cfg)
    local item = ItemData[tostring(cfg.id)]
    if item == nil then return end
    if cfg.type == 0 then
        self.nameLab.text = string.format("%s(永久)", item.name, str)
    elseif cfg.type == 1 then
        self.nameLab.text = item.name
    end
end

--更新道具
function My:UpCell(cfg)
    if self.cell == nil then
        self.cell = ObjPool.Get(UIItemCell)
        self.cell:InitLoadPool(self.cellTran)
    end
    self.cell:UpData(cfg.id)
end

--更新属性文本
function My:UpProLab(cfg)
    self:HideLabItems()
    for i=1, ElixirMgr.maxProCount do
        local proList = cfg["pro"..i]
        if #proList > 0 then
            local id = proList[1]
            local val = proList[2]
            if val == nil then break end
            local info = PropName[id]
            if info == nil then return end
            self.proLabList[i].gameObject:SetActive(true)
            if cfg.type == 0 then
                local count = ElixirMgr:GetElixirCount(cfg.id)
                local isMax = ElixirMgr:IsMax(cfg.id, cfg.max, cfg.type, cfg.time, cfg.max)
                local plusCount = (isMax==true) and 0 or count+1
                local temp1 = (info.show==1) and (val/10000*100*count).."%" or val*count
                local temp2 = (info.show==1) and (val/10000*100*plusCount).."%" or val*plusCount
                self.proLabList[i].text = string.format("%s %s", info.name, temp1)
                self.valLabList[i].text = "+"..temp2
            elseif cfg.type == 1 then
                local temp = (info.show==1) and (val/10000*100).."%" or val
                self.proLabList[i].text = info.name
                self.valLabList[i].text = "+"..temp
            end
        end
    end
end

--隐藏文本项
function My:HideLabItems()
    for i,v in ipairs(self.proLabList) do
        v.gameObject:SetActive(false)
    end
end

--初始化文本项
function My:InitLabItem(CG, CGS)
    local Add = TransTool.AddChild
    for i=1, ElixirMgr.maxProCount do
        local go = Instantiate(self.labItem)
        local tran = go.transform
        go:SetActive(true)
        Add(self.labGrid.transform, tran)
        local proLab = CGS(UILabel, tran, self.Name)
        local valLab = CG(UILabel, tran, "valLab")
        table.insert(self.proLabList, proLab)
        table.insert(self.valLabList, valLab)
    end
    self.labGrid:Reposition()
end

--更新红点
function My:UpAction(cfg, count)
    local isShow = ElixirMgr:IsShowUiAction(cfg, count)
    UIElixir:ElixirRed(cfg);
    self.redGo:SetActive(isShow)
end

--更新计时器
function My:UpTimer(rTime)
	local timer = self.timer
	timer:Stop()
	timer.seconds = rTime
    timer:Start()
    self:InvCountDown()
end

--创建计时器
function My:CreateTimer()
    if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
    timer.fmtOp = 3
	timer.apdOp = 1
end

--间隔倒计时
function My:InvCountDown()
    if self.cfg.type == 1 then
        self.desLab3.text = string.format("[F4DDBDFF]当前剩余时间：[00FF00FF]%s", self.timer.remain)
    end
end

--结束倒计时
function My:EndCountDown()
	self.desLab3.gameObject:SetActive(false)
end

--清空道具
function My:ClearCell()
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
        self.cell = nil  
    end
end

--清空计时器
function My:ClearTimer()
	if self.timer then
		self.timer:Stop()
		self.timer:AutoToPool()
		self.timer = nil
	end
end

--清理缓存
function My:Clear()
    self.cfg = nil
    self.count = nil
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:ClearCell()
    self:ClearTimer()
end

return My