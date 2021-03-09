UIEvrBox = Super:New{Name="UIEvrBox"}
local My = UIEvrBox
require("UI/EvrBox/EvrBoxIt")

function My:Init(go)
    local tip = "UIEvrBox"
    self.root =go;
    self.go = go.gameObject
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local US = UITool.SetLsnrSelf

    self.grid = CG(UIGrid,root,"scrollV/Grid",tip)
    self.prefab = TF(root,"scrollV/Grid/item",tip)
    self.prefab.gameObject:SetActive(false)
    self.itemTab = {}
    self.tipBtn=TFC(root,"tipBtn",tip)
    self:RefreshData()
    self:SetLnsr("Add")
    US(self.tipBtn,self.OnClickTipBtn,self,tip)
end

function My:SetLnsr( func )
    EvrBoxMgr.eInfo[func](EvrBoxMgr.eInfo, self.RefreshData, self)
    EvrBoxMgr.eRecharge[func](EvrBoxMgr.eRecharge, self.ChangeShow, self)
    EvrBoxMgr.eReward[func](EvrBoxMgr.eReward, self.ChangeShow, self)
end

function My:OnClickTipBtn(go)
    local desInfo = InvestDesCfg["2012"]
    local str = desInfo.des
     UIComTips:Show(str, Vector3(-223,208,0),nil,nil,nil,nil,UIWidget.Pivot.TopLeft)
end

function My:RefreshData()
    local data = EvrBoxMgr:GetShowCfg()
    local len = #data
    local itemTab = self.itemTab
    local count = #itemTab
    local max = count >= len and count or len
    local min = count + len - max
    for i = 1,max do
        if i <= min then
            itemTab[i]:UpdateData(data[i])
            itemTab[i]:SetActive(true)
        elseif i <= count then
            itemTab[i]:SetActive(false)
        else
            local go = Instantiate(self.prefab)
            TransTool.AddChild(self.grid.transform,go.transform)
            local item = ObjPool.Get(EvrBoxIt)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(self.itemTab,item)
        end
    end
    self.grid:Reposition()
end

function My:UpShow(bool)
    self.go:SetActive(bool)
    local isRewRed = EvrBoxMgr:IsShowRed()
    if isRewRed == false then
        LvAwardMgr:UpAction(8,isRewRed)
    end
end

function My:ChangeShow()
    local tab = self.itemTab
    for i = 1,3 do
        local cRewTimes = EvrBoxMgr:GetCurRewTimes(i)
        local info = tab[i]
        info:RefreshDif(cRewTimes,i)
    end
end

function My:AddPool()
    self:TabToPool(self.itemTab)
end

function My:TabToPool(tab)
    for k,v in pairs(tab) do
        ObjPool.Add(v)
        tab[k] = nil
    end
end

function My:Dispose()
    self:SetLnsr("Remove")
    self:AddPool()
end