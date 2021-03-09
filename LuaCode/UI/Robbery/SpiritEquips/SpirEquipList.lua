SpirEquipList = {Name = "SpirEquipList"}
local My = SpirEquipList;
My.cellDic = {}
My.bgDic = {}
My.addDic = {}
My.lockDic = {}
My.curSpirId = 0;

function My:Init(trans)
    local name = trans.name;
    local TF = TransTool.Find;
    self.grid = TF(trans,"Grid",name);

    self:InitCell();
end

--初始化格子
function My:InitCell()
    local TFC=TransTool.FindChild;
	local CG=ComTool.Get;
	local UC = UITool.SetLsnrSelf;
	for i=1,10 do
		local go = TFC(self.grid,"ItemCell"..i);
		local trans = go.transform;
		local part = RobEquipsMgr.parts[i];
		go.name=part;
		local cell = ObjPool.Get(Cell);
		cell:Init(go);
		My.cellDic[part]=cell;
		cell.eClickCell:Add(self.ClickCell,self);
        
		local bg = CG(UILabel,trans,"part",self.Name,false);
        My.bgDic[part]=bg;

		local lock = CG(UILabel,trans,"Lock",self.Name,false);
        My.lockDic[part] = lock;

		if tonumber(part)==9 or tonumber(part)==10 then 
			local add = TFC(trans,"add");
			My.addDic[part]=add;
			add:SetActive(false);
			UC(add,self.ClickAdd,self,self.Name);
		end
	end
end

--添加事件监听
function My:AddLsnr()
	SpItemCom.eClickCell:Add(self.SetSelectSpir,self);
	RobberyMgr.eUpdateStateInfo:Add(self.UpdateRob,self);
	RobEquipsMgr.eAddEquip:Add(self.AddEquip,self);
	RobEquipsMgr.eRmEquip:Add(self.RmEquip,self);
	RobEquipsMgr.eOpenLock:Add(self.OpenLock,self);
end

--关闭事件监听
function My:RemoveLsnr()
	SpItemCom.eClickCell:Remove(self.SetSelectSpir,self);
	RobberyMgr.eUpdateStateInfo:Remove(self.UpdateRob,self);
	RobEquipsMgr.eAddEquip:Remove(self.AddEquip,self);
	RobEquipsMgr.eRmEquip:Remove(self.RmEquip,self);
	RobEquipsMgr.eOpenLock:Remove(self.OpenLock,self);
end

--设置装备
function My:SetEquips()
	local curSpirId = My.curSpirId;
	local dic = RobEquipsMgr.equipDic;
	equips = dic[curSpirId];
	if equips == nil then
		return;
	end
	for k,v in pairs(equips) do
		local part = tostring(k);
		local equipId = v.type_id;
		local cell = My.cellDic[part];
		cell:UpData(equipId,1);
		self:SetDesBgState(part,false);
	end
end

--清理装备
function My:CleanEquips()
	for k,v in pairs(My.cellDic) do
		v:Clean();
	end
end

--添加装备
function My:AddEquip(spirId,part,equipId)
	if spirId ~= My.curSpirId then
		return;
	end
	part = tostring(part);
	local cell = My.cellDic[part];
	cell:UpData(equipId,1);
	self:SetLockState(part,false);
	self:SetDesBgState(part,false);
end

--删除装备
function My:RmEquip(spirId,part,equipId)
	if spirId ~= My.curSpirId then
		return;
	end
	part = tostring(part);
	local cell = My.cellDic[part];
	cell:Clean();
	self:SetDesBgState(part,true);
end

--设置选择战灵
function My:SetSelectSpir(spirCfg,lv)
	if spirCfg == nil then
		return;
	end
	self:Open();
end

function My:UpdateRob()
	self:Open();
end

--设置当前战灵ID
function My:SetCurSpirId(spirId)
	My.curSpirId = spirId;
end

--设置锁
function My:SetLocks()
	local lockDic = My.lockDic;
	for k,v in pairs(lockDic) do
		self:SetLock(k,v);
	end
end

--开锁
function My:OpenLock(spirId,part)
	if My.curSpirId ~= spirId then
		return;
	end
	part = tostring(part);
	local lock = My.lockDic[part];
	self:SetLock(part,lock);
end

--设置锁
function My:SetLock(part,lock)
	if lock == nil then
		return;
	end
	local REMgr = RobEquipsMgr;
	local isOpenLock = REMgr.LockIsOpen(My.curSpirId,part);
	lock.gameObject:SetActive(not isOpenLock);
	self:SetAddState(part,isOpenLock);
	if isOpenLock == false then
		local curSpirId = My.curSpirId;
		local isStfRobId = REMgr.IsStfRobId(curSpirId,part);
		local text = "";
		if isStfRobId == false then --满足境界部位的境界描述为“”
			text = REMgr.GetOpenDes(curSpirId,part);
		end
		lock.text = text;
	end
end

--显示所有锁
function My:ShowLocks()
	local lockDic = My.lockDic;
	for k,v in pairs(lockDic) do
		v.gameObject:SetActive(true);
	end
end

--显示锁
function My:SetLockState(part,active)
	local lockDic = My.lockDic;
	if lockDic == nil then
		return;
	end
	local lock = lockDic[part];
	if lock == nil then
		return;
	end
	lock.gameObject:SetActive(active);
end

--显示所有背景描述
function My:ShowAllBgs()
	local bgDic = My.bgDic;
	for k,v in pairs(bgDic) do
		self:ShowDesBg(k,v,true);
	end
end

--设置描述背景
function My:SetDesBgState(part,active)
	local bg = My.bgDic[part];
	self:ShowDesBg(part,bg,active);
end

--显示背景描述
function My:ShowDesBg(part,bg,active)
	if bg == nil then
		return;
	end
	bg.gameObject:SetActive(active);
	if active == false then
		return;
	end
	local text = UIMisc.WearParts(tonumber(part));
	bg.text = text;
end

--关闭所有描述背景
function My:CloseAllDesBg()
	local bgDic = My.bgDic;
	for k,v in pairs(bgDic) do
		self:CloseDesBg(k,v);
	end
end

--关闭背景描述
function My:CloseDesBg(part,bg)
	if bg == nil then
		return;
	end
	bg.gameObject:SetActive(false);
end

--设置加号状态
function My:SetAddState(part,active)
	if part ~= "9" and part ~= "10" then
		return;
	end
	local add = My.addDic[part];
	local isNull = LuaTool.IsNull(add);
	if isNull ~= true then
		if active == true then
			local has = RobEquipsMgr.GetPartEquips(part);
			if has ~= nil then
				active = false;
			end 
		end
		add:SetActive(active);
	end
end

--打开界面
function My:Open()
	self:SetCurSpirId(SpItemCom.curSpirId);
	self:SetLocks();
	self:ShowAllBgs();
	self:AddLsnr();
	self:CleanEquips();
	self:SetEquips();
	SpiriteEquips:RfrSpirEqRed();
end

--关闭界面
function My:Close()
	SpirEquipOpen:Close();
	self:ShowLocks();
	self:ShowAllBgs();
	self:RemoveLsnr();
	self:CleanEquips();
end

--点击加号
function My:ClickAdd(go)
	local lv = User.instance.MapData.Level;
	local max = 30;
	local OpenName = UIGetItem.Name;
	local name = go.transform.parent.name;
	if lv<max then
		 return;
	end
	self.clickPart=name;
	UIMgr.Open(OpenName,self.OpenGetItemCb,self);
end

--打开获取途径UI返回
function My:OpenGetItemCb(name)
	local ui = UIMgr.Get(name)
	if ui then 
		ui:UpData(self.clickPart)
	end
end

--点击格子
function My:ClickCell(go)
	local part = go.name;
	local active = My.GetLockState(part);
	if active == true then
		local isStfRobId = RobEquipsMgr.IsStfRobId(My.curSpirId,part);
		if isStfRobId == true then
			SpirEquipOpen:Open(part);
		else
			local msg = My.GetLockOpenDes(part);
			msg = msg .. "境界开启装备栏";
			UITip.Log(msg);
		end
		return;
	end
	if part == "9" or part == "10" then
		local equips = RobEquipsMgr.GetPartEquips(part);
		if equips == nil then
			return;
		end
	end
	SpirEquipPack:Open(part);
end

--获取锁状态
function My.GetLockState(part)
	local lock = My.lockDic[part];
	local active = false;
	if lock ~= nil then
		local lockG = lock.gameObject;
		active = lockG.activeSelf;
	end
	return active;
end

--获取开锁描述
function My.GetLockOpenDes(part)
	local des = "数据异常";
	local lock = My.lockDic[part];
	if lock ~= nil then
		des = lock.text;
	end
	return des;
end

--是否有解锁装备
function My.HasUnlockEquip()
	for k,v in pairs(My.lockDic) do
		local active = My.GetLockState(k);
		if active == false then
			return true;
		end
	end
	return false;
end

--清除
function My:Clear()
	
end

--释放
function My:Dispose()
	self:RemoveLsnr();
	TableTool.ClearDic(My.bgDic);
	TableTool.ClearDic(My.lockDic);
	TableTool.ClearDic(My.addDic);
	TableTool.ClearDicToPool(My.cellDic);
end