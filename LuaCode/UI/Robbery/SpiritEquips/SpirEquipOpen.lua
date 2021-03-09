SpirEquipOpen = Super:New{Name="SpirEquipOpen"}
local My = SpirEquipOpen;

function My:Init(trans)
    self.root = trans.gameObject;
    local name = trans.name;
    local CG = ComTool.Get;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;

    self.Msg = CG(UILabel,trans,"msg",name,false);
    local go = TF(trans,"ItemRoot",name);
    self.ItemRoot = go.transform;
    UC(trans,"bg/yesBtn",name,self.OpenLock,self);
    UC(trans,"CloseBtn",name,self.Close,self);
    self:SetGbjState(self.root,false);
end

--打开
function My:Open(part)
    self:SetGbjState(self.root,true);
    self:SetMsg(part);
    self:SetNeedItem(part);
    self.part = part;
end

--关闭
function My:Close()
    self:SetGbjState(self.root,false);
    self:Clear();
end

--立即开启按钮点击
function My:OpenLock(go)
    local spirId = RobEquipsMgr.GetCurSpirId();
    local islock = RobberyMgr:IsLockSp(spirId);
    if islock == true then
        local msg = "请先激活当前战灵！";
        UITip.Log(msg);
        return;
    end
    if self.CanOpen == true then
        RobEquipsMgr:ReqArmorOpenLock(spirId,self.part);
        self:Close();
    else
        local itemInfo = RobEquipsMgr.GetOpenNeedItem(spirId,self.part);
        if itemInfo ~= nil then
            GetWayFunc.OpenGetWay(itemInfo.k,Vector3.zero);
        end
    end
end

--设置对象显示状态
function My:SetGbjState(go,active)
    local isNull = LuaTool.IsNull(go);
    if isNull == nil then
        return;
    end
    self.root:SetActive(active);
end

--设置信息
function My:SetMsg(part)
    if self.Msg == nil then
        return;
    end
    local partText = UIMisc.WearParts(tonumber(part));
    local text = string.format("当前灵器【%s】部位未开启",partText);
	self.Msg.text = text;
end

--设置需要物品
function My:SetNeedItem(part)
    self.CanOpen = false;
    local spirId = RobEquipsMgr.GetCurSpirId();
    local item = RobEquipsMgr.GetOpenNeedItem(spirId,part);
    if item == nil then
        return;
    end
    if self.NeedItem == nil then
        self.NeedItem = ObjPool.Get(UIItemCell);
        self.NeedItem:InitLoadPool(self.ItemRoot);
    end
    local bagNum = PropMgr.TypeIdByNum(item.k);
    self.CanOpen = bagNum >= item.v;
    local str = string.format("%d/%d",bagNum,item.v);
    self.NeedItem:UpData(item.k, str, nil, 0.9);
end

--清除物品
function My:ClearItem()
	if self.NeedItem ~= nil then
        self.NeedItem:DestroyGo();
        ObjPool.Add(self.NeedItem);
        self.NeedItem = nil;
    end
end

--清除
function My:Clear()
    self.CanOpen = nil;
    self.part = nil;
    self:ClearItem();
end