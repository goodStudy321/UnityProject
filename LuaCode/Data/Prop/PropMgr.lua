--[[
道具管理类
--]]
require("Data/Prop/Naturemgr")
PropMgr = {Name = "PropMgr"}
local My = PropMgr
local GetError = nil
local Naturemgr=Naturemgr

--背包更新事件
My.eUpdate = Event()
My.eClean=Event()
My.eRemove=Event()
My.eUpNum=Event()
My.eAddNum=Event()
My.eAdd=Event()
My.eGetAdd=Event() --道具获得
My.eAddGem=Event()
My.eAddSeal=Event();
My.eReGem=Event()
My.eReSeal=Event();
My.eSort=Event()
My.eUp=Event()
My.eUse=Event()	--响应使用道具
My.eGrid=Event()
My.eReName=Event()
My.eUpFight=event()
--------
My.eMSMUpdate = Event()	--天机令
--------

--背包装备 key:部位 value:list[type_id]
--需要整理得加
My.equipDic={}
My.typeIdDic={} --key:type_id value:list[id]
My.typeId2Dic={}
My.typeId3Dic={}
My.typeId4Dic={}
My.typeId5Dic={}
My.typeId8Dic={}


--必须要
My.tbDic={} --key:id value:tb --背包
My.tb2Dic={} --个人仓库
My.tb3Dic={} --寻宝临时仓库
My.tb4Dic={} --许愿池仓库
My.tb5Dic={} --天机令
My.tb6Dic = {}  --炼丹炉临时仓库
My.tb8Dic = {}  --通天塔活动仓库
My.tbAll={tp1=My.tbDic,tp2=My.tb2Dic,tp3=My.tb3Dic,tp4=My.tb4Dic,tp5=My.tb5Dic,tp6=My.tb6Dic,tp8=My.tb8Dic}
My.typeIdAll={tp1=My.typeIdDic,tp2=My.typeId2Dic,tp3=My.typeId3Dic,tp4=My.typeId4Dic,tp5=My.typeId5Dic,tp8=My.typeId8Dic}
--空格 table{index..}
local spaceTbList = {{},{},{},{},{},{},{},{}}
--按顺序排序的 里面是一个唯一id
My.sortIdDic = {{},{},{},{},{},{},{},{}}




My.fightDic = {} --key:id value:fight
My.cellNumDic={} --背包最大格子数量

--相同品质
local quaDic = {} --key:quality value:list[type_id]
--背包宝石 --key:部位 value:List[type_id]
local gemDic = {}
--背包印章 --key:部位 value:List[type_id]
local sealDic = {}
-- --按顺序排序的 里面是一个表type_id
-- local sortTid = {}
My.indexDic={}
local bagNumList = {}--背包格子数量

local getList={}
My.isAuto=false
--是否自动吞噬
My.isAutoDevour = false

My.isFull=false --背包数量是否已满

My.isSort=false --是否排序
My.tp=1
My.TimeDic={}

My.tb = nil

function My.Init()
	My.AddLnsr()
	GetError = ErrorCodeMgr.GetError
	My.InitTimeDic(  )
	Naturemgr.InitTab()
end


function My.InitTimeDic(  )
	My.TimeDic["57"]=0
	My.TimeDic["58"]=0
	My.TimeDic["92"]=0
end

--添加事件
function My.AddLnsr()
  local Add = ProtoLsnr.Add
  Add(20810, My.ResqInfo)
  Add(20812, My.ResqUpdate)
  Add(20814, My.ResqMerge)
  Add(20816, My.ResqGrid)
  Add(20838, My.ResqUse)
  Add(20840, My.ResqSell)
  Add(20818,My.ResqDepot)
  Add(20026,My.ResqReName)
  Add(22820,My.ResqFamilyName)
  Add(20028,My.ResqSelectGift)

  Add(20732,My.ResqBossTime)
  Add(20740,My.ResqItemTime)
end

function My.ResqInfo(msg)
	My.Clear()
	local bagList=msg.bag_list
	for i,bag in ipairs(bagList) do
		local tp=bag.bag_id
		local lst = bag.goods_list
		local num = bag.bag_grid
		local list=My.tbAll["tp"..tp]
		if list then 
			for i,v in ipairs(lst) do		
				local tb = My.ParseGood(v)			
				local id = tb.id
				local type_id = tb.type_id
				tb=My.DealSpace(tb,tp)
				if tp<3 then tb=My.UpFight(tb) end
				if list then list[tostring(id)]=tb end
				My.UpTypeIdDic(type_id,id,tp)			
			end
			My.SortTb(tp)
			My.cellNumDic[tostring(tp)]=num
			if tp==1 then 
				My.eUpdate() 	
			elseif tp==5 then
				My.eMSMUpdate()
			end
		end
	end
	My.CheckFull()

	EquipMgr.PropNextRed()
end

function My.ResqUpdate(msg)
	local upList = msg.update_list
	local delList = msg.del_list
	local action = msg.action
	local kvList = msg.kv_list
	local tpp=nil
	for i,id in ipairs(delList) do
		local sid=tostring(id)
		local tp,dic=My.GetTp(id)
		if dic then 
			local sortid = My.sortIdDic[tp]
			tpp=tp
			local tb = dic[sid]
			if not tb then 
				iTrace.eError("xiaoyu","  道具更新删除为空请查看代码 #dic: "..TableTool.GetDicCount(dic).."  id: "..sid)
				return
			end
			local index = tb.index
			sortid[index+1]=-1
			local type_id = tb.type_id
			ObjPool.Add(tb)
			dic[sid]=nil
			local bagNum=bagNumList[tp]
			bagNumList[tp]=bagNum-1
			local space=spaceTbList[tp]
			table.insert(space,index)
			if tp==1 then My.indexDic[tostring(index)]=nil end
			if #space>1 then table.sort(space, My.SortSpace) end
			My.ReTypeIdDic(type_id,id,tp)
			My.eRemove(id,tp,type_id,action,index)
		end
	end
	for i,v in ipairs(upList) do
		local id = v.id
		local sid=tostring(id)
		local type_id = v.type_id
		local num = v.num
		local tp,dic=My.GetTp(id)
		local sortid = My.sortIdDic[tp]
		if dic then 
			tpp=tp
			local tb =dic[sid]
			if(tb==nil)then
				tb=My.ParseGood(v)
				tb = My.DealSpace(tb,tp)
				sortid[tb.index+1]=tb.id
				dic[sid]=tb
				if tp<3 then tb=My.UpFight(tb) end			
				if tb.isUp==true then 
					local part=PropTool.FindPart(tostring(type_id))
					My.eUp(part) 
				end
				My.UpTypeIdDic(type_id,id,tp)
				My.GetAdd(action,type_id,num,tb.bind)
				My.eAdd(tb,action,tp)
			else
				local num = num-tb.num
				tb:Init(v)
				if num>0 then 
					My.GetAdd(action,type_id,num,tb.bind) 
					if tp==1 then My.eAddNum(type_id,num,action,id) end
				end
				My.eUpNum(tb,tp,num,action)
			end

			-- --红点
			-- if tp==1 then 
			-- 	My.SetRed(type_id)
			-- end
			-- --
		end
	end
	for i,v in ipairs(kvList) do
		My.GetAdd(action,v.id,v.val)
	end
	My.eGetAdd(action,getList) --道具获得事件（action 服务端宏定义）
	if #getList>0 then
		if (action==10302 or action==10343 or action == 10107 or action == 10375 or action == 10428 or action == 10429 or action == 10430 or action == 10450) then --恭喜获得
			UIMgr.Open(UIGetRewardPanel.Name,My.RewardCb)
		elseif (action == 10431) then
			if (not LuckFullMgr.isAuto) then
				UIMgr.Open(UIGetRewardPanel.Name,My.RewardCb)
			end
		end
	end
	ListTool.ClearToPool(getList)
	if tpp==1 then 
		My.eUpdate() 
		My.CheckFull()
		My.AutoSell(My.isAuto)
		My.AutoDevour(My.isAutoDevour)
	elseif tpp== 5 then
		My.eMSMUpdate()
	end

	if My.isSort==true then
		My.ReqMerge(tpp)
	end
end

function My.RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(getList)
	end
end

function My.CheckFull()
	local isFull=false
	local bagNum=bagNumList[1] or 0
	if bagNum==My.cellNumDic["1"] then isFull=true end
	EventMgr.Trigger("UpBag",isFull)
	My.isFull=isFull
end

function My.GetAdd(action,type_id,num,bind)
	if not bind then --服务端发过来需要界面显示的道具（不放在背包的，例如货币，符文）
		bind=false
		local item=ItemData[tostring(type_id)]
		local max = item.overlayNum
		if num>max then
			local y,yy = math.modf(num/max)
			for i=1,y do
				My.Addkv(type_id,max,bind)
			end
			if yy>0 then
				My.Addkv(type_id,num-y*max,bind)
			end
		else
			My.Addkv(type_id,num,bind)
		end
	else
		My.Addkv(type_id,num,bind)
	end
end

function My.Addkv(type_id,num,bind)
	local kv=ObjPool.Get(KV)
	kv:Init(type_id,num,bind)
	getList[#getList+1]=kv
end

local mergeDic = {}
function My.ReqMerge(tp)
	My.ClearMergeDic()
	tp=tonumber(tp)
	My.tp=tp
	local tbDic=My.tbAll["tp"..tp]
	local idDic=My.typeIdAll["tp"..tp]
	if not tbDic or not idDic then return end
	local msg = ProtoPool.GetByID(20813)
	local merge_list = msg.merge_list

	for k,v in pairs(idDic) do
		local item = UIMisc.FindCreate(k)
		local maxNum = item.overlayNum
		if maxNum>0 then
			for i,id in ipairs(v) do
				local tb = tbDic[tostring(id)]
				local num = tb.num
				local bind = tb.bind and "1" or "2"
				if num<maxNum then 
					local type_idDic = mergeDic[k]
					if not type_idDic then type_idDic={} mergeDic[k]=type_idDic end
					--绑定1 非绑定2
					local bindDic = type_idDic[bind]
					if not bindDic then bindDic={} type_idDic[bind]=bindDic end

					--到期1  相同2 
					local now =  TimeTool.GetServerTimeNow()*0.001
					local tp = (tb.market_end_time == 1 or (now - tb.market_end_time>0)) and "1" or "2"
					local list = bindDic[tp]
					if not list then list={} bindDic[tp]=list end
					table.insert( list, tb )
				end
			end
		end
	end

	for k,v in pairs(mergeDic) do
		for bind,bindDic in pairs(v) do
			for tp,list in pairs(bindDic) do
				local num = #list
				if num<2 then
					ListTool.Clear(list)
					v[bind]=nil
				else
					local merge = merge_list:add()
					for i,tb in ipairs(list) do
						merge.id_list:append(tb.id)
					end					
				end
			end
		end
	end

	if #merge_list==0 then My.SortTb(tp)
	else 
		ProtoMgr.Send(msg)		
	end
end

function My.ClearMergeDic()
	for k,v in pairs(mergeDic) do
		for bind,bindDic in pairs(v) do
			for index,indexDic in pairs(bindDic) do
				ListTool.Clear(indexDic)
			end
			TableTool.ClearDic(bindDic)
		end
		TableTool.ClearDic(v)
	end
	TableTool.ClearDic(mergeDic)
end

function My.ResqMerge(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
		My.SortTb(My.tp)
	end
end

function My.ReqGrid(bagId,num)
	local msg = ProtoPool.GetByID(20815)
	msg.bag_id=bagId
	msg.add_num=num
	ProtoMgr.Send(msg)
end

function My.ResqGrid(msg)
	local err = msg.err_code
	local bagId = msg.bag_id
	local num = msg.bag_grid
	if(err==0)then
		UITip.Log("成功开启格子")
		local add = num-My.cellNumDic[tostring(bagId)]
		My.cellNumDic[tostring(bagId)]=num
		My.eGrid(bagId,add)
	else
		UITip.Log(GetError(err))
	end
end

--id传type_id tp是1    id传唯一id默认 tp可以不传
function My.ReqUse(id,num,tp,isSpir)
	local type_id = nil
	if(tp==1)then
		type_id=tostring(id)
	else
		local tb = My.tbDic[tostring(id)]
		if(tb==nil)then return end
	 	type_id =tostring(tb.type_id)
	end	
	local item = UIMisc.FindCreate(type_id)
	if(item==nil)then iTrace.eError("xiaoyu","道具表为空  type_id: "..type_id)return end
	local lv = item.useLevel or 0
	local vip = item.useVIP or 0
	local gg = item.gilgulLv or 0
	local cate = item.cateLim or 0 --职业
	local realm = item.realm or 0 --境界
	local uFx =item.uFx or 0--类型	--职业
	if(cate~=0 and User.instance.MapData.Category~=cate)then
		UITip.Log("职业不符")
		return
	end
	if(lv~=0 and User.instance.MapData.Level<lv )then
		UITip.Log("等级不足")
		return
	end
	local robcfg = RobberyMgr:GetCurCfg()
	if(realm~=0 and (not robcfg or robcfg.id<realm) )then
		local rob = RobberyMgr:GetCurCfg(realm)
		local text = "当前装备需要达到"..rob.floorName.."才能穿戴是否立即前往提升境界？"
		MsgBox.ShowYes(text,My.ProRobCb,My,"立即前往")		
		return
	end
	if(vip~=0 and VIPMgr.GetVIPLv()<vip )then
		local text = "VIP等级不足，无法使用道具。是否前往提升VIP？"
		if VIPMgr.GetVIPLv()<4 then
			MsgBox.ShowYes(text,My.yesCb2,My,"提升VIP")			
		else
			MsgBox.ShowYes(text,My.yesCb,My,"提升VIP")
		end

		return
	end
	if(gg~=0 and RebirthMsg.RbLev<gg)then
		UITip.Log("转生等级不足")
		return
	end

	if(tp==nil)then tp=0 end
	if(num==nil)then num=1 end
	if uFx==57 or uFx==58 or uFx==92 then
		local times=PropMgr.TimeDic[tostring(uFx)]
		if times then
			local gid = nil
			if uFx==57 then
				gid="84"
			elseif uFx==58 then
				gid="85"
			elseif uFx==92 then
				gid="174"
			end
			local global = GlobalTemp[gid]
			if not global then iTrace.eError("soon","global表为空 id: "..gid)return end
			local AllTms = global.Value3
			if times+1> AllTms then
				UITip.Log("【今日使用次数已达到上限】")
				return
			end
		local dec =AllTms-times
		num=num>dec and dec or num
		end
	end
	if isSpir ~= nil and isSpir == true then
		local spirId = RobEquipsMgr.GetCurSpirId();
		local equips = {id};
		RobEquipsMgr:ReqArmorLoad(spirId,equips);
	else
		local msg = ProtoPool.GetByID(20837)
		msg.type=tp
		msg.id=id
		msg.num=num
		ProtoMgr.Send(msg)
	end
end

function My.yesCb()
	VIPMgr.OpenVIP(1)
end

function My.yesCb2()
	UIMgr.Open(UIV4Panel.Name)
end

function My.ProRobCb()
	UIRobbery:OpenRobbery(1)
end

function My.ResqUse(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		if msg.type_id==118 or msg.type_id==119 then
			UITip.Log("五行幻力增加")
		end
	end
	My.eUse()
end

function My.ReqSell(dic)
	local msg = ProtoPool.GetByID(20839)
	local list = msg.item_list
	for k,v in pairs(dic) do
		local kv = msg.item_list:add()
		kv.id=tonumber(k)
		kv.val=v		
	end
	if(#list>0)then
		ProtoMgr.Send(msg)
	else
		UITip.Log("没有道具可出售")
	end
end

function My.ResqSell(msg)
	local err = msg.err_code
	if err==0 then
		UITip.Log("成功出售")
	else
		UITip.Log(GetError(err))
	end
end

--移动
function My.ReqDepot(fId,tId,id)
	local msg=ProtoPool.GetByID(20817)
	msg.from_bag_id=fId
	msg.to_bag_id=tId
	msg.id=id
	ProtoMgr.Send(msg)
end

function My.ResqDepot(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	end
end

--角色改名
function My.ReqReName(name)
	local msg=ProtoPool.GetByID(20025)
	msg.name=name
	ProtoMgr.Send(msg)
end

function My.ResqReName(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		UITip.Log("改名成功!")
		local name = msg.name
		User.instance.MapData.Name=name
		My.eReName("changeName")
	end
end

--道庭改名
function My.ReqFamilyName(name)
	local msg=ProtoPool.GetByID(22819)
	msg.family_name=name
	ProtoMgr.Send(msg)
end

function My.ResqFamilyName(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		UITip.Log("改名成功!")
		local name = msg.family_name
		User.instance.MapData.FamlilyName=name
		My.eReName("changeFamilyName")
	end
end

--装备礼包选择
function My.ReqSelectGift(id,index)
	local msg=ProtoPool.GetByID(20027)
	msg.goods_id=id
	msg.index=index
	ProtoMgr.Send(msg)
end

function My.ResqSelectGift(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		UITip.Log("选择成功!")
	end
end

function My.ResqBossTime(msg)
	local kv = msg.item_times
	local uFx = kv.id
	local time = kv.val
	My.TimeDic[tostring(uFx)]=time
end

function My.ResqItemTime(msg)
	local kv = msg.item_times
	local uFx = kv.id
	local time = kv.val
	My.TimeDic[tostring(uFx)]=time
end

--解析道具结构
function My.ParseGood(good)
	local tb = ObjPool.Get(PropTb)
	tb:Init(good)
	return tb
end

function My.GetTp(id)
	local tp=0
	if(id>=1 and id<=1000)then
		tp=1
	elseif(id>=1001 and id<=2000)then	
		tp=2
	elseif(id>=2001 and id<=3000)then
		tp=3
	elseif(id>=3001 and id<=4000)then
		tp=4
	elseif(id>= 4001 and id <= 5000) then
		tp=5
	elseif(id>= 5001 and id <= 6000) then
		tp = 6
	elseif(id>= 7001 and id <= 8000) then
		tp = 8
	end	
	return tp,My.tbAll["tp"..tp]		
end

function My.UpAllFight()
	for k,v in pairs(My.equipDic) do
		ListTool.Clear(v)
		My.equipDic[k]=nil
	end
	local dic1 = My.tbDic
	for k,v in pairs(dic1) do
		My.UpFight(v)
	end
	local dic2 = My.tb2Dic
	for k,v in pairs(dic2) do
		My.UpFight(v)
	end
	My.eUpFight()
end

--比较背包 装备 战力
function My.UpFight(tb)
	local type_id = tostring(tb.type_id)
	local id = tb.id
	local item = ItemData[type_id]
	if(item==nil)then iTrace.Error("xiaoyu","道具表为空 id:"..type_id)return end
	if(item.uFx==1)then
		local part = PropTool.FindPart(type_id)
		local ttb = My.equipDic[part]
		if(ttb==nil)then
			ttb={}
			My.equipDic[part]=ttb
		end
		ttb[#ttb+1]=id

		local fight =PropTool.Fight(tb)
		My.fightDic[tostring(id)]=fight

		local wear = EquipMgr.hasEquipDic[part]
		tb.isDown=false
		tb.isUp=false
		if(wear==nil)then		
			tb.isUp=true
		else
			local wearF = wear.fight
			if(fight>wearF)then				
				tb.isUp=true
			elseif fight<wearF then
				tb.isDown=true
			end
		end
	end
	return tb
end

function My.DealSpace(tb,tp)
	local bagNum=bagNumList[tp] or 0
	local dic=spaceTbList[tp]
	if not dic then return end 
	if(#dic > 0)then
		if(#dic>1)then
			table.sort(dic, My.SortSpace)
		end
		tb.index = dic[#dic]
		dic[#dic]=nil
	else
		tb.index = bagNum
	end
	if tp==1 then My.indexDic[tostring(tb.index)]=tb.id end
	bagNumList[tp]=bagNum+1

	return tb
end

--排序
function My.SortTb(tp)
	--清理数据
	local space=spaceTbList[tp]
	if not space then return end
	My.eClean(tp)	
	ListTool.Clear(space)
	ListTool.Clear(My.sortIdDic[tp])
	if tp==1 then TableTool.ClearDic(My.indexDic) end
	bagNumList[tp]=0
	--local SORT= {"1","25","21-24","8-12","2-7,13-17","31"}
	--装备排序:品质大小 部位小大 品阶大小 评分大小 type_id大小 id大小
	--其他：品质大小 type_id大小 数量多少 id大小
	My.AddSortType_Id(35212,tp) -- 25 35212
	My.AddSort(28,tp) --精灵和仙女
	My.AddSort(35,tp) --增加副本次数
	My.AddSort(1,tp) --装备
	My.AddSort(25,tp) --礼包
	for i=21,24 do --钱
		My.AddSort(i,tp)
	end
	for i=8,12 do --时装
		My.AddSort(i,tp)
	end
	for i=2,7 do --丹药
		My.AddSort(i,tp)
	end
	for i=13,17 do --丹药
		My.AddSort(i,tp)
	end
	My.AddSort(31,tp) --宝石

	--13-17 18-20 26-30 32-34 --其他
	for i=18,20 do
		My.AddSort(i,tp)
	end
	for i=26,30 do
		if i~=28 then
			My.AddSort(i,tp)
		end
	end
	for i=32,34 do
		My.AddSort(i,tp)
	end
	My.AddSort(0,tp)
	for i=36,100 do --其他
		My.AddSort(i,tp)
	end
	My.eSort(tp)
	My.isSort=false
	return My.sortIdDic[tp]
end

local AddSortList = {}
function My.AddSort(use,tp)
	local typeIdDic=My.typeIdAll["tp"..tp]
	local tbDic=My.tbAll["tp"..tp]
	local idDic=My.sortIdDic[tp]
	if not typeIdDic or not tbDic then return end
	local num=bagNumList[tp] or 0
	local en = My.SortUse(use,typeIdDic)
	if #en>1 then table.sort(en, My.SortQua)end
	for i,type_id in ipairs(en) do
		local tb = typeIdDic[tostring(type_id)]
		if tb and type_id~=35212 then
			if(#tb>1)then
				if use==1 and tp==1 then table.sort(tb,My.SortGrade)
				else table.sort(tb, My.SortNum) end
			end
			for i,id in ipairs(tb) do
				local tbb = tbDic[tostring(id)]
				tbb.index=num
				if tp==1 then My.indexDic[tostring(num)]=tbb.id end
				num=num+1				
				idDic[#idDic+1]=id
			end
		end
	end
	bagNumList[tp]=num
end

local sortUseList = {}
function My.SortUse(use,typeIdDic)
	ListTool.Clear(sortUseList)
	for k,v in pairs(typeIdDic) do
		local item = UIMisc.FindCreate(k)
		local uFx=item.uFx or 0
		if uFx==use then
			table.insert( sortUseList,k)
		end
	end
	return sortUseList
end

function My.AddSortType_Id(type_id,tp)
	local typeIdDic=My.typeIdAll["tp"..tp]
	local tbDic=My.tbAll["tp"..tp]
	local idDic=My.sortIdDic[tp]
	local num=bagNumList[tp] or 0
	if not typeIdDic or not tbDic then return end
	local tb = typeIdDic[tostring(type_id)]
	if tb then
		if(#tb>1)then
			if use==1 and tp==1 then table.sort(tb,My.SortGrade)
			else table.sort(tb, My.SortNum) end
		end
		for i,id in ipairs(tb) do
			local tbb = tbDic[tostring(id)]
			tbb.index=num
			if tp==1 then My.indexDic[tostring(num)]=tbb.id end
			num=num+1				
			idDic[#idDic+1]=id
		end
	end
	bagNumList[tp]=num
end

function My.SortNum(a,b)
	local tp,dic=My.GetTp(a)
	local num1 = dic[tostring(a)].num
	local num2 =dic[tostring(b)].num
	return num1>num2
end

function My.SortGrade(a,b)
	local f1 = My.fightDic[tostring(a)]
	local f2 = My.fightDic[tostring(b)]
	return f1>f2
end

function My.SortQua(a, b)
	a=tostring(a)
	b=tostring(b)
	local item1 = ItemData[a]
	if(item1==nil)then iTrace.eError("xiaoyu","道具表为空 type_id: "..a)return end
	local item2 = ItemData[b]
	if(item2==nil)then iTrace.eError("xiaoyu","道具表为空 type_id: "..b)return end
	local uFx1 = item1.uFx
	local uFx2 = item2.uFx
	if(item2.quality == item1.quality)then
		if(uFx1==1 and uFx2==1)then
			return My.SortPart(a, b)
		else
			return My.SortId(a,b)
		end
	end
	return item1.quality>item2.quality
end

function My.SortPart(a,b)
	local part1 = EquipBaseTemp[a].wearParts
	local part2 = EquipBaseTemp[b].wearParts
	if(part1==part2)then
		return My.SortRank(a, b)
	else
		return part1<part2	
	end
end

function My.SortRank(a,b)
	local rank1 = EquipBaseTemp[a].wearRank
	local rank2 = EquipBaseTemp[b].wearRank
	return rank1>rank2	
end

function My.SortId(a,b)
	local id1 = tonumber(a)
	local id2 = tonumber(b)
	return id1>id2
end

function My.SortSpace(a, b)
	return a > b
end

function My.UpTypeIdDic(type_id,id,tp)
	local dic=My.typeIdAll["tp"..tp]
	if not dic then return end
	local tb = dic[tostring(type_id)]
	if(tb==nil)then
		tb={}
		dic[tostring(type_id)]=tb

		--添加type_id
		if tp ==1 then My.UpQuaDic(type_id) end
	end
	-- for i,v in ipairs(tb) do
	-- 	if(id==v)then return end
	-- end
	table.insert(tb,id)
end

function My.ReTypeIdDic(type_id,id,tp)
	local dic=My.typeIdAll["tp"..tp]
	if not dic then return end
	local tb = dic[tostring(type_id)]
	for i,v in ipairs(tb) do
		if(id==v)then 
			table.remove(tb,i)
			if(#tb==0)then
				dic[tostring(type_id)]=nil
				--移除type_id
				if tp ==1 then My.ReQuaDic(type_id) end
				return
			end 
		end
	end
end

function My.UpQuaDic(type_id)
	local item = ItemData[tostring(type_id)]
	if(item==nil)then iTrace.eError("xiaoyu","道具表为空 type_id: ".. type_id)return end
	local qua = item.quality
	local tb = quaDic[tostring(qua)]
	if(tb==nil)then
		tb={}
		quaDic[tostring(qua)]=tb
	end
	table.insert(tb,type_id)
	local uFx = item.uFx or 0
	if uFx==31 then
		My.UpGem(type_id)
	elseif uFx==77 then
		My.UpSeal(type_id)
	end
end

function My.ReQuaDic(type_id)
	local item = ItemData[tostring(type_id)]
	if(item==nil)then iTrace.eError("xiaoyu","道具表为空 type_id: ".. type_id)return end
	local qua = item.quality
	local tb = quaDic[tostring(qua)]
	for i,v in ipairs(tb) do
		if(type_id==v)then table.remove(tb,i) break end
	end
	local uFx = item.uFx or 0
	if uFx==31 then
		My.ReGem(type_id)
	elseif uFx==77 then
		My.ReSeal(type_id)
	end
end

function My.UpSeal( type_id )
	local seal = tSealData[tostring(type_id)]
	if(seal==nil)then iTrace.Error("soon","纹印表为空 type_id: ".. type_id) return end
	local parts = seal.parts
	for i,v in ipairs(parts) do
		local tb=sealDic[tostring(v)]
		if(tb==nil)then
			tb={}
		    sealDic[tostring(v)]=tb
			tb[1]=type_id
		else
			local has = My.FindTypeId(tb,type_id)
			if(has==false)then
				table.insert(tb,type_id)
				if(#tb>1)then
					table.sort(tb, My.SortTId)
				end
			end
		end
	end
	My.eAddSeal(type_id)
end

function My.UpGem(type_id)
	local gem = GemData[tostring(type_id)]
	if(gem==nil)then iTrace.eError("xiaoyu","宝石表为空 type_id: ".. type_id) return end
	local parts = gem.parts
	for i,v in ipairs(parts) do
		local tb=gemDic[tostring(v)]
		if(tb==nil)then
			tb={}
		    gemDic[tostring(v)]=tb
			tb[1]=type_id
		else
			local has = My.FindTypeId(tb,type_id)
			if(has==false)then
				table.insert(tb,type_id)
				if(#tb>1)then
					table.sort(tb, My.SortTId)
				end
			end
		end
	end
	My.eAddGem(type_id)
end

function My.SortTId(a,b)
	return a>b
end

function My.FindTypeId(tb,type_id)
	for i,v in ipairs(tb) do
		if(v==type_id)then return true end	
	end
	return false
end

function My.ReGem(type_id)
	local gem = GemData[tostring(type_id)]
	if(gem==nil)then iTrace.eError("xiaoyu","宝石表为空 type_id: ".. type_id) return end
	local parts = gem.parts
	for i,v in ipairs(parts) do
		local tb = gemDic[tostring(v)]
		if(tb~=nil)then
			for i2,v2 in ipairs(tb) do
				if(v2==type_id)then
					table.remove(tb,i2)
					My.eReGem(type_id)
				end
			end
		end
		if #tb==0 then gemDic[tostring(v)]=nil end
	end
end

function My.ReSeal(type_id)
	local seal = tSealData[tostring(type_id)]
	if(seal==nil)then iTrace.Error("soon","纹印表为空 type_id: ".. type_id) return end
	local parts = seal.parts
	for i,v in ipairs(parts) do
		local tb = sealDic[tostring(v)]
		if(tb~=nil)then
			for i2,v2 in ipairs(tb) do
				if(v2==type_id)then
					table.remove(tb,i2)
					My.eReSeal(type_id)
				end
			end
		end
		if #tb==0 then sealDic[tostring(v)]=nil end
	end
end

----------------------------公开方法 背包
--filted:是否过滤过期道具
function My.TypeIdByNum(type_id,tp,filted)
	if(type(type_id)=="number")then type_id=tostring(type_id) end
	if not tp then tp=1 end
	local num = 0  
	local typeDic = My.typeIdAll["tp"..tp]
	local tbDic = My.tbAll["tp"..tp]
	local tb = typeDic[type_id]
	if(tb~=nil and #tb>0)then
		for i,v in ipairs(tb) do
			local ttb = tbDic[tostring(v)]
			if filted == true then
				local n = My.GetItemNum(ttb);
				num = num + n;
			else
				num=num+ttb.num
			end
		end
	end
	return num
end

--获取物品数量
function My.GetItemNum(ttb)
	local num = ttb.num;
	local endTime = ttb.endTime;
	if endTime and endTime > 0 then
		local nowTime = TimeTool.GetServerTimeNow()*0.001;
		local leftTime = endTime - nowTime;
		if leftTime <= 0 then
			return 0;
		end
	end
	return num;
end

function My.TypeIdById(type_id)
	local id = nil
	if(type(type_id)=="number")then type_id=tostring(type_id) end
	local tb = My.typeIdDic[type_id]
	if(tb~=nil and #tb>0)then id=tb[#tb] end
	return id
end

--通过道具使用类型使用获取一堆道具数据
function My.UseGetDic(tab, tplist)
	if not tab then iTrace.eError("hs", "传入tabel为空")
	else ListTool.Clear(tab) end
	if not tplist then return tab end
	local len = #tplist
	for i=1,len do
 		local tp = tplist[i]
		if(tp==nil)then tp=1 end
		local tb = My.UseEffGet(tp)
		if(tb~=nil)then
			for i,type_id in ipairs(tb) do
				if(type(type_id)=="number")then type_id=tostring(type_id)end
				local ic = ItemData[type_id]
				if ic.type ~= 1 or (ic.type == 1 and ic.quality >= 3) then 
					local tb = My.typeIdDic[type_id]
					if(tb==nil)then return nil end
					for i,id in ipairs(tb) do
						local ttb = My.tbDic[tostring(id)]
						tab[#tab+1]=ttb
						if(#tab>1)then
							table.sort( tab, My.SortUseQua)
						end
					end
				end
			end
		end
	end
	return tab
end

function My.SortUseQua(a,b)
	local id1 = tostring(a.type_id)
	local id2 = tostring(b.type_id)
	local item1 = ItemData[id1]
	local item2 = ItemData[id2]
	return item1.quality>item2.quality
end

--通过道具使用效果获取
local useDic = {}
function My.UseEffGet(use)
	ListTool.Clear(useDic)
	local dic = My.typeIdDic
	for k,v in pairs(dic) do
		local item = UIMisc.FindCreate(k)
		local uFx = item.uFx or 0
		if uFx==use then 
			table.insert( useDic, k )
		end
	end
	return useDic
end

--通过使用效果获取该系列的所有item
function My.GetItemsByUseEff(use)
	local items = {}
	local dic = My.typeIdDic
	for k,v in pairs(dic) do
		local item = UIMisc.FindCreate(k)
		if item.uFx==use then
			for i,id in ipairs(v) do
				local tb = My.tbDic[tostring(id)]
				table.insert( items, tb)
			end
		end
	end
	return items
end

--获取背包中所有可以拍卖的道具
function My.GetCanAuctionItems()
	local list1 = My.FindAuctionItems(My.typeId5Dic, My.tb5Dic)
	table.sort(list1, function(a,b) return SMSMgr:Sort(a,b) end)
	local list2 = My.FindAuctionItems(My.typeIdDic, My.tbDic)
	table.sort(list2, My.Sort)
	local items = TableTool.CombList(list1, list2)
	return items
end

--获取所有可以捐献的道具
function My.GetCanDonateItems()
	local items = {}
	for i, v in pairs(My.tbAll) do
		for j, k in pairs(v) do
			local temp = ItemData[tostring(k.type_id)]
			if temp and temp.worth and temp.worth > 0 then
				table.insert(items, k)
			end
		end
	end
	return items
end

function My.FindAuctionItems(typeIdDic, tbDic)
	local list = {}
	for _, idList in pairs(typeIdDic) do
		for _,id in ipairs(idList) do
			local tb = tbDic[tostring(id)]
			local now =  TimeTool.GetServerTimeNow()*0.001
			local cfg = ItemData[tostring(tb.type_id)];
			if cfg.startPrice and cfg.AucSecId then
				if tb.bind == false and (tb.market_end_time == 1 or now - tb.market_end_time > 0) then
					table.insert(list, tb)
				end
			end
		end
	end
	return list
end


--获取宝石
function My.GetGemByPart(part)
	local tb = gemDic[tostring(part)]
	if(tb == nil)then return nil end
	return tb
end
--获取纹印
function My.GetSealByPart(part)
	local tb = sealDic[tostring(part)]
	if(tb == nil)then return nil end
	return tb
end

--自动出售道具
function My.AutoSell(state)
	My.isAuto=state
	if(state==false)then return 
	else
		local cellNum = My.cellNumDic["1"]
		if not cellNum then return end
		local num=bagNumList[1] or 0
		local space=spaceTbList[1]
		if(cellNum-num+#space<5)then
			local msg = ProtoPool.GetByID(20839)
			local list = msg.item_list
			local tb = My.typeIdDic
			for type_id,tbb in pairs(tb) do
				local item = ItemData[tostring(type_id)]
				if(item==nil)then iTrace.eError("xiaoyu","道具表为空 type_id: ".. type_id)return end
				if(item.price~=nil and item.uFx==1 and item.quality<3)then
					for i,id in ipairs(tbb) do
						local kv = list:add()
						kv.id=id
						kv.val=1
					end
				end
			end
			if(#list>0)then
				ProtoMgr.Send(msg)
			end
		end
	end
end

--当背包小于五时自动吞噬零星紫色装备
function My.AutoDevour(isAutoState)
	My.isAutoDevour = isAutoState
	if isAutoState == false then
		return
	end
	local qual = ItemQuality.Purple
	local step = ItemStep.All
	local curStar = 0
	local petDItem = My.GetQUARANKSTART(qual, step, curStar,isAutoState)
	local len = #petDItem
	if len <= 0 then
		return
	end
	local cellNum = My.cellNumDic["1"]
	local num = bagNumList[1] or 0
	local space = spaceTbList[1]
	local restSpace = cellNum - num + #space
	if restSpace >= 5 then
		return
	end
	-- PetMgr:ReqPetLevelUp(petDItem)
	PetMgr.OnReqPetLevelUp(petDItem)
end

--获取背包剩余空格
function My.GetRemainCell()
	return My.cellNumDic["1"]-bagNumList[1]
end

function My.GetSpace()
	return spaceTbList[1]
end

-- 设置出售道具信息
function My.SetPropTb(tb)
	My.tb = tb
end

--通过道具Id该系列的所有道具
function My.GetGoodsByTypeId(typeId)
	local data = {}
	local list = My.typeIdDic[tostring(typeId)]
	if list then
		for i=1,#list do
			local tb = My.tbDic[tostring(list[i])]
			table.insert(data, tb)
		end
	end
	return data
end

--品质，品阶，星级
local outList = {}
function My.GetQUARANKSTART(qua,rank,star,isAutoState)
	if isAutoState == nil then
		isAutoState = false
	end
	ListTool.Clear(outList)
	local dic = My.typeIdDic
	if not dic then return nil end
	for k,v in pairs(dic) do
		local item=ItemData[tostring(k)]
		local QUA = item.quality
		if item.uFx==1 then
			local equip = EquipBaseTemp[tostring(k)]						
			local RANK = equip.wearRank or 0
			local STAR = equip.startLv or 0
			local result1,result2,result3 = false
			if QUA < ItemQuality.Powder and QUA >= ItemQuality.White and (qua==0 or QUA<=qua) then 
				result1=true 
			end
			if rank==0 or RANK<=rank then 
				result2=true 
			end
			if isAutoState == true then
				if star == STAR then
					result3=true
				else
					result3=false
				end
			else
				if star==0 or STAR<=star then 
					if QUA == ItemQuality.Red and STAR >= 2 then
						result3=false 
					else
						result3=true 
					end
				end
			end
			
			if result1==true and result2==true and result3==true then
				for i1,v1 in ipairs(v) do
					local tb = My.tbDic[tostring(v1)]
					outList[#outList+1]=tb
				end
			end
		elseif item.uFx==7 and (qua==0 or QUA<=qua) then --宠物丹药
			for i1,v1 in ipairs(v) do
				local tb = My.tbDic[tostring(v1)]
				outList[#outList+1]=tb
			end
		end
	end
	table.sort(outList,My.Sort)
	return outList
end

function My.Sort(a, b)
	if not a or not b then return 0 end
	local aid = a.type_id
	local bid = b.type_id
	local ai=ItemData[tostring(aid)]
	local bi=ItemData[tostring(bid)]
	if ai and bi then
		if ai.quality == bi.quality then
			local ae = EquipBaseTemp[tostring(aid)]
			local be = EquipBaseTemp[tostring(bid)]
			if ae and be then
				return ae.wearRank > be.wearRank
			end
		else
			return ai.quality > bi.quality
		end
	end
	return false
end

--获取背包能穿戴的更好的装备
function My.GetCanEquipUp()
	local isup=false
	for k,v in pairs(My.tbDic) do
		if v.isUp==true then
			local item=UIMisc.FindCreate(v.type_id)
			local canUse = QuickUseMgr.CanUse(item)
			if canUse==true then isup=true break end
		end
	end
	return isup
end

--获取背包装备
local bagEquipList = {}
function My.GetBagEquip()
	ListTool.Clear(bagEquipList)
	for k,v in pairs(My.tbDic) do
		local item = UIMisc.FindCreate(v.type_id)
		if item.uFx==1 then
			table.insert( bagEquipList, v)
		end
	end
	return bagEquipList
end

--添加Clear方法
function My.Clear()
	for k,v in pairs(My.equipDic) do
		ListTool.Clear(v)
		My.equipDic[k]=nil
	end
	for k,v in pairs(My.typeIdAll) do
		TableTool.ClearDic(v)
	end
	for k,v in pairs(My.tbAll) do
		TableTool.ClearDicToPool(v)
	end
	for k,v in pairs(quaDic) do
		ListTool.Clear(v)
		quaDic[k]=nil
	end
	for k,v in pairs(gemDic) do
		ListTool.Clear(v)
		gemDic[k]=nil
	end
	for k,v in pairs(sealDic) do
		ListTool.Clear(v)
		sealDic[k]=nil
	end
	for i,v in ipairs(My.sortIdDic) do
		ListTool.Clear(v)
	end
	for i,v in ipairs(spaceTbList) do
		ListTool.Clear(v)
	end
end

function My.Dispose()

end

return My