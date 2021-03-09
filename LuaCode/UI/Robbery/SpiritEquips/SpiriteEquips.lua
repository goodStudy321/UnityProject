require("UI/Robbery/SpItemCom")
require("UI/Robbery/SpiritEquips/SpirEquipList")
require("UI/Robbery/SpiritEquips/SpirEquipPack")
require("UI/Robbery/SpiritEquips/SpirEquipAttr")
require("UI/Robbery/SpiritEquips/SpirEquipOpen")
SpiriteEquips = UILoadBase:New{Name = "SpiriteEquips"}
local My = SpiriteEquips;

function My:Init()
    local root = self.GbjRoot;
    self.root = root;
    local name = root.name;
    local CG = ComTool.Get;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;

    local item = TF(root,"mods/Grid/item",name);
    local grid = CG(UIGrid,root,"mods/Grid",name,false);
    local modParent = TF(root,"modelRoot",name);
    SpItemCom:Init(item,grid,modParent);

    local equips = TF(root,"Equips",name);
    local equipsPack = TF(root,"SpiritEquips",name);
    local equipTip = TF(root,"EquipTip",name);
    local lockOpen = TF(root,"OpenTip",name);
    SpirEquipList:Init(equips);
    SpirEquipPack:Init(equipsPack);
    SpirEquipAttr:Init(equipTip);
    SpirEquipOpen:Init(lockOpen);

    UC(root,"attBtn",name,self.AttrC,self);
    UC(root,"PutOnBtn",name,self.PutOnC,self);
    UC(root,"TackoffBtn",name,self.TackoffC,self);

    self:SetActive(self.root,false);
end

--添加事件监听
function My:AddLsnr()
	RobEquipsMgr.eRfrRed:Add(self.RefreshRed,self);
end

--关闭事件监听
function My:RemoveLsnr()
	RobEquipsMgr.eRfrRed:Remove(self.RefreshRed,self);
end

--打开面板
function My:Open()
    -- self:SetActive(self.root,true);
    SpItemCom:SltDefault();
    SpirEquipList:Open();
    self:RefreshRed();
    self:AddLsnr();
end

--关闭面板
function My:Close()
    -- self:SetActive(self.root,false);
    SpirEquipList:Close();
    self:RemoveLsnr();
end

--关闭点击
function My:CloseC()
    self:Close();
end

--装备属性总览点击
function My:AttrC()
    SpirEquipAttr:Open();
end

--一键装备
function My:PutOnC()
    local HasUnlkEq =SpirEquipList.HasUnlockEquip();
    if HasUnlkEq == false then
        local msg = "未解锁装备孔";
        UITip.Log(msg);
        return;
    end

    local mgr = RobEquipsMgr;
    local spirId = mgr.GetCurSpirId();
    local equipIds = mgr.GetPutOnEqs(spirId);
    mgr:ReqArmorLoad(spirId,equipIds);
end

--一键卸载
function My:TackoffC()
    local HasUnlkEq =SpirEquipList.HasUnlockEquip();
    if HasUnlkEq == false then
        local msg = "未解锁装备孔";
        UITip.Log(msg);
        return;
    end

    local mgr = RobEquipsMgr;
    local dic = mgr.equipDic;
    local spirId = mgr.GetCurSpirId();
    local equips = dic[spirId];
    if equips == nil then
        return;
    end
    local equipIds = {};
    for k,v in pairs(equips) do
        equipIds[k] = v.type_id;
    end
    mgr:ReqArmorUnload(spirId,equipIds);
end

--设置状态
function My:SetActive(trans,active)
    if trans == nil then
        return;
    end
    local go = trans.gameObject;
    go:SetActive(active);
end

--刷新红点
function My:RefreshRed()
    self:RfrSpirRed();
    self:RfrSpirEqRed();
end

--刷新战灵红点
function My:RfrSpirRed()
    for k,v in pairs(SpiriteCfg) do
        local spirId = v.spiriteId;
        local red = RobEquipsMgr.GetSpirRed(spirId);
        SpItemCom:SetRed(spirId,red);
    end
end

--刷新战灵装备格子红点
function My:RfrSpirEqRed()
    local cellDic = SpirEquipList.cellDic;
    local spirId = SpirEquipList.curSpirId;
    local equips,parts = RobEquipsMgr.GetPutOnEqs(spirId,true);
    if cellDic == nil then
        return;
    end
    for k,v in pairs(cellDic) do
        local part = k;
        local cell = v;
        local val = parts[part];
        if val ~= nil then
            cell:IconUp(true);
            cell:IconDown(false);
        else
            cell:IconUp(false);
            cell:IconDown(false);
        end
    end
end

function My:Dispose()
    SpItemCom:Dispose();
    SpirEquipList:Dispose();
    SpirEquipPack:Dispose();
end