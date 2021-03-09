FeverCopy = Super:New{Name = "FeverCopy"}
local My = FeverCopy

local aMgr = Loong.Game.AssetMgr

local US = UITool.SetBtnClick
local T = TransTool.FindChild
local C = ComTool.Get
local CS = ComTool.GetSelf
local Add = TransTool.AddChild

function My:Init(go)
    self.go = go
    local trans = go.transform
    local des = self.Name

    self.lb1 = C(UILabel,trans,"lb1",des)
    self.lb2 = C(UILabel,trans,"lb2",des)

    self.grid = C(UIGrid,trans,"grid",des)

    self.cellRoot = T(trans,"grid").transform

    US(trans, "goBtn", des, self.OnGo, self)

    self.modRoot = T(trans,"mod",des).transform

    self.goBtnSpr = C(UISprite,trans,"goBtn",des)

    self.items = {}
    self:ShowPoint()
    self:ShowReward()
    self:ShowModel()
    self:ShowBtnState()
end

function My:ShowPoint()
    self.curPoint = TreaFeverMgr:GetCurPoint()
    self.allPoint = TreaFeverMgr:GetAllPoint()
    if self.curPoint> self.allPoint then
        self.lb1.text="已完成挑战"
        return
    end
    if self.curPoint == 0 then
        self.lb1.text = "暂未闯关"
    else
        self.lb1.text = "第"..self.curPoint.."关"
    end
    self.lb2.text = "共"..self.allPoint.."关"
end

function My:ShowBtnState()
    local box = self.goBtnSpr.gameObject:GetComponent(typeof(BoxCollider))
    if self.curPoint > self.allPoint then
        self.goBtnSpr.spriteName = "btn_figure_down_avtivity"
        box.enabled = false
    else
        self.goBtnSpr.spriteName = "btn_figure_non_avtivity"
        box.enabled = true
    end
end

function My:ShowModel()
    local modId = TreaFeverMgr:GetBossId()
    local info = MonsterTemp[tostring(modId)]
    if not info then iTrace.eError("不存在怪物表Id",modId) return end
    modId = info.modId
    info = RoleBaseTemp[tostring(modId)]
    if not info then iTrace.eError("不存在模型Id",modId) return end
    local modPath=nil;
    modPath = info.uipath;
    if modPath == nil then
        modPath = info.path;
    end
    aMgr.LoadPrefab(modPath,GbjHandler(self.SetDetailModel,self))
end

function My:SetDetailModel(go)
    if go == nil then
        return;
    end
    if  LuaTool.IsNull(self.go) == nil then
        GO.Destroy(go);
        return;
    end
    self:ClearCurDetailModel()
    self.curDetailModel = go
    TransTool.AddChild(self.modRoot,go.transform);
    go.transform.localEulerAngles = Vector3.New(0,0,0);
    local modId = TreaFeverMgr:GetBossId()
    local uiboss = FeverHelp.GetBossUi(modId)
    self.elAgl= uiboss.uiElAgl
    self.pos = uiboss.uiPos
    self:SetAngle();
    self:SetPos();
    LayerTool.Set(go,19);
end

--设置角度
function My:SetAngle()
    if self.modRoot == nil then
        return;
    end
    if self.elAgl == nil then
        return;
    end
    local len = #self.elAgl;
    if len ~= 3 then
        return;
    end
    self.modRoot.localEulerAngles = Vector3.New(self.elAgl[1],self.elAgl[2],self.elAgl[3]);
end

--设置位置
function My:SetPos()
    if self.modRoot == nil then
        return;
    end
    if self.pos == nil then
        return;
    end
    local len = #self.pos;
    if len ~= 3 then
        return;
    end
    self.modRoot.localPosition = Vector3.New(self.pos[1],self.pos[2],self.pos[3]);
end

function My:ClearCurDetailModel()
    if self.modRoot == nil then
        return;
    end
    if self.curDetailModel then
        AssetMgr:Unload(self.curDetailModel.name, ".prefab", false)
        DestroyImmediate(self.curDetailModel)
        self.curDetailModel = nil
        self.pos = nil;
        self.elAgl = nil;
    end
end

function My:ShowReward()
    local data = TreaFeverMgr:GetCopyAward()
    local num = #data
    for i=1,num do
        self.item = ObjPool.Get(UIItemCell)
        self.item:InitLoadPool(self.cellRoot,0.8,nil,nil,nil,Vector3.Zero)
        self.item:UpData(data[i].k,data[i].v)
        self.items[#self.items + 1] = self.item
    end
end

function My:OnGo()
    local mapId = TreaFeverMgr:GetMapId()
    if not mapId then return end
    SceneMgr:ReqPreEnter(mapId, true, true)
end

function My:UpShow(value)
    self.go:SetActive(value)
end

function My:Dispose()
    while #self.items > 0 do
        local item = self.items[#self.items]
        item:DestroyGo()
        ObjPool.Add(item)
        self.items[#self.items] = nil
    end
    self:ClearCurDetailModel()
end

return My