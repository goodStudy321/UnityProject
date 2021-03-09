--[[
装备结构 p_equip
--]]
EquipTb=Super:New{Name="EquipTb"}
local My=EquipTb

function My:Ctor()
	self.stDic={}
	self.eDic={}
	self.cList={}
	self.slDic={}--纹印
	self.honDic={}
end

--设置初始化（战灵装备使用）
function My:SetInit(equipId,excellents)
	--装备表id
	self.type_id=equipId

	--装备卓越属性列表（id,val）
	TableTool.ClearDic(self.eDic)
	local eDic=excellents
	if eDic then
		for i,v in ipairs(eDic) do
			self.eDic[tostring(v.id)]=v.val
		end
	end
end

function My:Init(equip)
	--装备表id
	self.type_id=equip.equip_id 

	--强化等级
	self.lv=equip.refine_level 

	--熟练度
	self.mas=equip.mastery 

	--套装等级
	self.suitLv=equip.suit_level

	--铸魂等级
	self.forgeSoulLv = equip.forge_soul_cultivate

	--已激活的铸魂属性id
	self.forgeSoulProId = equip.forge_soul

	--装备身上宝石列表
	TableTool.ClearDic(self.stDic)
	local stList=equip.stone_list
	if stList then
		for i,v in ipairs(stList) do
			if v~=nil then 
				self.stDic[tostring(v.id)]=v.val
			end
		end
	end

	--装备身上纹印列表
	TableTool.ClearDic(self.slDic)
	local slList=equip.seal_list
	if slList then
		for i,v in ipairs(slList) do
			if v~=nil then 
				self.slDic[tostring(v.id)]=v.val
			end
		end
	end

	--淬炼度列表
	TableTool.ClearDic(self.honDic)
	local honList = equip.stone_honings
	if honList then
		for k,v in ipairs(honList) do
			if v~=nil then
				local id = tostring(v.id);
				local val = v.val;
				self.honDic[id]=val;
			end
		end
	end

	--装备卓越属性列表（id,val）
	TableTool.ClearDic(self.eDic)
	local eDic=equip.excellent_list
	if eDic then
		for i,v in ipairs(eDic) do
			self.eDic[tostring(v.id)]=v.val
		end
	end

	--是否绑定
	self.bind=equip.bind

	--洗练条数
	self.conciseNum=equip.concise_num

	--洗练数据
	ListTool.ClearToPool(self.cList)
	local cList = equip.concise_list
	if cList then
		for i,v in ipairs(cList) do
			local kv = ObjPool.Get(KV)
			kv:Init(v.index,v.prop_key,v.prop_value)
			self.cList[i]=kv
			if #self.cList>1 then
				table.sort( self.cList, My.SortCb )
			end
		end
	end
end

function My.SortCb(a,b)
	return a.k<b.k
end

--设置淬炼度
function My:SetHoning(holeIndex,honingVal)
	local id = tostring(holeIndex);
	self.honDic[id] = honingVal;
end

function My:Dispose()
	--装备身上宝石列表
	TableTool.ClearDic(self.stDic)

	--淬炼度列表
	TableTool.ClearDic(self.honDic)

	--装备卓越属性列表（id,val）
	TableTool.ClearDic(self.eDic)

	--装备卓越属性列表（id,val）
	TableTool.ClearDic(self.slDic)
	
	--洗练数据
	ListTool.ClearToPool(self.cList)
end