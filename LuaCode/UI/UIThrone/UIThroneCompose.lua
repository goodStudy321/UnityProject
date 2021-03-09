UIThroneCompose = Super:New{Name = "UIThroneCompose"}

require("UI/UIThrone/ThComposeCell")

local My = UIThroneCompose

My.cellList = {}
My.selectList = {}
My.showCompExp = 0

function My:Init(root)
    self.gbj = root.gameObject
    local trans = root
    local G = ComTool.Get
    local SC = UITool.SetLsnrClick
    local EA = EventDelegate.Add
    local EC = EventDelegate.Callback
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf

    self.desLab = G(UILabel,trans,"desLab")
    self.sView = G(UIScrollView, trans, "ScrollView")
    self.grid = G(UIGrid, trans, "ScrollView/Grid")
    self.expLab = G(UILabel,trans,"comLab/expLab")
    self.icon = G(UITexture,trans,"comLab/Icon",des)
    self.prefab = FC(self.grid.transform, "Cell")
    self.prefab:SetActive(false)
    local prefabTemp = FC(self.grid.transform, "cell")
    prefabTemp:SetActive(false)
    self.cellTemp = {}
    for i = 1,21 do
        local go = Instantiate(prefabTemp)
        go:SetActive(true)
        TransTool.AddChild(self.grid.transform,go.transform)
        table.insert(self.cellTemp, go)
    end
    self.grid:Reposition()

    self.composeBtn = FC(trans, "Button")
    self.btnClose = FC(trans, "closeBtn")
    S(self.composeBtn,self.OnComposeBtn,self)
    S(self.btnClose, self.Close, self)
    self:UpIcon()
end

--icon
function My:UpIcon()
	self.iconName = ItemData["20"].icon
	AssetMgr:Load(self.iconName,ObjHandler(self.LoadIcon,self))
end

function My:LoadIcon(obj)
	self.icon.mainTexture = obj
end

function My:UnloadTex()
	if self.iconName then 
		AssetMgr:Unload(self.iconName,".png",false)
	end
	self.iconName=nil
end

function My:Open()
    self.gbj:SetActive(true)
    self:SetEvent("Add")
    self:Refresh()
end

function My:Close()
    self.gbj:SetActive(false)
    self:SetEvent("Remove")
    self:ClearSelectData()
end

function My:SetEvent(fn)
    local mgr = ThroneMgr
	PropMgr.eUpdate[fn](PropMgr.eUpdate, self.Refresh, self)
	-- mgr.eRespCompose[fn](mgr.eRespCompose, self.OnComposeInfo, self)
    -- RobberyMgr.eUpdateSpiRefInfo[fn](RobberyMgr.eUpdateSpiRefInfo, self.SetSpProp, self)
end


function My:UpdateData(data)
    local len = #data
    local list = self.cellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
    local str = ""
    self.grid.gameObject:SetActive(true)
    if len == 0 then
        local color = "[F39800FF]"
        str = string.format("暂无%s宝座晶石[-]可分解，击败%s世界BOSS[-]有机率掉落%s宝座晶石[-]和激活道具",color,color,color)
        self.grid.gameObject:SetActive(false)
    end
    self.desLab.text = str
    
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.prefab)
            TransTool.AddChild(self.cellTemp[i].transform,go.transform)
            local item = ObjPool.Get(ThComposeCell)
            item:Init(go)
            item.eClick:Add(self.OnClick,self)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.grid:Reposition()
end

function My:ClearSelectData()
    self.showCompExp = 0
    self.expLab.text = self.showCompExp
    TableTool.ClearDic(self.selectList)
end

function My:OnClick(isSelect, data)
    if isSelect then
        TableTool.Add(self.selectList, data)
    else
        TableTool.Remove(self.selectList, data)
    end
    self:ShowComposeExp(isSelect,data)
end

function My:SelectAll()
    self:ClearSelectData()
    local list = self.cellList
    for i=1,#list do
        if list[i]:IsActive() then
            list[i]:SetHighlight(true)
            table.insert(self.selectList, list[i].data)
            self:ShowComposeExp(true,list[i].data)
        end
    end
end

--显示分解将要获得的经验
function My:ShowComposeExp(isSelect,dataId)
    local showExp = self.showCompExp
    local dataId = dataId
    dataId = tostring(dataId)
    local equipCfg = ItemData[dataId]
    local propNum = PropMgr.TypeIdByNum(dataId)
    local comExp = equipCfg.uFxArg[1] * propNum
    if isSelect then
        showExp = showExp + comExp
    else
        showExp = showExp - comExp
    end
    self.showCompExp = showExp
    self.expLab.text = self.showCompExp
end

--分解返回
function My:OnComposeInfo()

end

function My:Refresh()
    self:ClearSelectData()
    local data = nil
    local data = self:UpdateProps()
    self:UpdateData(data)
    self:SelectAll()
end

function My:UpdateProps()
    local data = {}
    local itemIds = ItemsCfg[6].ids
    local res, GetNum = nil, ItemTool.GetNum
    for i=1,#itemIds do
        local id = itemIds[i]
        res = GetNum(id)
        res = res or 0
        if res > 0 then
            table.insert(data,id)
        end
    end
    return data
end

--点击分解
function My:OnComposeBtn()
    local list = self.selectList
    local len = #list
    if len == 0 then
        UITip.Log("请选择分解材料")
        return
    end
    ThroneMgr.ReqCompose(list)
end

function My:ClearTemp()
    local len = #self.cellTemp
	while len > 0 do
		self.cellTemp[len] = nil
		table.remove(self.cellTemp, len)
		len = #self.cellTemp
	end
end

function My:Dispose()
    self:SetEvent("Remove")
    self:UnloadTex()
    self:ClearSelectData()
    self:ClearTemp()
    self.showCompExp = 0
    TableTool.ClearListToPool(self.cellList)
    -- TableTool.ClearUserData(self)
end

return My