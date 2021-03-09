--[[
宝石格子位置类
--]]
local AssetMgr=Loong.Game.AssetMgr
HoningCell=Super:New{Name="HoningCell"}
local My=HoningCell
--点击宝石孔
My.eClickGem=Event()
--更新淬炼属性
My.eRefreshHonAttr = Event();

function My:Ctor()
	self.tex=ObjPool.Get(StrBuffer)
	self.att={"hp","atk","def","arm"}
	self.tipStr=ObjPool.Get(StrBuffer)
	self.tipList={}
end

function My:Init(go,index)
	self.index=index
	local trans = go.transform
	local TF=TransTool.FindChild
	local CG=ComTool.Get

	self.cell=ObjPool.Get(Cell)
	self.cell:InitLoadPool(trans,0.8)
	self.Add=TF(trans,"Add")
	self.Red=TF(trans,"Red")
	self.Up=TF(trans,"Up")
	self.Att=CG(UILabel,trans,"Att",self.Name,false)
	self.Att.gameObject:SetActive(false)
	self.Lab=TF(trans,"Label")
	--设置开启阶数描述
	if index < 6 then
		local label = CG(UILabel,trans,"Label",self.Name,false);
		local text = string.format("%s开启",Tg3.rank[index]);
		label.text = text;
	end
	self.Slt = TF(trans,"Select");
	self.Slt:SetActive(false);

	local US = UITool.SetLsnrSelf;
	local go = self.cell.trans.gameObject;
	US(go,self.ClickCell,self,self.Name, false)
	self:AddEvent();
end

function My:AddEvent()
	--EquipMgr.eHoning:Add(self.UpdHonPer,self);
end

function My:RemoveEvent()
	--EquipMgr.eHoning:Remove(self.UpdHonPer,self);
end

--点击格子
function My:ClickCell()
	if self.lockState == true then
		UITip.Log("宝石孔未开启");
		return;
	end
	if self.addState == true then
		UITip.Log("镶嵌宝石后才可进行淬炼")
		return;
	end
	if My.eClickGem then
		My.eClickGem(self);
	end
end

--选择格子
function My:Select(active)
	if self.Slt == nil then
		return;
	end
	self.Slt:SetActive(active);
end

--更新数据
function My:UpData(type_id,honId)
	self.gemName = "未镶嵌";
	if type_id ~= nil then
		self.type_id=type_id
		local gem = GemData[tostring(type_id)]
		if gem ~= nil then
			self.gemType = gem.type;
			self.cell:UpData(type_id,"Lv."..gem.lv)
			self:AddState(false)
			self.gemName = gem.name;
		else
			iTrace.eError("xiaoyu","宝石表为空  type_id：".. type_id)
		end
	else
		if self.lockState == true then
			return;
		end
	end
	self:SetHonPer(honId);
end

--设置淬炼度显示
function My:SetHonPer(honId)
	self.honId = honId;
	self.tex:Dispose()

	local honVal = Tg4.GetHonVal(honId);
	local honPer = "淬炼度:" .. honVal .. "%";
	self.tex:Apd(self.gemName):Apd("\n"):Apd(honPer);

	local text = self.tex:ToStr()
	local att = self.Att.gameObject
	if StrTool.IsNullOrEmpty(text) then
		 att:SetActive(false)
	else
		att:SetActive(true)
	end
	self.Att.text=text
end

--更新淬炼度
function My:UpdHonPer(index,honId)
	if self.index ~= index then
		return;
	end
	self:SetHonPer(honId);
	if My.eRefreshHonAttr then
		My.eRefreshHonAttr(self);
	end
end

--添加红点
function My:AddRedUp(part)
	part = tostring(part);
	local equipTb = EquipMgr.hasEquipDic[part];
	if equipTb == nil then
		return;
	end
	if self.type_id == nil then
		return;
	end

	local honDic = equipTb.honDic;
	local canHon = EquipMgr.ChkHonCndt(self.index,self.type_id,honDic);
	if canHon == true then
		self:RedState(true);
	else
		self:RedState(false);
	end
end

--设置孔
function My:SetHoles(part)
	part=tostring(part)
	self.part=part
	self:CleanState()
	self.tipStr:Dispose()
	local tb = EquipMgr.hasEquipDic[part]
	self.equipId=tb.type_id
	local stDic = tb.stDic
	local id = stDic[tostring(self.index)]
	self.type_id=id
	if not id then --宝石孔为空
		local equip = EquipBaseTemp[tostring(self.equipId)]
		local num = equip.holesNum
		local viplv = VIPMgr.GetVIPLv()	 
		if self.index==6 and viplv>=Tg4.VipUnLock then
			self:AddState(true)
			self:LockState(0.001)
		elseif self.index<=num then
			self:AddState(true)
			self:LockState(0.001)
		else
			self:AddState(false)
			self:LockState(1)
			self:LabState(true)
		end
	end
end

function My:GetGem(curid)
	local hasnum = PropMgr.TypeIdByNum(curid)
	local data = GemData[tostring(curid)]
	if data.canGem==nil then return false end
	local num = data.num-1
	self.tipStr:Apd("需要消耗")
	if hasnum>=num then
		self:AddGem(data,num)
		self.tipStr:Apd("将"):Apd(data.lv):Apd("级宝石提升到"):Apd(data.lv+1):Apd("级")
		return true
	else
		local lerp = num-hasnum
		for k,v in pairs(GemData) do
			if v.canGem==curid then
				local num1=lerp*(v.num)
				local hasnum1 = PropMgr.TypeIdByNum(v.id)
				if hasnum1<num1 then 
					local lerp1 = num1-hasnum1
					for k1,v1 in pairs(GemData) do
						if v1.canGem==v.id then
							local num2=lerp1*(v1.num)
							local hasnum2 = PropMgr.TypeIdByNum(v1.id)
							if hasnum2<num2 then return false
							else 
								self:AddGem(data,hasnum)
								self:AddGem(v,hasnum1)
								self:AddGem(v1,num2)
								self.tipStr:Apd("将"):Apd(data.lv):Apd("级宝石提升到"):Apd(data.lv+1):Apd("级")
								return true 
							end
						end
					end					
				else 
					self:AddGem(data,hasnum)
					self:AddGem(v,num1)
					self.tipStr:Apd("将"):Apd(data.lv):Apd("级宝石提升到"):Apd(data.lv+1):Apd("级")
					return true 
				end
			end
		end
	end
end

function My:AddGem(data,num)
	if num==0 then return end
	self.tipStr:Apd(data.lv):Apd("级宝石* "):Apd(num):Apd("，")
	local kv = ObjPool.Get(KV)
	kv:Init(data.id,num)
	self.tipList[#self.tipList+1]=kv
end


function My:LockState(a)
	if a == 1 then 
		self.lockState = true;
	else
		self.lockState = false;
	end

	self.cell:Lock(a)
end
function My:AddState(active)
	self.addState = active;
	self.Add:SetActive(active)
end

function My:RedState(active)
	self.Red:SetActive(active)
end

function My:UpState(active)
	self.Up:SetActive(active)
end

function My:LabState(active)
	self.Lab:SetActive(active)
end

function My:CleanState()
	self:AddState(false)
	self:RedState(false)
	self:UpState(false)
	if self.index~=6 then
		self:LabState(false) 
	end
end

function My:Clean()
	self:Select(false);
	self.type_id=nil
	self.equipId=nil
	self.gemType=nil;
	self.Att.text=""
	if self.cell then
		self.cell:Clean()
	end
end

function My:Dispose()
	self:RemoveEvent();
	self:Clean()
	if self.cell then
		self.cell:DestroyGo()
		ObjPool.Add(self.cell)
		self.cell=nil
	end
end