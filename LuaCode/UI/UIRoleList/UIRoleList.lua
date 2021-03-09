UIRoleList = UIBase:New{Name="UIRoleList"}
local My = UIRoleList;
My.ItemList = {}
local GO = UnityEngine.GameObject;

function My:InitCustom(go)
    local name = "UIRoleList";
	local trans = self.root;
    local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;
    self.Info = TF(trans,"Info",name);
    self.Tween = CG(TweenPosition,trans,"Info/Tween",name,false);
    self.Table = CG(UITable,trans,"Info/Tween/ScrollView/Table",name,false);
    self.Item = TF(trans,"Info/Tween/ScrollView/Table/Item",name);
    self.Item:SetActive(false);
    self.BossItem = TF(trans,"Info/Tween/ScrollView/Table/BossItem",name);
    self.BossItem:SetActive(false);
    self.BlgItem = TF(trans,"Info/Tween/ScrollView/Table/BlgItem",name);
    self.BlgItem:SetActive(false);
    self.FwdSpr = TF(trans,"Info/Tween/ShowBtn/Sprite",name);
    UC(trans,"Info/Tween/ShowBtn",name,self.ShowBtnC,self);
    self.show = false;
    local saveZone = User:IsInSaveZone();
    if saveZone == false then
        self:ShowBtnC(nil);
    end
end

function My:OpenCustom()
    self:SetItems();
    self:AddLsnr();
end

function My:CloseCustom()
    self:RmLnsr();
end

--添加监听
function My:AddLsnr()
    RoleList.eCreate:Add(self.Create,self);
    RoleList.eRemove:Add(self.Remove,self);
    RoleList.eSetBelonger:Add(self.UpdateBlg,self);
    RoleList.eRcvBelonger:Add(self.RecoverBlg,self);
    RoleList.eSelfChgTmOrFml:Add(self.CreateItems,self);
    AtkInfoMgr.eUpdateAtk:Add(self.SetAtk,self);
    UIMainMenu.eHide:Add(self.RespBtnHide, self);
    local EH = EventHandler;
    local EM = EventMgr;
    self.OnEtZS = EH(self.EnterSaveZone,self);
    EM.Add("EnterSaveZone",self.OnEtZS);
    self.OnExtZS = EH(self.ExitSaveZone,self);
    EM.Add("ExitSaveZone",self.OnExtZS);
    EventMgr.Add("OnChangeScene",self.OnChangeScene);
end

--移除监听
function My:RmLnsr()
    RoleList.eCreate:Remove(self.Create,self);
    RoleList.eRemove:Remove(self.Remove,self);
    RoleList.eSetBelonger:Remove(self.UpdateBlg,self);
    RoleList.eRcvBelonger:Remove(self.RecoverBlg,self);
    RoleList.eSelfChgTmOrFml:Remove(self.CreateItems,self);
    AtkInfoMgr.eUpdateAtk:Remove(self.SetAtk,self);
    UIMainMenu.eHide:Remove(self.RespBtnHide, self);
    local EH = EventHandler;
    local EM = EventMgr;
    EM.Remove("EnterSaveZone",self.OnEtZS);
    EM.Remove("ExitSaveZone",self.OnExtZS);
    EventMgr.Remove("OnChangeScene",self.OnChangeScene);
end
--显示
function My.OnChangeScene()
    My:RespBtnHide(true)
end
--进入安全区
function My:EnterSaveZone()
    if self:GetUIState() == false then
        return;
    end
    self.show = false;
    self.Tween:PlayForward();
    self:SetFwdSpr();
end

--出去安全区
function My:ExitSaveZone()
    if self:GetUIState() == false then
        return;
    end
    self.show = true;
    self.Tween:PlayReverse();
    self:SetFwdSpr();
end

--获取面板显示状态
function My:GetUIState()
    if self.root == nil then
        return false;
    end
    if self.root.gameObject.activeSelf == false then
        return false;
    end
    return true;
end

--点击显示隐藏
function My:ShowBtnC(go)
    if self.show == true then
        self.show = false;
        self.Tween:PlayForward();
    else
        self.show = true;
        self.Tween:PlayReverse();
    end
    self:SetFwdSpr();
end

--设置方向图片
function My:SetFwdSpr()
    if self.FwdSpr == nil then
        return;
    end
    local show = self.show;
    local angles = nil;
    if show == true then
        angles = Vector3.zero;
    else
        angles = Vector3.New(0,0,180);
    end
    local sprTrans = self.FwdSpr.transform;
    sprTrans.localEulerAngles = angles;
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

--设置boss信息
function My:SetBossInfo(info)
    go = self:SetItemGo(self.BossItem,info.id);
    go.name = string.format("1%s", info.id);
    self:SetItemInfo(info,go,3,false);
end

--还原归属者成竞争者
function My:RecoverBlg()
    result = RoleList.ExistBlg();
    if result == true then
        local blg = RoleList.bossBelonger;
        local id = blg.id;
        self:Destroy(id);
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
        local go = self:SetItemGo(self.BlgItem,id);
        go.name = string.format("2%s", id);
        result = AtkInfoMgr.IsAtker(id);
        if result == true then
            self:SetItemInfo(info,go,1,true);
            return;
        end
        local isTmOrFml = info.isTeamOrFml;
        local roleInfo = RoleList.List[id];
        if roleInfo ~= nil then
            isTmOrFml = roleInfo.isTeamOrFml;
        end
        if isTmOrFml == true then
            self:SetItemInfo(info,go,2,false);
            return;
        end
        self:SetItemInfo(info,go,3,false);
    end
end

--设置角色单位信息
function My:SetRoleInfo(info)
    local id = info.id;
    go = self:SetItemGo(self.Item,id);
    result = AtkInfoMgr.IsAtker(id);
    if result == true then
        go.name = string.format("3%s", id);
        self:SetItemInfo(info,go,1,true);
        return;
    end
    if info.isTeamOrFml == true then
        go.name = string.format("5%s", id);
        self:SetItemInfo(info,go,2,false);
        return;
    end
    go.name = string.format("4%s", id);
    self:SetItemInfo(info,go,3,false);
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
    local itemGo = self.ItemList[id];
    if itemGo ~= nil then
        return itemGo;
    end
    go = self:CloneItem(go);
    self.ItemList[id] = go;
    local UCS = UITool.SetLsnrSelf;
    UCS(go.transform,self.ClickItem,self, nil, false);
    return go;
end

--设置条目
function My:SetItem(info)
    local id = info.id;
    local result = RoleList.IsMons(info);
    if result == true then
        self:SetBossInfo(info);
        return;
    end
    result = RoleList.IsBelonger(id);
    if result == true then
        self:SetBlgInfo();
        return;
    end
    self:SetRoleInfo(info);
end

--设置条目信息
function My:SetItemInfo(info,go,colType,isAtker)
    local name = self.root.name;
    local CG = ComTool.Get;
    local trans = go.transform;
    local levelLbl = CG(UILabel,trans,"Level",name,false);
    local nameLbl = CG(UILabel,trans,"Name",name,false);
    local sltSprite = CG(UISprite,trans,"Select",name,false);
    sltSprite.gameObject:SetActive(false);
    self:SetLabel(info,levelLbl,nameLbl);
    self:SetColor(levelLbl,nameLbl,colType);
    self:SetAtkFlg(go,isAtker);
end

--设置文本标签
function My:SetLabel(info,levelLbl,nameLbl)
    if info == nil then
        return;
    end
    local level = info.level;
    if level == 0 then
        levelLbl.gameObject:SetActive(false);
    else
        levelLbl.text = "LV." .. tostring(info.level);
    end
    nameLbl.text = tostring(info.name);
end

--设置颜色
function My:SetColor(levelLbl,nameLbl,colType)
    local col = RoleList.colors[colType];
    levelLbl.color = col;
    nameLbl.color = col;
end

--设置攻击标志
function My:SetAtkFlg(go,isAtker)
    local name = self.root.name;
    local TF = TransTool.FindChild;
    local trans = go.transform;
    local flag = TF(trans,"AtkFlag",name);
    if isAtker == true then
        flag:SetActive(true);
    else
        flag:SetActive(false);
    end
end

--设置攻击者
function My:SetAtk(id,add)
    local go = self.ItemList[id];
    if go == nil then
        return;
    end
    local colType = nil;
    if add == true then
        colType = 1;
    else
        colType = 3;
        local info = RoleList.List[id];
        if info ~= nil and info.isTeamOrFml == true then
            colType = 2;
        end
    end
    self:SetItemInfo(nil,go,colType,add);
end

--移除
function My:Remove(id)
    self:Destroy(id);
    self.Table:Reposition();
end

--銷毀對象
function My:Destroy(id)
    if self.curSltSp ~= nil then
        self.curSltSp.gameObject:SetActive(false);
        self.curSltSp = nil;
    end
    local go = self.ItemList[id];
    if go == nil then
        return;
    end
    go.transform.parent = nil;
    Destroy(go);
    self.ItemList[id] = nil;
end

--响应展开按钮
function My:RespBtnHide(value)
    self.Info.gameObject:SetActive(value);
    if value == false then
        return;
    end
    if self.Table ~= nil then
        self.Table:Reposition();
    end
    local saveZone = User:IsInSaveZone();
    if saveZone == false then
        self:ExitSaveZone();
    else
        self:EnterSaveZone();
    end
end

--点击条目
function My:ClickItem(go)
    local id = go.name;
    id = string.sub( id,2,#id);
    if id == nil then
        return;
    end
    if self:ChkItem(id) == false then
        return;
    end
    if LuaTool.IsNull(self.curSltSp) == false then
        self.curSltSp.gameObject:SetActive(false);
    end
    local CG = ComTool.Get;
    local trans = go.transform;
    local sltSprite = CG(UISprite,trans,"Select",name,false);
    sltSprite.gameObject:SetActive(true);
    self.curSltSp = sltSprite;
    local uid = User.MapData.UID;
    uid = tostring(uid);
    if id == uid then
        return;
    end
    local tarId = tonumber(id);
    self.tarId = tarId;
    local checkTip = self:CheckTip();
    if checkTip == false then
        SelectRoleMgr.instance:StartNavPath(tarId,1);
        return;
    end
    local info = RoleList.List[id];
    if info == nil then
        return;
    end
    local isMons = RoleList.IsMons(info);
    if isMons == true then
        SelectRoleMgr.instance:StartNavPath(tarId,1);
        return;
    end
    if info.isTeamOrFml == true then
        local str = "此人是队友或盟友，是否要攻击？";
        MsgBox.ShowYes(str,self.YesCb,self,"确定",self.NoCb,self,"取消");
        return;
    end
    self:BegAtk(FightStatus.ForceMode);
end

--检查提示
function My:CheckTip()
    local fightType = User.instance.MapData.FightType;
    if fightType == FightStatus.PeaceMode then
        return true;
    elseif fightType == FightStatus.ForceMode then
        return true;
    end
    return false;
end

--开始攻击
function My:BegAtk(fightType)
    local canHit = User:CanHitSafeUnit(self.tarId);
    if canHit == false then
        local msg = "目标在安全区内无法前往攻击";
        UITip.Log(msg)
        return;--目标在安全区内，不切换模式直接返回
    end
    local result = self:ChangeMod(fightType);
    if result == false then
        return;
    end
    SelectRoleMgr.instance:StartNavPath(self.tarId,1);
end

function My:YesCb()
    local fightType = FightStatus.AllMode;
    self:BegAtk(fightType);
end

function My:NoCb()

end

--切换成模式
function My:ChangeMod(fightType)
    local curFT = User.instance.MapData.FightType;
    if fightType == curFT then
        return true;
    end

    local sceneId = tostring(User.instance.SceneId);
	if sceneId == "0" then
		return false;
    end
    local sceneInfo = SceneTemp[sceneId]; 
	if sceneInfo == nil then
		return false;
	end
	
    local fightmodels = sceneInfo.fightmode;
    if fightmodels == nil then
        local text = "此地图没有配置战斗模式";
        UITip.Error(text);
        return false;
    end
	local result = false;
	for k in pairs(fightmodels) do
		if fightType == fightmodels[k] then
			result = true;
			break;
		end
	end
	if result then
        NetFightInfo.RequestChangeFightMode(fightType);
        User.instance.MapData.FightType = fightType;
        return true;
    else
        local str = "当前场景不能切换成%s战斗姿态";
        local ftStr = GetFightStatusTitle(fightType);
        local text = string.format(str,ftStr)
        UITip.Error(text);
        return false;
	end
end

--检查条目
function My:ChkItem(id)
    if self.ItemList[id] == nil  then
        self:Remove(id);
        return false;
    end
    return true;
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

return My;