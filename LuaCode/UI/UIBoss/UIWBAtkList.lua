require("UI/UIBoss/WBAtkInfo")
require("UI/UIBoss/WBAtkBossInfo")
require("UI/UIBoss/WBAtkRcvHp")
require("UI/UIBoss/NewBlgTip")
require("UI/UIBoss/WBBlgRwd")
UIWBAtkList = UIBase:New{Name ="UIWBAtkList"}

local My = UIWBAtkList;
My.ItemList = {}
My.BossInfo = WBAtkBossInfo;
My.RcvHp = WBAtkRcvHp;

My.ePlayerBeHarm = Event()

local GO = UnityEngine.GameObject;
function My:InitCustom()
    local trans = self.root;
    local name = trans.name;
    local TF = TransTool.Find;
    local CG = ComTool.Get;

    local go = TF(trans,"Info",name);
    self.anchor = ComTool.GetSelf(UIWidget, go, des)
	self.oriLeft = self.anchor.leftAnchor.absolute
    self.oriRight = self.anchor.rightAnchor.absolute

    local blg = TF(trans,"Info/CurBelong",name);
    self.CurBlg = ObjPool.Get(WBAtkInfo);
    self.CurBlg:Init(blg);
    self.CurBlg:InitBlgRwdBtn(blg);
    self.CurBlg:SetActive(false);

    self.Table = CG(UITable,trans,"Info/ScrollView/Table",name);
    self.Item = TF(trans,"Info/ScrollView/Table/Item");
    self.Item.gameObject:SetActive(false);
    
    local bossIcon = TF(trans,"Info/BossIcon",name);
    My.BossInfo:Init(bossIcon);
    local rcvHp = TF(trans,"Info/RecoveryHP",name);
    local rcvTip = TF(trans,"Info/RcvHpTip",name);
    My.RcvHp:Init(rcvHp,rcvTip);

    NewBlgTip:Init(trans);

    local wbBlgRwd = TF(trans,"BlgRwd",name);
    WBBlgRwd:Init(wbBlgRwd);

    self:ScreenChg(ScreenMgr.orient, true)
end

function My:OpenCustom()
    self:SetItems();
    self:AddLsnr();
    BossHelp:bossFindPath();
end

function My:CloseCustom()
    self:RmLnsr();
    WBBlgRwd:Close();
end

--添加监听
function My:AddLsnr()
    RoleList.eCreate:Add(self.Create,self);
    RoleList.eRemove:Add(self.Remove,self);
    RoleList.eSetBelonger:Add(self.UpdateBlg,self);
    RoleList.eRcvBelonger:Add(self.RecoverBlg,self);
    RoleList.eSelfChgTmOrFml:Add(self.CreateItems,self);
    RoleList.eChgHp:Add(self.ChgHp,self);
    AtkInfoMgr.eChgTarget:Add(self.ChgTarget,self);
    AtkInfoMgr.eUpdateAtk:Add(self.SetAtk,self);
    AtkInfoMgr.eSelfDead:Add(self.CreateItems,self);
    WBChgOwner.eChgOwner:Add(NewBlgTip.SetTip,NewBlgTip);
    ScreenMgr.eChange:Add(self.ScreenChg,self);
    My.RcvHp:AddLsnr();
end

--移除监听
function My:RmLnsr()
    RoleList.eCreate:Remove(self.Create,self);
    RoleList.eRemove:Remove(self.Remove,self);
    RoleList.eSetBelonger:Remove(self.UpdateBlg,self);
    RoleList.eRcvBelonger:Remove(self.RecoverBlg,self);
    RoleList.eSelfChgTmOrFml:Remove(self.CreateItems,self);
    RoleList.eChgHp:Remove(self.ChgHp,self);
    AtkInfoMgr.eChgTarget:Remove(self.ChgTarget,self);
    AtkInfoMgr.eUpdateAtk:Remove(self.SetAtk,self);
    AtkInfoMgr.eSelfDead:Remove(self.CreateItems,self);
    WBChgOwner.eChgOwner:Remove(NewBlgTip.SetTip,NewBlgTip);
    ScreenMgr.eChange:Remove(self.ScreenChg,self);
    My.RcvHp:RmLnsr();
end

function My:ScreenChg(orient, init)
    local reset = UITool.IsResetOrient(orient)
	UITool.SetLiuHaiAbsolute(self.anchor, true, reset, self.oriLeft,self.oriRight)
end

--血量更新
function My:ChgHp(id)
    local ownerId = User.MapData.UIDStr;
    local blg = RoleList.IsBelonger(ownerId);
    local info = nil;
    if blg == true then
        info = RoleList.bossBelonger;
    else
        info = RoleList.List[id];
    end
    if info == nil then
        return;
    end
    local itemInfo = nil;
    local isBlg = RoleList.IsBelonger(id);
    if isBlg == true then
        itemInfo = self.CurBlg;
    else
        itemInfo = My.ItemList[id];
    end
    if itemInfo == nil then
        return;
    end
    itemInfo:UpdateHp(info.hp,info.maxHp);
end

--锁定攻击目标改变
function My:ChgTarget(id,add)
    local isBlg = RoleList.IsBelonger(id);
    if add == false then
        if isBlg == true then
            if self.CurBlg ~= nil then
                self.CurBlg:ResetState();
            end
            self:SetBlgInfo();
        else
            local info = RoleList.List[id];
            if info ~= nil then
                local isMons = RoleList.IsMons(info);
                if isMons == true then
                    return;
                end
                local itemInfo = self.ItemList[id];
                if itemInfo ~= nil then
                    itemInfo:ResetState();
                end
                self:SetRoleInfo(info);
            end
        end
    else
        if isBlg == true then
            self:SetBlgInfo();
        else
            local info = RoleList.List[id];
            if info ~= nil then
                local isMons = RoleList.IsMons(info);
                if isMons == true then
                    return;
                end
                self:SetRoleInfo(info);
            end
        end       
    end
end

--设置条目
function My:SetItems()
    self:ClearItem();
    self:CreateItems();
end

--创建所有条目
function My:CreateItems()
    for k,v in pairs(RoleList.List) do
        self:Create(v);
    end
    local bBlg = RoleList.bossBelonger;
    if bBlg == nil then
        return;
    end
    local ownerId = User.MapData.UIDStr;
    if bBlg.id ~= ownerId then
        return;
    end
    self:UpdateBlg();
end

--还原归属者成竞争者
function My:RecoverBlg()
    result = RoleList.ExistBlg();
    if result == true then
        local blg = RoleList.bossBelonger;
        local id = blg.id;
        self.CurBlg:ResetData();--隐藏和重置归属者数据
        local info = RoleList.List[id];
        if info ~= nil then
            self:SetRoleInfo(info);
        end
    end
end

--更新归属者
function My:UpdateBlg()
    self:SetBlgInfo();
    if self.Table ~= nil then
        self.Table:Reposition();
    end
end

--设置归属者信息
function My:SetBlgInfo()
    local id = nil;
    result = RoleList.ExistBlg();
    if result == true then
        local info = RoleList.bossBelonger;
        id = info.id;
        self:Destroy(id);--删除在竞争者列表条目
        local roleInfo = RoleList.List[id];
        if roleInfo ~= nil then
            info = roleInfo;
        else
            local hp = 0;
            local maxHp = 100;
            local sex = 0;
            if id == User.MapData.UIDStr then
                hp = User.MapData.Hp;
                hp = RoleAssets.LongToNum(hp);
                maxHp = User.MapData.MaxHp;
                maxHp = RoleAssets.LongToNum(maxHp);
                sex = User.MapData.Sex;
            end
            info.hp = hp;
            info.maxHp = maxHp;
            info.sex = sex;
        end
        local curBlg = self.CurBlg;
        curBlg:UpdateData(info);
        local nameId = string.format("2%s", id);
        curBlg:SetGoName(nameId);
        result = AtkInfoMgr.IsAtker(id);
        if result == true then
            curBlg:SetItemInfo(info,1,true);
            return;
        end
        local isTmOrFml = info.isTeamOrFml;
        local roleInfo = RoleList.List[id];
        if roleInfo ~= nil then
            isTmOrFml = roleInfo.isTeamOrFml;
        end
        if isTmOrFml == true then
            curBlg:SetItemInfo(info,2,false);
            return;
        end
        curBlg:SetItemInfo(info,3,false);
    end
end

--设置角色单位信息
function My:SetRoleInfo(info)
    local id = info.id;
    local nameId = nil;
    local colType = nil;
    local isAtker = false;
    local itemInfo = self:SetItemGo(self.Item,id);
    itemInfo:UpdateData(info);
    result = AtkInfoMgr.IsAtker(id);
    if result == true then
        colType = 1;
        isAtker = true;
        nameId = string.format("3%s", id);
    elseif info.isTeamOrFml == true then
        colType = 2;
        isAtker = false;
        nameId = string.format("5%s", id);
    else
        colType = 3;
        isAtker = false;
        nameId = string.format("4%s", id);
    end
    itemInfo:SetGoName(nameId);
    itemInfo:SetItemInfo(info,colType,isAtker);
end

--创建
function My:Create(info)
    if info == nil then
        return;
    end
    self:SetItem(info);
    self.Table:Reposition();
end

--设置条目对象
function My:SetItemGo(go,id)
    local itemInfo = self.ItemList[id];
    if itemInfo ~= nil then
        return itemInfo;
    end
    go = self:CloneItem(go);
    local info = ObjPool.Get(WBAtkInfo);
    info:Init(go.transform);
    self.ItemList[id] = info;
    return info;
end

--设置条目
function My:SetItem(info)
    local id = info.id;
    local result = RoleList.IsMons(info);
    if result == true then
        My.BossInfo:SetBossID(id);
        return;
    end
    result = RoleList.IsBelonger(id);
    if result == true then
        self:SetBlgInfo();
        return;
    end
    self:SetRoleInfo(info);
end

--设置攻击者
function My:SetAtk(id,add)
    self:TriggerGuide(id,add)
    local info = RoleList.List[id];
    result = RoleList.IsBelonger(id);
    if result == true then
        self:SetBlgInfo();
    else
        if info ~= nil then
            self:SetRoleInfo(info);
            self.Table:Reposition();
        end
    end
end

--触发引导
function My:TriggerGuide(id,add)
    if User.SceneId ~= 90002 then return end
    if not add then return end
    self.ePlayerBeHarm()
end

--移除
function My:Remove(id)
    self:Destroy(id);
    self.Table:Reposition();
end

--銷毀對象
function My:Destroy(id)
    local itemInfo = self.ItemList[id];
    if itemInfo == nil then
        return;
    end
    itemInfo:Destroy();
    self.ItemList[id] = nil;
end

--清除条目
function My:ClearItem()
    if self.ItemList == nil then
        return;
    end
    for k,v in pairs(self.ItemList) do
        self:Remove(k);
    end
end

function My:ConDisplay()
	do return true end
end

function My:Clear()
    self:ClearItem();
end

--克隆对象
function My:CloneItem(go)
    local root = GO.Instantiate(go);
    root.name = go.name;
    root.transform.parent = go.transform.parent;
    root.transform.localPosition = Vector3.zero;
    root.transform.localScale = Vector3.one;
    root.gameObject:SetActive(true);
    return root;
end

--更新
function My:Update()
    WBAtkRcvHp:Update();
end

return My;