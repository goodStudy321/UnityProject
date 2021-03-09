
--[[
告别单身
--]]


UIGoodByeSingle = Super:New{Name = "UIGoodByeSingle"}

require("UI/UIGoodByeSingle/GoodByeSingleCell")
require("Tool/MyGbjPool")
local My = UIGoodByeSingle

My.mCellList = {}

local aMgr = Loong.Game.AssetMgr

function My:Init(go)
    self.go = go
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local USB = UITool.SetBtnClick

    self.trans = go.transform
    local trans = self.trans
    self.labFightVal = CG(UILabel, trans, "labFightVal")
    self.labBtnGet = CG(UILabel, trans, "btnGet/Label")
    self.labTime = CG(UILabel, trans, "labTime")
    self.redPoint = TF(trans, "btnGet/red")
    self.btnMarry = TF(trans, "btnMarry")
    self.btnGet = TF(trans,"btnGet")
    self.tex1 = TF(trans,"tex1")
    self.tex2 = TF(trans,"tex2")
    self.gbjPool = ObjPool.Get(MyGbjPool)

    USB(trans, "btnGet",self.Name, self.OnClickTopBtnGet, self)
    USB(trans, "btnMarry", self.Name, self.OnClickTopBtnMarry, self)

    local gridParent = TF(self.trans, "Grid")
    for i = 1, 3 do
        local go = TFC(gridParent, tostring(i))
        local cell = ObjPool.Get(GoodByeSingleCell)
        cell:Init(go)
        self.mCellList[i] = cell
    end
    self:InitActionInfo()
    self:UpTopBtn()
    self:UpdateTex()
    self:SetFightText()
    self:UpdateCell()
    --初始化时判断红点
    local mgr = GoodByeSingleMgr
    local isred = mgr:UpRedPoint()
    if isred then
        mgr.eRed(isred, 4)
    end
    self:SetEvent("Add")

end

--初始化活动信息，并存起来
function My:InitActionInfo()
    local info = NewActivMgr:GetActivInfo(GoodByeSingleMgr.sysID)
    if not info then return end
    GoodByeSingleMgr:SaveActivInfo(info)
end

--设置左边情侣称号特效
function My:SetTex1(go)
    if not LuaTool.IsNull(self.tex1) then
        self.gbjPool:Add(self.title1)
        self.title1 = go
        go.transform:SetParent(self.tex1)
        go.transform.localScale = Vector3(0.7, 0.7, 0.7)
        go.transform.localPosition = Vector3(0,0,0)
    else
        self:Unload(go)
    end
end

--设置右边情侣称号特效
function My:SetTex2(go)
    if not LuaTool.IsNull(self.tex2) then
        self.gbjPool:Add(self.title2)
        self.title2 = go
        go.transform:SetParent(self.tex2)
        go.transform.localScale = Vector3(0.7, 0.7, 0.7)
        go.transform.localPosition = Vector3(0,0,0)
    else
        self:Unload(go)
    end
end

--更新顶部按钮状态
function My:UpTopBtn()
    local mgr = GoodByeSingleMgr
    local dataList = mgr.dataList
    local labBtn = self.labBtnGet
    local red = self.redPoint
    local btnGet = self.btnGet
    local btnMarry = self.btnMarry
    local btnType = mgr:UpBtnType(4)
    if btnType then
        btnGet.gameObject:SetActive(true)
        btnMarry.gameObject:SetActive(false)
        if btnType.val == 1 then
            labBtn.text = "领取"
            red.gameObject:SetActive(true)
        elseif btnType.val == 2 then
            labBtn.text = "已领取"
            red.gameObject:SetActive(false)
            UITool.SetGray(btnGet)
        end
    else
        btnGet.gameObject:SetActive(false)
        btnMarry.gameObject:SetActive(true)
    end
end

--设置战力值
function My:SetFightText()
    local mgr = GoodByeSingleMgr
    local fightNum = mgr:GetFightVal()
    local labFightVal = self.labFightVal
    labFightVal.text = tostring(fightNum)
end

--设置活动时间
function My:SetTimeText()
    local mgr = GoodByeSingleMgr
    local labTime = self.labTime
    local str = mgr:GetTimeStr()
    labTime.text = str
end


function My:SetEvent(func)
    local mgr = GoodByeSingleMgr
    mgr.eUpTopBtn[func](mgr.eUpTopBtn, self.UpTopBtn, self)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function My:OnAdd(action,dic)
    if action==10451 then
        self.dic=dic
        UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
    end
end

--显示奖励的回调方法
function My:RewardCb(name)
    local ui = UIMgr.Get(name)
    if(ui)then
        ui:UpdateData(self.dic)
    end
end

--点击前往结婚
function My:OnClickTopBtnMarry()
    UIMarry:OpenTab(1);
end

--点击领取按钮
function My:OnClickTopBtnGet()
    local labBtnGet = self.labBtnGet
    if labBtnGet.text == "领取" then
        local mgr = GoodByeSingleMgr
        mgr:ResqGet(4)
    end
end

--刷新cell内容
function My:UpdateCell()
    local mgr = GoodByeSingleMgr
    local data = mgr:GetCellData()
    local list = self.mCellList
    for i = 1, #data do
        if list[i] then
            list[i]:UpdateData(data[i])
        end
    end
end

--刷新两个情侣称号特效
function My:UpdateTex()
    local mgr = GoodByeSingleMgr
    local idList = mgr:GetTexIdList()
    local name1 = TitleCfg[tostring(idList[1])].prefab1
    local name2 = TitleCfg[tostring(idList[2])].prefab1
    if StrTool.IsNullOrEmpty(name1) then return end
    if StrTool.IsNullOrEmpty(name2) then return end
    name1 = QualityMgr:GetQuaEffName(name1)
    name2 = QualityMgr:GetQuaEffName(name2)
    if not AssetTool.IsExistAss(name) then
        return
    end

    aMgr.LoadPrefab(name1, GbjHandler(self.SetTex1, self))
    aMgr.LoadPrefab(name2, GbjHandler(self.SetTex2, self))
end

function My:OpenCustom()
    self:SetTimeText()
end

function My:Open( ... )
    self.go:SetActive(true)
    self:OpenCustom()
end

function My:Close( ... )
    --关闭时判断红点
    local mgr = GoodByeSingleMgr
    local isred = mgr:UpRedPoint()
    if isred then
        mgr.eRed(isred, 4)
    end
    self.go:SetActive(false)
end

function My:Unload(go)
    if LuaTool.IsNull(go) then return end
    AssetMgr:Unload(go.name, "prefab", false)
    GameObject.DestroyImmediate(go)
end

function My:Dispose()
    self:SetEvent("Remove")
    ObjPool.Add(self.gbjPool)
    self.gbjPool = nil
    self:Unload(self.title1)
    self.title1 = nil
    self:Unload(self.title2)
    self.title2 = nil
    TableTool.ClearDicToPool(self.mCellList)
end
















