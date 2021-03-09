--[[
淬炼
--]]
require("UI/UIEquip/HoningCell")
require("UI/UIEquip/HonPreview")
require("UI/UIEquip/HnEPanel")

Tg4=Super:New{Name="Tg4"}
local My=Tg4
--vip解锁孔需要的vip等级
My.VipUnLock = 7;

function My:Ctor()
	--当前装备孔格子列表
	self.cellList={}
	--消耗材料格子列表
	self.costItmList={}
end

--获取淬炼度
function My.GetHonVal(honId)
	if honId == nil then
		return 0;
	end
	local id = tostring(honId);
	local info = HonInfo[id];
	if info == nil then
		return 0;
	end
	return info.honPer;
end

function My:Init(go)
	local TF=TransTool.FindChild
	local CG = ComTool.Get
	local UCS = UITool.SetLsnrSelf
	local UC = UITool.SetLsnrClick;
	local trans=go.transform
	self.go=go

	for i=1,6 do
		local cell = ObjPool.Get(HoningCell)
		cell:Init(TF(trans,"bg/d"..i),i,self.Name)
		self.cellList[i]=cell
		cell.eClickGem:Add(self.ClickCell,self);
		cell.eRefreshHonAttr:Add(self.RefreshHonAttr,self);
	end

	self.Tip = TF(trans,"Tip",self.Name);
	self.HonBtnGo = TF(trans,"HoningBtn",self.Name);
	UCS(self.HonBtnGo,self.HonClick,self,"HoningBtn", false);
	self.CurHon = CG(UILabel,trans,"HoningAttr/CurHoning",self.Name);
	self.NextHon = CG(UILabel,trans,"HoningAttr/NextHoning",self.Name);
	self.CurHonTbl = CG(UITable,trans,"HoningAttr/CurAttr",self.Name);
	self.NextHonTbl = CG(UITable,trans,"HoningAttr/NextAttr",self.Name);
	self.NdItemsTbl = CG(UITable,trans,"HoningAttr/NeedItems",self.Name);
	self.HonHgest = TF(trans,"HoningAttr/HonHeightest",self.Name);
	self.Attr = TF(trans,"HoningAttr/Attr",self.Name);
	self.Attr:SetActive(false);
	
	self.cell=ObjPool.Get(UIItemCell)
	self.cell:InitLoadPool(trans,nil,nil,nil,nil,Vector3.New(45.6,-33.7,0))
	
	local prv = TF(trans,"Preview",self.Name);
	HonPreview:Init(prv);
    UC(trans,"PrvBtn",self.Name,self.OpenHonPrv,self);
    
    self.lPanel = ObjPool.Get(HnEPanel)
    self.lPanel:Init(TF(trans, "left"))
    self.lPanel:InitEquip(4,tp)	
end

function My:SetEvent(fn)
    EquipMgr.eHoning[fn](EquipMgr.eHoning,self.RfRed,self);
    UIEquipCell.eClick[fn](UIEquipCell.eClick,self.OnClickCell,self)
end

function My:OnClickCell(part)
    self.part=part
	local tb = EquipMgr.hasEquipDic[part]
	self:UpData(tb,part)
end

--打开淬炼预览
function My:OpenHonPrv(go)
	HonPreview.equipPart = self.part;
    HonPreview:Open();
end

--淬炼点击
function My:HonClick(go)
	local honCell = self.CurHonCell;
	if honCell == nil then
		return;
	end
	local isPropEnough = self:ChkItems()
	if isPropEnough == false then
		EquipMgr.ReqHoning(self.type_id,honCell.index);
		return
	end
	local result = self:CanHoning();
	if result == false then
		return;
	end
	EquipMgr.ReqHoning(self.type_id,honCell.index);
end

--点击镶嵌格子
function My:ClickCell(honCell)
	if honCell == nil then
		return;
	end
	
	if self.CurHonCell ~= nil then
		if self.CurHonCell == honCell then
			self.CurHonCell:Select(true);
			return;
		end
		self.CurHonCell:Select(false);
	end
	self.CurHonCell = honCell;
	honCell:Select(true);

	self:RefreshHonAttr(honCell);
end

--更新淬炼属性
function My:RefreshHonAttr(honCell)
	if honCell == nil then
		return;
	end

	local gemType = honCell.gemType;
	if gemType == nil then
		return;
	end
	local honId = honCell.honId;
	local typeId = honCell.type_id;
	self:SetCurHon(honId);
	self:SetNextHon(gemType,typeId,honId);
end

--更新装备数据
function My:UpData(tb,part)
	-- if self.type_id == tb.type_id then
	-- 	return;
	-- end
	self.type_id=tb.type_id
	for i,v in ipairs(self.cellList) do
		v:Clean()
		v:SetHoles(part);
		v:AddRedUp(part)
		self:ShowHolesInfo(tb,v);
	end

	local item = ItemData[tostring(tb.type_id)]
	if(item==nil) then
		iTrace.eError("提示","道具表为空  type_id：".. self.type_id)
		return
	end
	self.cell:TipData(tb)
	self:SltCell(part);
end

--更细红点
--part 装备部位
--hIndex 淬炼孔索引
--hHonId 淬炼Id
function My:RfRed(equipId,part,hIndex,hHonId)
	if equipId ~= self.type_id then
		return;
	end
	for i,v in ipairs(self.cellList) do
		v:AddRedUp(part)
		if i == hIndex then
			v:UpdHonPer(hIndex,hHonId);
		end
	end
end

--选择淬炼格子
function My:SltCell(part)
	local slt = self:SltHonCell(part);
	if slt == true then
		return;
	end
	self:SltFirstCell();
end

--选择可淬炼格子
function My:SltHonCell(part)
	self:ClearCurHonCell();
	part = tostring(part);
	equipTb = EquipMgr.hasEquipDic[part];
	if equipTb == false then
		return false;
	end
	local stDic = equipTb.stDic;
	local honDic = equipTb.honDic;
	local index = EquipMgr.ChkHonHole(stDic,honDic);
	local cell = self.cellList[index];
	if cell == nil then
		self.CurHonCell = nil;
		return false;
	end
	self:SetRightShow(true);
	self:ClickCell(cell);
	return true;
end

--按顺序选择第一个镶嵌的格子
function My:SltFirstCell()
	self:ClearCurHonCell();
	for i,v in ipairs(self.cellList) do
		if v.type_id ~= nil then
			self:SetRightShow(true);
			self:ClickCell(v);
			return;
		end
	end
	self:SetRightShow(false);
end

--显示装备孔信息
function My:ShowHolesInfo(tb, honCell)
	if honCell == nil then
		return;
	end
	local index = tostring(honCell.index);
	local honDic = tb.honDic;
	local gemDic = tb.stDic;
	local gemId = gemDic[index];
	local honId = honDic[index];
	honCell:UpData(gemId,honId);
end

--设置当前淬炼度
function My:SetCurHon(honId)
	if honId == nil or honId == 0 then--未淬炼
		self.CurHon.text = "0%";
	else
		self:SetHonPer(self.CurHon,honId);
	end

	local honTrans = self.CurHonTbl.transform;
	self:SetHonAttr(honTrans,honId);
	self.CurHonTbl:Reposition();
end

--设置下一级淬炼度
function My:SetNextHon(gemType,gemTypeId,honId)
	if honId == nil or honId == 0 then--未淬炼
		honId = gemType * 100;
	end
	honId = honId + 1;
	local id = tostring(honId);
	local info = HonInfo[id];
	local hGo = self.NextHon.gameObject;
	if info == nil then
		honId = nil;
		self:SetGoState(hGo,false);
		self:SetGoState(self.HonHgest,true);

		self:SetGoState(self.NextHonTbl.gameObject,false);
		self:SetGoState(self.NdItemsTbl.gameObject,false);

		self:SetGoState(self.HonBtnGo,false);
		self:SetGoState(self.Tip,false);
		return;
	else
		self:SetGoState(hGo,true);
		self:SetGoState(self.HonHgest,false);
		self:SetHonPer(self.NextHon,honId);
		local stf = self:StfGemLv(gemTypeId);
		if stf == true then
			self:SetGoState(self.HonBtnGo,true);
			self:SetGoState(self.Tip,false);
		else
			self:SetGoState(self.HonBtnGo,false);
			self:SetGoState(self.Tip,true);
		end
	end

	local honTrans = self.NextHonTbl.transform;
	self:SetHonAttr(honTrans,honId);
	self.NextHonTbl:Reposition();
	self:SetNeedItems(info);
end

--设置淬炼度属性
function My:SetHonAttr(honTrans,honId)
	TransTool.ClearChildren(honTrans);
	if honId == nil or honId == 0 then --未淬炼
		return;
	end

	local id = tostring(honId);
	local info = HonInfo[id];
	if info == nil then
		return;
	end

	self:SetGoState(self.NextHonTbl.gameObject,true);
	if info.gemAddPer ~= nil then
		local attStr = "宝石属性";
		local addVal = info.gemAddPer/100;
		self:SetAttr(honTrans,attStr,addVal);
	end
	for k,v in pairs(info.addAttrs) do
		local attStr = PropTool.GetNameById(v.k);
		local addVal = v.v/100;
		self:SetAttr(honTrans,attStr,addVal);
	end
end

--设置属性
function My:SetAttr(parent,attStr,addVal)
	local CG = ComTool.Get;
	local trans = self:CloneAttr(parent);
	local title = CG(UILabel,trans,"AttrTitle",trans.name);
	local addPer = CG(UILabel,trans,"AttrPer",trans.name);
	title.text = attStr .. "：";
	addPer.text = "+" .. addVal .. "%";
end

--设置淬炼度
function My:SetHonPer(label,honId)
	if honId == nil then
		return;
	end
	local id = tostring(honId);
	local info = HonInfo[id];
	if info == nil then
		return;
	end
	local honVal = info.honPer;
	label.text = honVal .. "%";
end

--设置需要消耗物品
function My:SetNeedItems(honTbl)
	TableTool.ClearListToPool(self.costItmList)
	self:SetGoState(self.NdItemsTbl.gameObject,true);
	local ndIts = honTbl.needItems;
	for index,item in pairs(ndIts) do
		local id = item.k;
		local val = item.v;
		local str = self:GetCellStr(id,val);
		local cell = ObjPool.Get(UIItemCell);
		local cParent = self.NdItemsTbl.transform;
		cell:InitLoadPool(cParent,0.8,self);
		cell:UpData(id,str);
		self.costItmList[index] = cell;
	end
end

--获取格子描述
function My:GetCellStr(id,num)
	local allNum = PropMgr.TypeIdByNum(id);
	local str = nil;
	if allNum < num then
		str = "[ff0000]"..allNum.."[-]/"..num;
	else
		str = allNum.."/"..num;
	end
	return str;
end

--加载奖励格子完成
function My:LoadCD(go)
	self.NdItemsTbl:Reposition();
end

--克隆属性对象
function My:CloneAttr(parent)
	local go = GameObject.Instantiate(self.Attr);
	go:SetActive(true);
	local trans = go.transform;
	trans.parent = parent;
	trans.localPosition = Vector3.zero;
	trans.localScale = Vector3.one;
	return trans;
end

--设置属性状态
function My:SetAttState(active)
	self:SetGoState(self.CurHonTbl.gameObject,active);
	self:SetGoState(self.NextHonTbl.gameObject,active);
	self:SetGoState(self.NdItemsTbl.gameObject,active);
	self:SetGoState(self.HonBtnGo,active);
	self:SetGoState(self.Tip,active);
end

--设置当前和下一级淬炼度为0
function My:SetHonPerZero()
	self.CurHon.text = "0%";
	self.NextHon.text = "0%";
	self:SetGoState(self.HonHgest,false);
end

function My:Open()
	self:SetEvent("Add")
    self.go:SetActive(true)
    if HnEPanel.curPart then self:OnClickCell(HnEPanel.curPart) end
end

function My:Close()
	self:SetEvent("Remove")
	self.go:SetActive(false)
	self:Clear();
end

--清理数据
function My:Clear()
	self.part=nil
	self.type_id = nil;
	self:ClearCurHonCell();
end

--清理当前选中淬炼孔
function My:ClearCurHonCell()
	if self.CurHonCell ~= nil then
		self.CurHonCell:Select(false);
		self.CurHonCell = nil;
	end
end

--设置右边面板显示状态
function My:SetRightShow(active)
	self:SetAttState(active);
	if active == false then
		self:SetHonPerZero();
	end
end

--设置对象状态
function My:SetGoState(go,active)
	if go == nil then
		return;
	end
	if go.activeSelf == active then
		return;
	end
	go:SetActive(active);
end

--是否可淬炼
function My:CanHoning()
	if self.HonHgest ~= nil then
		if self.HonHgest.activeSelf == true then
			UITip.Log("当前已淬炼至最高级")
			return false;
		end
	end
	local honCell = self.CurHonCell;
	if honCell == nil then
		return false;
	end
	if honCell.type_id == nil then
		return false;
	end
	local stflv = self:StfGemLv(honCell.type_id);
	if stflv == false then
		UITip.Log("需要4级宝石才能提升淬炼")
		return false;
	end
	return self:ChkItems();
end

--是否满足宝石等级(4级)
function My:StfGemLv(typeId)
	local gem = GemData[tostring(typeId)];
	if gem == nil then
		return false;
	end
	if gem.lv < 4 then
		return false;
	end
	return true;
end

--检查淬炼材料
function My:ChkItems()
	local honCell = self.CurHonCell;
	if honCell == nil then
		return false;
	end
	
	local honId = honCell.honId;
	if honId == nil or honId == 0 then--未淬炼
		honId = honCell.gemType * 100;
	end
	honId = honId + 1;
	local id = tostring(honId);
	local info = HonInfo[id];
	if info == nil then
		return false;
	end
	local ndIts = info.needItems;
	for index,item in pairs(ndIts) do
		local id = item.k;
		local val = item.v;
		local hasNum = PropMgr.TypeIdByNum(id);
		if hasNum < val then
			UITip.Log("淬炼材料不足");
			return false;
		end
	end
	return true;
end

function My:Dispose()
    self:Close()
	self.part=nil
	self.type_id = nil;
	self.CurHonCell = nil;
	ListTool.ClearToPool(self.cellList)
	TableTool.ClearListToPool(self.costItmList)
    if self.cell then self.cell:DestroyGo() ObjPool.Add(self.cell) end
    if self.lPanel then ObjPool.Add(self.lPanel) self.lPanel=nil end
end