require("UI/Robbery/StateReCell")
StateSInfo = Super:New{Name = "StateSInfo"}

local My = StateSInfo

function My:Init(go,statePanelInfo)
    local root = go.transform
    self.Gbj = root
    self.statePanelInfo = statePanelInfo
    local name = root.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local USBC = UITool.SetBtnClick
    local UC = UITool.SetLsnrClick
    self.cellTab = {}
    self.propTab = {}
    local vec = Vector3.New()
    local pos1 = vec(-158,-58,0)
    local pos2 = vec(25,-58,0)
    local pos3 = vec(-158,-89,0)
    local pos4 = vec(25,-89,0)
    self.propPos = {pos1,pos2,pos3,pos4}

    -- self.curSLab = CG(UILabel,root,"curSLab",name)
    self.propLab = CG(UILabel,root,"propLab",name)
    self.propLab.text = ""
    -- self.propNum = CG(UILabel,root,"propLab/propNum",name)
    -- self.scrollV = CG(UIScrollView,root,"scroll",name)
    -- self.scrollPan = CG(UIPanel,root,"scroll",name)
    self.grid = CG(UIGrid,root,"scroll/grid",name)
    self.cell = TF(root,"scroll/grid/cell")
    self.cell.gameObject:SetActive(false)
end

function My:RefreshSShow()
    local state = RobberyMgr.RobberyState
    local cfg = nil
    local cfg = RobberyMgr:GetNextCfg()
    -- if state == 1 then
    --     cfg = RobberyMgr:GetPreCfg()
    -- elseif state == 5 then
    --     cfg = RobberyMgr:GetNextCfg()
    -- end
    if cfg == nil then
        return     
    end
    local stateId = cfg.id
    local rewardTab = RobberyMgr:GetCurSReward(stateId)
    local curF = cfg.floorName
    self:RefreshProp(cfg)
    self:ShowReward(rewardTab)
end

function My:ShowReward(data)
    local len = #data
    local list = self.cellTab
    local count = #self.cellTab
    if len < 1 then return end
    local max = count >= len and count or len
    local min = count + len - max
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.cell)
            TransTool.AddChild(self.grid.transform,go.transform)
            go.transform.localScale = Vector3.New(0.85,0.85,0.85)
            local item = ObjPool.Get(StateReCell)
            item:Init(go)
            local box = go.transform:GetComponent("BoxCollider")
            UITool.SetLsnrSelf(box,self.ClickBox,self,"StateReCell",false)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.grid:Reposition()
end

function My:ClickBox(obj)
    local skilTip = self.statePanelInfo.stateSkillT
    local spClickMod = self.statePanelInfo.stateMInfo
    local strName = obj.gameObject.name
    local name = tonumber(strName)
    local cfg = nil
    if name < 20 then --战灵装备孔
        cfg = ItemData["24"]
    elseif SkillLvTemp[strName] then
        cfg = SkillLvTemp[strName]
    elseif ItemData[strName] then
        cfg = ItemData[strName]
    end
    if SpiriteCfg[strName] then
        cfg = nil
    end
    if SpiriteCfg[strName] then
        spClickMod.spIdIndex = tonumber(strName)
        spClickMod:ClickSpReward()
    else
        skilTip:Show(cfg,2)
    end
    -- iTrace.eError("GS","click name====",name)
end

function My:RefreshProp(cfg)
    local props = PropTool.SwitchAttr(cfg)
    local len = #props
    if len < 1 then return end

    local list = self.propTab
    local pos = self.propPos
    local count = #self.propTab
    local max = count >= len and count or len
    local min = count + len - max
    for i=1, max do
        if i <= min then
            self:SetCurPLab(props[i],list[i])
        elseif i <= count then
            list[i].text = ""
        else
            local go = Instantiate(self.propLab.gameObject)
            TransTool.AddChild(self.Gbj.transform,go.transform)
            go.transform.localPosition = pos[i]
            local item = go:GetComponent("UILabel")
            self:SetCurPLab(props[i],item)
            table.insert(list, item)
        end
    end
end

--设置当前境界
function My:SetCurSLab(lab)
    self.curSLab.text = string.format( "到达%s",lab)
end

--设置当前境界属性
function My:SetCurPLab(data,item)
    local str = ""
    local info = data
    local key = info.k
    local val = info.v
    local name = PropName[key].name
    str = string.format("[F4DDBDFF]%s[-]  [00FF00FF]+%s[-]",name,val)
    item.text = str
end

function My:CellToPool()
    for k,v in pairs(self.cellTab) do
        v:Dispose()
        ObjPool.Add(v)
        self.cellTab[k] = nil
    end

    for k,v in pairs(self.propTab) do
        self.propTab[k] = nil
    end
end

function My:Dispose()
    self:CellToPool()
    TableTool.ClearUserData(self)
end