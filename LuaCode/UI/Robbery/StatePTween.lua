require("UI/Robbery/StateItemSkill")

StatePTween = Super:New{Name = "StatePTween"}
local My = StatePTween

local SKIT = StateItemSkill

function My:Init(go,stateAct)
    local root = go.transform
    self.Gbj = root
    local name = root.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local USBC = UITool.SetBtnClick
    local UC = UITool.SetLsnrClick
    self.curIndex = nil
    self.propLabTab = {}

    self.stateSkill = TF(root,"skillGrid/cell")
    self.stateSkill.gameObject:SetActive(false)
    self.propLab = CG(UILabel,root,"propLab",name)
    self.flag = CG(UISprite,root,"flag",name)
    self.stateP = stateAct
    local propTrans = self.propLab.transform
    for i = 1,6 do
        local index = tostring(i)
        local propL = CG(UILabel,propTrans,index,name)
        table.insert(self.propLabTab,propL)
    end
    self.skilGrid = CG(UIGrid,root,"skillGrid",name)
    self.skilItems = {}
end

function My:ShowProp(propTab,isGry)
    local str = ""
    local index = 0
    local color1 = ""
    local color2 = ""
    self.flag.gameObject:SetActive(isGry)
    self.flag.color = Color.New(1,1,1,1)
    if isGry == true then
        color1 = "[B2ADAD]"
        color2 = "[B2ADAD]"
    else
        color1 = "[F4DDBDFF]"
        color2 = "[00FF00FF]"
    end
    local propLabTab = self.propLabTab
    for k,v in pairs(propTab) do
        index = index + 1
        local name = PropName[k].name
        local val = v
        propLabTab[index].text = string.format( "%s%s[-] %s+%s[-]",color1,name,color2,val)
    end
    for i = index + 1 ,#propLabTab do
        propLabTab[i].text = ""
    end
end

function My:ShowReward(data,isGry)
    local len = #data
    local list = self.skilItems
    local count = #self.skilItems
    if len < 1 then return end
    local max = count >= len and count or len
    local min = count + len - max
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i],isGry)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.stateSkill)
            TransTool.AddChild(self.skilGrid.transform,go.transform)
            go.transform.localScale = Vector3.New(0.85,0.85,0.85)
            local item = ObjPool.Get(SKIT)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i],isGry)
            table.insert(list, item)
        end
        UITool.SetLsnrSelf(list[i].skBox, self.OnClickTipBtn,self)
    end
    self.skilGrid:Reposition()
end

function My:OnClickTipBtn(go)
    local skilTip = self.stateP.stateSkillT
    local spClickMod = self.stateP.stateMInfo
    local id = go.gameObject.name
    local data = ItemData[id] ~= nil and ItemData[id] or SkillLvTemp[id]
    if SpiriteCfg[id] then
        spClickMod.spIdIndex = tonumber(id)
        spClickMod:ClickSpReward()
    else
        skilTip:Show(data,1)
    end
end

function My:ItemSkillToPool()
    for k,v in pairs(self.skilItems) do
        v:UnLoadIcon()
        v:Dispose()
        ObjPool.Add(v)
        self.skilItems[k] = nil
    end
    for k,v in pairs(self.propLabTab) do
        self.propLabTab[k] = nil
    end
end

function My:Dispose()
    self.stateP = nil
    self:ItemSkillToPool()
    TableTool.ClearUserData(self)
end