--[[
装备管理类
--]]
require("Data/Prop/EquipColor")
EquipMgr={Name="EquipMgr"}
local My=EquipMgr
local GetError = nil
My.eRefine=Event()
My.eRefineFail=Event() --todo:aKeyFail
My.ePunch=Event() 
My.eSealPunch=Event() 
My.eRemove=Event()
My.eSealRemove=Event()
--My.eAKey=Event()
My.eASealKey=Event();
My.eCompose=Event()
My.eSealCompose=Event()
My.eECompose=Event()
My.eESealCompose=Event();
My.eSuit=Event()
My.eLoad=Event()
My.eConciseOpen=Event()
My.eTime=Event()
My.eClick = Event()
My.eOpenJ = Event()
My.eForgeSoul = Event()
My.eJewelry = Event()  --更新首饰进阶装备cell
--淬炼成功事件
My.eHoning = Event();
My.eUp=Event() --装备战力更高箭头更新
My.eRed=Event() --大红点状态有变化才触发
My.eChangeRed=Event() --装备界面小红点状态改变
My.eChangeHonRed=Event() --淬炼界面
My.eComRed=Event()
My.eChangeComRed=Event()


local isFirstBetterEquip4 = false
local isFirstBetterEquip5 = false

My.hasEquipDic={} --装备穿戴列表 key 穿戴部位id,value tb
My.freeTime=0 --免费洗练次数
-------------设置强化的红点状态
My.redBool={}  
My.qianghuaPartRed = {} --强化
My.xilianPartRed={} --洗练
My.red32Dic={} --道具合成
My.red33Dic={} --装备合成
My.red34Dic={} --饰品合成
My.red35Dic={} --首饰合成
My.redT5Dic = {} -- 首饰进阶
My.red6Dic = {} -- 天机印合成

My.red3Dic = {}
My.xiangqianPartDic = {}
My.red5Dic = {}
My.wenyinPartDic = {}
--淬炼红点字典
My.cuilianPartDic = {}
-------------
--合成
My.redBoolCom = {}
My.lockDic={}  --锁定列表记录

--不需要清理
local attNAME = {"hp","atk","def","arm"}
------------表
My.conciseDic={} --装备洗练表
My.sysDic={}
My.gemList={}
My.sealList={}
My.goodDic={}
My.equipList={{},{},{}}
My.jewelryList = {{},{}}
My.jjInfos = {}
------------

function My.Init()
	My.AddLnsr()
	GetError = ErrorCodeMgr.GetError
	CopyMgr.eInitCopyInfo:Add(My.UpAction)
	RoleAssets.eUpAsset:Add(My.UpAction)
	VIPMgr.eUpInfo:Add(My.OnVIPChange)
	PropMgr.eRemove:Add(My.PropRmove)
	PropMgr.eAdd:Add(My.PropAdd)
	PropMgr.eUpNum:Add(My.PropUpNum)
	RoleAssets.eUpAsset:Add(My.PropChg);
	--RoleAssets.eEnd:Add(My.End)
	OpenMgr.eOpen:Add(My.Open)
	EventMgr.Add("OnChangeLv",My.OnChangeLv)
	EventMgr.Add("SelectSuc",My.RoleInfoEnd)
	My.InitTable() --初始化各种表
	My.SetSysID()
end

function My.AddLnsr()
	local Add = ProtoLsnr.Add
	Add(21200, My.ResqInfo)
	Add(21202, My.ResqRefine)
	Add(21206, My.ResqPunch)
	Add(24404, My.ResqSealPunch)
	Add(21208, My.ResqRemove)
	Add(24406, My.ResSealRemove)
	Add(21210, My.ResqECompose)
	Add(21212, My.ResqSuit)
	Add(21214, My.ResqSCompose)
	Add(24408, My.ResqSealCompose)
	--Add(21216, My.ResqOneKey)
	Add(24410, My.ResSealOneKey)
	Add(21220, My.ResqLoad)
	Add(21222, My.ResqGCompose)
	Add(21226,My.ResqTime)
	Add(21228,My.ResqConcise)
	Add(21230,My.ResqOpen)
	Add(21218,My.ResqJewelry)
	Add(21232,My.ResqActivte)
	Add(21234,My.ResqUpgrade)
	Add(21204,My.ResqESCompose)
	Add(24402,My.ResqESSealCompose)
	Add(26382,My.ResqNatureCompose)
	Add(24352,My.RespHoning)
end

-- 设置当前点击装备Tip信息
function My.SetCurEquipTipData(item,equip,tb)
	My.curItem = item 
	My.curequip = equip
	My.curTb = tb
end

function My.OnEquip(isSpir)
	if(My.curItem.canUse==1)then
		if isSpir == true then
			My.OnEquipCb(isSpir);
			return;
		end
		local part = My.curequip.wearParts
		local tb = EquipMgr.hasEquipDic[tostring(part)]
		if(tb~=nil and tb.suitLv~=nil and tb.suitLv~=0)then
			local title="您换下的为[67cc67]套装部件[-]，且无法转移到新的装备上，是否更换该装备[67cc67]（返还全部套装石头）[-]?"			
			MsgBox.ShowYesNo(title, My.OnEquipCb,My)
		elseif EquipMgr:IsTips(tostring(part), My.curItem.id) then
			local title="替换会使铸魂效果暂时失效，是否确认替换？"			
			MsgBox.ShowYesNo(title, My.OnEquipCb,My)
		else
			My.OnEquipCb()
		end			
	else
		UITip.Log("不能穿戴")
	end
end

function My.OnEquipCb(isSpir)
	local useLv = My.curItem.useLevel or 1
	if(User.MapData.Level<useLv)then
		UITip.Log("等级不足，无法穿戴")
		return
	end
	PropMgr.ReqUse(My.curTb.id,1,nil,isSpir)
end


--货币改变事件
function My.PropChg(ty)
	if ty==1 then	
		My.qianghuaRed()
	end
end

-- function My.End()
-- 	My.qianghuaRed()
	
-- 	My.isOpenJ = OpenMgr:IsOpen(58)
-- 	My.SetRed2()
-- end

-- function My.IsOpen()
-- 	for i=11,18 do
-- 		local tp = i-10
-- 		local isopen=OpenMgr:IsOpen(i) or false
-- 		openList[tp]=isopen
-- 	end
-- end

function My.Open(id)
	if id==11 then --强化系统开启
		My.qianghuaRed()
		My.xilianRed()
	elseif id==12 then --进阶系统
		--My.SetRed2()
	elseif id==13 then --道具合成
		My.SetRed32()
	elseif id==19 then --装备合成
		My.SetRed33()
		My.SetRed34()
		My.SetRed35()
	elseif id==14 then --镶嵌
		My.xiangqianRed()
	elseif id==17 then --纹印
		My.wenyinRed()
	elseif id == 58 then --首饰进阶
		My.SetRed2()
	elseif id == 18 then --淬炼
		My.cuilianRed()
	elseif id==706 then --天机印合成
		Naturemgr.SetRed()
	end
end

--------------------------------------- region 协  议
-- 首饰进阶协议
function My.ReqJewelry(id)
	local msg=ProtoPool.GetByID(21217)
	msg.equip_id=id
	ProtoMgr.Send(msg)
end

function My.ResqJewelry(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		local equip = msg.equip
		if list == nil then return end
		local tb,part=My.SetEquip(equip)
		tb.fight=PropTool.Fight(tb)
		My.hasEquipDic[part]=tb
		
		My.eLoad(tb,part)
		My.eSuit(tb,part)
		--My.eClick(part)
	end
	My.SetRed2()
	My.eJewelry()
end

function My.ResqInfo(msg)
	local list=msg.equip_list
	if(list==nil)then return end
	for i,v in ipairs(list) do
		local tb,part=My.SetEquip(v)
		tb.fight=PropTool.Fight(tb)
		My.hasEquipDic[part]=tb
	end
end

function My.ReqRefine(id)
	local msg=ProtoPool.GetByID(21201)
	msg.equip_id=id
	ProtoMgr.Send(msg)
end

function My.ResqRefine(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
		My.eRefineFail()
	else
		UITip.Log("装备强化成功")
		local multi = msg.multi
		local tb,part=My.SetEquip(msg.equip)
		tb.multi= multi
		My.eRefine(tb,part)

		My.qianghuaRed()
	end
end

function My.ReqPunch(id,sId,index)
	local msg=ProtoPool.GetByID(21205)
	msg.equip_id=id
	msg.stone_id=tonumber(sId)
	msg.punch_index=tonumber(index)
	ProtoMgr.Send(msg)
end

function My.ReqSealPunch(id,sId,index)
	local msg=ProtoPool.GetByID(24403)
	msg.equip_id=id
	msg.seal_id=tonumber(sId)
	msg.punch_index=tonumber(index)
	ProtoMgr.Send(msg)
end

function My.ResqPunch(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		UITip.Log("宝石镶嵌成功")
		local tb,part=My.SetEquip(msg.equip)
		My.ePunch(tb,part)
	end
end

function My.ResqSealPunch(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		UITip.Log("纹印镶嵌成功")
		local tb,part=My.SetEquip(msg.equip)
		My.eSealPunch(tb,part)
	end
end
-----------淬炼------------
--请求淬炼
function My.ReqHoning(equipId,holeIdex)
	local name = "m_stone_honing_tos";
	local msg = ProtoPool.Get(name);
	msg.equip_id = equipId;
	msg.index = holeIdex;
	ProtoMgr.Send(msg);
end

--淬炼反馈
function My.RespHoning(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		UITip.Log("淬炼成功")
		My.SetHoning(msg.equip_id,msg.stone_honing)
	end	
end

-----------淬炼End---------

function My.ReqRemove(id,index)
	local msg=ProtoPool.GetByID(21207)
	msg.equip_id=id
	msg.stone_index=tonumber(index)
	ProtoMgr.Send(msg)
end
--纹印装备镶嵌
function My.ReqSealRemove(id,index)
	local msg=ProtoPool.GetByID(24405)
	msg.equip_id=id
	msg.seal_index=tonumber(index)
	ProtoMgr.Send(msg)
end

function My.ResqRemove(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		UITip.Log("宝石成功卸下")
		local tb,part=My.SetEquip(msg.equip)
		My.eRemove(tb,part)
	end
end

function My.ResSealRemove(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		UITip.Log("纹印成功卸下")
		local tb,part=My.SetEquip(msg.equip)
		My.eSealRemove(tb,part)
	end
end

function My.ReqECompose(id,list)
	local msg=ProtoPool.GetByID(21209)
	msg.equip_id=id
	for i,v in ipairs(list) do
		msg.material_list:append(tonumber(v))
	end
	ProtoMgr.Send(msg)
end

function My.ResqECompose(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		local suc=msg.is_success
		if suc==true then
			UITip.Log("装备合成成功")
		else
			UITip.Log("装备合成失败")
		end
		My.eCompose(suc)
	end
end

--提升装备套装等级
function My.ReqSuit(id)
	local msg=ProtoPool.GetByID(21211)
	msg.equip_id=id
	ProtoMgr.Send(msg)
end

function My.ResqSuit(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		local tb,part=My.SetEquip(msg.equip)
		My.eSuit(tb,part)
	end
end

function My.ReqSCompose(sId)
	local msg=ProtoPool.GetByID(21213)
	msg.stone_id=sId
	ProtoMgr.Send(msg)
end
--纹印合成
function My.ReqSealCompose(sId)
	local msg=ProtoPool.GetByID(24407)
	msg.seal_id=sId
	ProtoMgr.Send(msg)
end

function My.ResqSCompose(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		UITip.Log("宝石合成成功")
		My.eCompose(true)
	end	
end
--纹印合成返回
function My.ResqSealCompose(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		UITip.Log("纹印合成成功")
		My.eCompose(true)
	end	
end

--装备身上宝石合成
function My.ReqESCompose(equip_id,index,list)
	local msg = ProtoPool.GetByID(21203)
	msg.equip_id=equip_id
	msg.index=index
	for i,v in ipairs(list) do
		local kv = msg.material_list:add()
		kv.id=v.k
		kv.val=v.v
	end
	ProtoMgr.Send(msg)
end

--装备身上纹印合成
function My.ReqESealCompose(equip_id,index,list)
	local msg = ProtoPool.GetByID(24401)
	msg.equip_id=equip_id
	msg.index=index
	for i,v in ipairs(list) do
		local kv = msg.material_list:add()
		kv.id=v.k
		kv.val=v.v
	end
	ProtoMgr.Send(msg)
end

function My.ResqESCompose(msg)
	local err = msg.err_code
	if err~=0 then
		UITip.Log(GetError(err))
	else
		local tb,part=My.SetEquip(msg.equip)
		My.xiangqianRed()
		My.eECompose(tb,part)
	end
end

--装备身上纹印合成返回
function My.ResqESSealCompose(msg)
	local err = msg.err_code
	if err~=0 then
		UITip.Log(GetError(err))
	else
		local tb,part=My.SetEquip(msg.equip)
		My.wenyinRed()
		My.eESealCompose(tb,part)
	end
end

--天机印合成
function My.ReqNatureCompose(compose_id)
	local msg = ProtoPool.GetByID(26381)
	msg.compose_id=compose_id
	ProtoMgr.Send(msg)
end

--天机印合成返回
function My.ResqNatureCompose(msg)
	local err = msg.err_code
	if err~=0 then
		UITip.Log(GetError(err))
	else
		UITip.Log("天机印合成成功")
	end
end

-- function My.ReqOneKey(tp,idList)
-- 	local msg=ProtoPool.GetByID(21215)
-- 	msg.type=tp
-- 	for i,v in ipairs(idList) do
-- 		msg.id_list:append(v)
-- 	end
-- 	ProtoMgr.Send(msg)
-- end

--纹印一键1穿戴/2卸下
function My.ReqSealOneKey(tp,idList)
	local msg=ProtoPool.GetByID(24409)
	msg.type=tp
	for i,v in ipairs(idList) do
		msg.id_list:append(v)
	end
	ProtoMgr.Send(msg)
end

-- function My.ResqOneKey(msg)
-- 	local err = msg.err_code
-- 	if err~=0 then
-- 		UITip.Log(GetError(err))
-- 	else
-- 		local tp = msg.type
-- 		local list = msg.equip_list
-- 		if tp==1 then 
-- 			UITip.Log("一键穿戴成功")
-- 			for i,v in ipairs(list) do
-- 				My.SetEquip(v)				
-- 			end
-- 		elseif tp==2 then 
-- 			UITip.Log("一键卸下成功")
-- 			for i,v in ipairs(list) do
-- 				My.SetEquip(v)
-- 			end		
-- 		end	
-- 		My.eAKey(tp)
-- 	end
-- end

function My.ResSealOneKey(msg)
	local err = msg.err_code
	if err~=0 then
		UITip.Log(GetError(err))
	else
		local tp = msg.type
		local tb = 0
		local part = nil
		local list = msg.equip_list
		if tp==1 then 
			UITip.Log("一键穿戴成功")
			for i,v in ipairs(list) do
				tb,part=My.SetEquip(v)				
			end
		elseif tp==2 then 
			UITip.Log("一键卸下成功")
			for i,v in ipairs(list) do
				tb,part=My.SetEquip(v)
			end		
		end	
		My.wenyinRed()
		My.eASealKey(tp)
	end
end

function My.ResqLoad(msg)
	local equip=msg.equip
	local tb,part=My.SetEquip(equip)
	tb.fight=PropTool.Fight(tb)
	PropMgr.UpAllFight()
	My.eUp(part)
	My.hasEquipDic[part]=tb
	My.qianghuaRed()
	My.xiangqianRed()
	My.wenyinRed()
	My.cuilianRed()
	My:UpAction()
	My.eLoad(tb,part)
	My.FirstBetterEquip(tb)
end

function My.FirstBetterEquip(tb)
	local item = UIMisc.FindCreate(tb.type_id)
	local qua = item.quality
	if qua==4 and isFirstBetterEquip4==false then 
		isFirstBetterEquip4=true
		UIBetterEquip.OpenBetterEquip(tb)
	elseif qua==5 and isFirstBetterEquip5==false then
		isFirstBetterEquip5=true
		UIBetterEquip.OpenBetterEquip(tb)
	end
end

function My.ReqGCompose(cId,rateNum)
	local msg=ProtoPool.GetByID(21221)
	msg.compose_id=cId
	msg.add_rate_num=rateNum
	ProtoMgr.Send(msg)
end

function My.ResqGCompose(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		local suc=msg.is_success
		if suc==true then
			UITip.Log("道具合成成功")
		else
			UITip.Log("道具合成失败")
		end
		My.eCompose(suc)
	end
end

function My.ResqTime(msg)
	local time = msg.free_concise_times
	My.freeTime=time
	My.eTime()
	
end

function My.ReqConcise(id,type,lock)
	local msg = ProtoPool.GetByID(21227)
	msg.equip_id=id
	msg.type=type --1普通洗练 2元宝洗练
	if lock then 
		for k,v in pairs(lock) do
			if v==true then 
				msg.lock_index_list:append(tonumber(k))
			end
		end
	end
	ProtoMgr.Send(msg)
end

function My.ResqConcise(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		UITip.Log("装备洗练成功")
		local equip=msg.equip
		local tb,part=My.SetEquip(equip)
		My.hasEquipDic[part]=tb
		My.eConciseOpen(tb,part)
	end
end

function My.ReqOpen(id)
	local msg = ProtoPool.GetByID(21229)
	msg.equip_id=id
	ProtoMgr.Send(msg)
end

function My.ResqOpen(msg)
	local err = msg.err_code
	if(err~=0)then
		UITip.Log(GetError(err))
	else
		UITip.Log("装备洗练开启成功")
		local equip=msg.equip
		local tb,part = My.SetEquip(equip)
		My.hasEquipDic[part]=tb
		My.eConciseOpen(tb,part)
	end
end

function My.SetEquip(equip)
	local part=PropTool.FindPart(tostring(equip.equip_id))
	local tb=My.hasEquipDic[part]
	if tb==nil then
		tb=My.ParseEquip(equip)
		My.hasEquipDic[part]=tb
	else
		tb:Dispose()
	end
	tb:Init(equip)
	return tb,part
end

--设置淬炼度
function My.SetHoning(equipId,honInfo)
	local part=PropTool.FindPart(tostring(equipId))
	local tb=My.hasEquipDic[part]
	if tb==nil then
		return;
	end
	if honInfo == nil then
		return;
	end
	tb:SetHoning(honInfo.id,honInfo.val);
	My.eHoning(equipId,part,honInfo.id,honInfo.val);
end

function My.ParseEquip(equip)
	local tb=ObjPool.Get(EquipTb)
	tb:Init(equip)
	return tb
end
--------------------------------------- endregion 协  议

--获取人物总的宝石等级
function My.GetAllGemLv()
	local count = 0
	for k,v in pairs(My.hasEquipDic) do
		for k,v in pairs(v.stDic) do
			local num = (v-30000) % 10
			count = count + num
        end
	end
	return count
end

--获取相同套装（诛仙诛神），相同套装组的装备数量
--gp 套装等级  group 套装组
function My.GetCurNum(gp,group)
	local num = 0
	for part,tb in pairs(EquipMgr.hasEquipDic) do
		if(tb.suitLv>=gp)then
			local equip = EquipBaseTemp[tostring(tb.type_id)]
			if(group==equip.suit1)then
				num=num+1
			elseif(group==equip.suit2)then
				num=num+1
			end
		end
	end
	return num
end

function My.GetSuit(g)
	if g ==1 then
		return "【诛仙】"
	elseif g==2 then
		return "【诛神】"
	else 
		return nil
	end
end

--获取装备强化概率表的编号
function My.FindType(part)
	local add
	if part==1 or part==7 or part==8 or part==9 or part==10 then --攻击类型
		add=10000
	else --防御类型
		add=20000
	end
	return add
end

function My.SetSysID()
	My.sysDic["1"]=11
	My.sysDic["2"]=15
	My.sysDic["3"]=14
	My.sysDic["4"]=18
	My.sysDic["5"]=17
	My.sysDic["6"]=505
end

--打开装备界面
local bTP,sTP,mjumpItem
function My.OpenEquip(tp,mas,jumpItem)
	bTP=tp
	sTP=mas or 1
	mjumpItem=jumpItem
	local isopen = OpenMgr:IsOpen(My.sysDic[tostring(tp)])
	if isopen==false then 
		UITip.Log("系统未开启") 
		return
	end
	UIMgr.Open(UIEquip.Name,My.EquipCb)
end

function My.EquipCb(name)
	local ui = UIMgr.Get(name)
	if ui then 
		ui:OpenTabByIdx(bTP,sTP,mjumpItem)
	end	
	bTP=nil
	sTP=nil
	mjumpItem=nil
end



-------------设置监听事件的红点状态
function My.PropRmove(id,tp,type_id,action)
	if tp==1 then 
		My.UpRed(type_id)
		My.SetRed2()
	elseif tp==5 then 
		My.tianjiyinRed(type_id)
	end
end

function My.PropAdd(tb,action,tp)
	if tp==1 then 
		My.UpRed(tb.type_id)
		My.SetRed2()
	elseif tp==5 then 
		My.tianjiyinRed(tb.type_id)
	end
end

function My.PropUpNum(tb,tp,num,action)
	if tp==1 then
		My.UpRed(tb.type_id)
		My.SetRed2()
	elseif tp==5 then
		My.tianjiyinRed(tb.type_id)
	end
end

function My.UpRed(type_id)
	local item = UIMisc.FindCreate(type_id)
	local uFx = item.uFx
	if uFx==31 then --宝石
		My.xiangqianRed()
		My.cuilianRed()
	elseif uFx==77 then --纹印
		My.wenyinRed()
	elseif uFx==1 then --装备
		My.SetRed33()
		My.SetRed34()
		My.SetRed35()
	elseif uFx==78 then --淬炼材料
		My.cuilianRed()
	elseif uFx==86 then --天机印
		Naturemgr.SetRed()
	else --道具
		My.SetRed32()
		My.xilianRed()
	end
end

function My.tianjiyinRed(type_id)
	local item = UIMisc.FindCreate(type_id)
	local uFx = item.uFx
	if uFx==86 then 
		Naturemgr.SetRed()
	end
end

function My.PropNextRed()
	
end

--上线玩家信息推送完
function My.RoleInfoEnd()
	--// LY add begin
	My.InitGood();
	--// LY add end
	My.InitEquip()
	My.GetUserData()
	My.xilianRed()
	My.qianghuaRed()
	My.wenyinRed()
	My.SetRed32()
	My.SetRed33()
	My.SetRed34()
	My.SetRed35()
	My.cuilianRed()
	My.SetRed2()
	Naturemgr.SetRed()
end

function My.OnChangeLv()
	My.qianghuaRed()
	My.xilianRed()
	My.SetRed33()
	My.SetRed34()
	My.SetRed35()
end

function My.OnVIPChange()
	My.xiangqianRed()
	My.wenyinRed()
end


--强化
function My.qianghuaRed()
	if OpenMgr:IsOpen(My.sysDic["1"])==false then return end
	local isred = false
	for part,tb in pairs(My.hasEquipDic) do
		local red = false
		local id = tostring(tb.type_id)
		local equip = EquipBaseTemp[id]
		local lv=tb.lv or 0
		local next = EquipMgr.FindType(equip.wearParts)+lv+1
		local str=EquipStr[tostring(next)]
		if str then 
			local needLv = str.level
			local money = RoleAssets.Silver
			local state = (money>=str.money and money>5000000)
			local uLv = User.instance.MapData.Level
			if state ==true and uLv>=needLv then 
			   red=true 
			   isred=true
		   end		  
		end	
		My.qianghuaPartRed[part]=red
	end
	if isred~=My.redBool["1"] then 
		My.eRed(isred,1) 
		My.redBool["1"]=isred 
	end
	My.eChangeRed(1)
end

--洗炼红点 
function My.xilianRed()
	if OpenMgr:IsOpen(My.sysDic["2"])==false then return end
	local redDic = My.xilianPartRed
	local isFree = My.freeTime>0 and true or false
	local isred=false
	for k,v in pairs(My.hasEquipDic) do
		local red = false
		local data = EquipOpenLv[k]
		local lv = data.lv or 0
		local isopen = User.instance.MapData.Level>=lv and true or false
		if isopen==true then
			if isFree==true then 
				red=true 
				isred=true
			else
				local hasNum=PropMgr.TypeIdByNum(103)
				local lockDic = EquipMgr.lockDic[k]
				local lockNum = 0
				if lockDic then lockNum=TableTool.GetDicCount(lockDic) end
				local needNum= EquipLock[tostring(lockNum)].neednum
				if hasNum>=needNum then red=true isred=true end
			end
		end
		redDic[k]=red
	end
	if isred~=My.redBool["2"] then 
		My.redBool["2"]=isred 
		My.eRed(isred,2) 
	end
	My.eChangeRed(2)
end

--首饰进阶
function My.SetRed2()
	if OpenMgr:IsOpen(53)==false then return end
	local isred = false
	if My.hasEquipDic == nil then return end
	for part,v in pairs(My.hasEquipDic) do
		local red = false
		local num = tonumber(part)
		if num == 9 or num == 10 then
			local id = v.type_id
			if JewelryList[tostring(id)] then
				local needid = JewelryList[tostring(id)].needId
				local num = PropMgr.TypeIdByNum(id) + 1
				local needNum = PropMgr.TypeIdByNum(needid)
				if num >= 1 and needNum >= 1 then
					red = true
					isred = true
				end
			end
			My.redT5Dic[part] = red
		end
	end
	if isred~=My.redBoolCom["5"] then 
		My.eComRed(isred,5)
		My.redBoolCom["5"]=isred 
	end
end

-- --宝石合成 change:宝石增加,宝石减少
-- function My.SetRed31()
-- 	local isopen=openList[3] or false 
-- 	if isopen==false then return end
-- 	local dic = My.red31Dic
-- 	if not dic then dic={} My.red3Dic["1"]=dic end	
-- 	local isred2 = false
-- 	--纹印合成
-- 	for i,v in ipairs(My.sealList) do
-- 		local k = tostring(3+i)
-- 		local list = dic[k]
-- 		if not list then list={} dic[k]=list end
-- 		for i1,v1 in ipairs(v) do
-- 			local red = false
-- 			local gem = tSealData[v1]
-- 			local has = PropMgr.TypeIdByNum(v1)
-- 			if has>=gem.num then red=true isred2=true end
-- 			list[i1]=red
-- 		end
-- 	end
-- 	if isred2~=My.redBool["31"] then 
-- 		My.eRed(isred2,3,1) 
-- 		My.redBool["31"]=isred2 
-- 	end
-- 	My.eChangeRed(3,1)
-- end

My.noshowRed=false --不再提示合成（装备合成）
--道具合成
function My.SetRed32()
	if OpenMgr:IsOpen(13)==false then return end
	local dic = My.red32Dic
	local isred=false
	for i,v in pairs(My.goodDic) do
		local ISSHOW=true
		if i=="8" then
			ISSHOW=My.IsShowSuit(v)
		end
		if ISSHOW==true then  
			local list = dic[tostring(i)]
			if not list then list={} dic[tostring(i)]=list end
			for i1,v1 in ipairs(v) do
				local red = true
				local info = SynInfo[v1]
				local items = info.needItems
				for i2,v2 in ipairs(items) do
					if My.noshowRed==true then 
						red=false
					else
						local isShow=true
						if i=="8" then
							isShow=My.CheckSuit(info)
						end
						if isShow==true then
							local id = v2.id
							local need = v2.val
							local has = PropMgr.TypeIdByNum(id)
							if has<need then 
								red=false
							end
						end
					end				
				end	
				list[tostring(v1)]=red
				if red==true then isred=true end
			end
		end
	end

	if isred~=My.redBoolCom["2"] then 
		My.eComRed(isred,2) 
		My.redBoolCom["2"]=isred 
	end
	My.eChangeComRed(2)
end

function My.IsShowSuit(v)
	for i1,v1 in ipairs(v) do
		local info=SynInfo[v1]
		local isShow=My.CheckSuit(info)
		if isShow==true then return true end
	end
	return false
end

--合成表
function My.CheckSuit(cfg)
	local suitInfo=SuitMgr.suitInfo
	local items=cfg.needItems
	for index, value in ipairs(items) do
		local id=value.id
		for i1, suitList in ipairs(suitInfo) do
			for i2, suitid in ipairs(suitList) do
				local suitCfg=SuitStarData[tostring(suitid)]
				local suitAttCfg=SuitAttData[tostring(suitCfg.suitId)]
				local rank=suitAttCfg.rank
				local needid=suitCfg.needList[1]
				if needid==id and rank>=10 then
					return true
				end
			end
		end
	end
	return false
end

--装备合成
My.noshowRed33=false --true 不再提示合成 类型-品阶-部位-eneeenn
function My.SetRed33()
	if OpenMgr:IsOpen(19)==false then return end
	local isred = false
	local dic = My.red33Dic
	local list = My.equipList[1]
	for i,v in pairs(list) do
		local typeDic = dic[tostring(i)]
		if not typeDic then typeDic={} dic[tostring(i)]=typeDic end
		for rank,v1 in pairs(v) do
			-- local rankDic = typeDic[rank]
			-- if not rankDic then rankDic={} typeDic[rank]=rankDic end
			local isrankred = false
			for part,v2 in pairs(v1) do
				local red = false
				if My.noshowRed33==false then 
					local data = EquipCompound[v2]
					local canid = data.canId
					if canid then
						local allNum = 0
						local maxNum = 0
						local prob=data.prob
						for i,v in ipairs(prob) do
							if v.val==10000 then maxNum=v.id break end
						end
						for i2,id in ipairs(canid) do
							local num = PropMgr.TypeIdByNum(id)
							allNum=allNum+num
							if allNum>=maxNum then red=true isred=true break end
						end
					end
				end
				if red==true then isrankred=true break end
			end
			typeDic[rank]=isrankred
		end	
	end
	if isred~=My.redBoolCom["3"] then 
		My.eComRed(isred,3) 
		My.redBoolCom["3"]=isred 
	end
	My.eChangeComRed(3)

	-- iTrace.eError("xiaoyu","xxxxxxxxxxxxxxxxxxxxxxx")
	-- iTrace.eError("xiaoyu","xxxxxxxxxxxxxxxxxxxxxxx")
	-- iTrace.eError("xiaoyu","xxxxxxxxx装备合成xxxxxxxxxxxxxx")
	-- for k,v in pairs(My.red33Dic) do
	-- 	for k1,v1 in pairs(v) do
	-- 		iTrace.eError("xiaoyu","  k1: "..k1.."  v1: "..tostring(v1))
	-- 	end
	-- end
	-- iTrace.eError("xiaoyu","装备合成大标签  "..tostring(My.redBoolCom["3"]))
end

--饰品合成
My.noshowRed34=false --true 不再提示合成 类型-品阶-部位-eneeenn
function My.SetRed34()
	if OpenMgr:IsOpen(19)==false then return end
	local isred = false
	local dic = My.red34Dic
	local list = My.equipList[2]
	for i,v in pairs(list) do
		local typeDic = dic[tostring(i)]
		if not typeDic then typeDic={} dic[tostring(i)]=typeDic end
		for rank,v1 in pairs(v) do
			local isrankred = false
			for part,v2 in pairs(v1) do
				local red = false
				if My.noshowRed34==false then 
					local data = EquipCompound[v2]
					local canid = data.canId
					if canid then
						local allNum = 0
						local maxNum = 0
						local prob=data.prob
						for i,v in ipairs(prob) do
							if v.val==10000 then maxNum=v.id break end
						end
						for i2,id in ipairs(canid) do
							local num = PropMgr.TypeIdByNum(id)
							allNum=allNum+num
							if allNum>=maxNum then red=true isred=true break end
						end
					end
				end
				if red==true then isrankred=true break end
			end
			typeDic[rank]=isrankred
		end	
	end
	if isred~=My.redBoolCom["4"] then 
		My.eComRed(isred,4) 
		My.redBoolCom["4"]=isred 
	end
	My.eChangeComRed(4)
end

--首饰合成
My.noshowRed35=false --true 不再提示合成 类型-品阶-部位-eneeenn
function My.SetRed35()
	if OpenMgr:IsOpen(19)==false then return end
	local isred = false
	local dic = My.red35Dic
	local list = My.equipList[3]
	for i,v in pairs(list) do
		local typeDic = dic[tostring(i)]
		if not typeDic then typeDic={} dic[tostring(i)]=typeDic end
		for rank,v1 in pairs(v) do
			local isrankred = false
			for part,v2 in pairs(v1) do
				local red = false
				if My.noshowRed35==false then 
					local data = EquipCompound[v2]
					local canid = data.canId
					if canid then
						local allNum = 0
						local maxNum = 0
						local prob=data.prob
						for i,v in ipairs(prob) do
							if v.val==10000 then maxNum=v.id break end
						end
						for i2,id in ipairs(canid) do
							local num = PropMgr.TypeIdByNum(id)
							allNum=allNum+num
							if allNum>=maxNum then red=true isred=true break end
						end
					end
				end
				if red==true then isrankred=true break end
			end
			typeDic[rank]=isrankred
		end	
	end
	if isred~=My.redBoolCom["7"] then 
		My.eComRed(isred,7) 
		My.redBoolCom["7"]=isred 
	end
	My.eChangeComRed(7)
end

--镶嵌  change:宝石增加，宝石减少--，宝石一键镶嵌卸下 装备身上宝石合成
function My.xiangqianRed()
	if OpenMgr:IsOpen(My.sysDic["3"])==false then return end
	local isred = false
	local lv = VIPMgr.GetVIPLv() or 0
	local add = 0
	if lv>=7 then add=1 end
	local redDic = My.xiangqianPartDic
	for part,tb in pairs(My.hasEquipDic) do
		local id = tostring(tb.type_id)
		local equip = EquipBaseTemp[id]
		local num = equip.holesNum+add
		local stDic = tb.stDic
		local len = LuaTool.Length(stDic)
		--宝石孔是否镶嵌满
		local gemDic=PropMgr.GetGemByPart(part)
		if len==num==true then
			for index,gemid in pairs(stDic) do
				local gem = GemData[tostring(gemid)]
				local ischange = false
				--1.是否有更高级的替换
				if gemDic then 
					for i,v in ipairs(gemDic) do
						local gem1 = GemData[tostring(v)]
						if gem1.lv>gem.lv then ischange=true break end
					end
				end
				if ischange==true then  
					redDic[part]=true 
					isred=true
					break
				else
					--2.升级
					local isup = My.GetGemUp(gemid,part)
					if isup==true then isred=true redDic[part]=true break end
					redDic[part]=false
				end			
			end
		else
			local state = false
			if gemDic then state=true isred=state end
			redDic[part]=state 
		end
	end
	if isred~=My.redBool["3"] then 
		My.redBool["3"]=isred 
		My.eRed(isred,3)  
	end	

	My.eChangeRed(3)
end


--镶嵌  change:纹印增加，纹印减少--，纹印一键镶嵌卸下 装备身上纹印合成
function My.wenyinRed()
	if OpenMgr:IsOpen(My.sysDic["5"])==false then return end
	local isred = false
	local add = 0
	local vip = VIPMgr.GetVIPLv()
	local vipInfo = soonTool.GetVipInfo(vip)
	if vipInfo.sealVip== 1 then  add=1 end
	for part,tb in pairs(My.hasEquipDic) do
		local id = tostring(tb.type_id)
		local equip = EquipBaseTemp[id]
		local num = equip.SealholesNum+add
		local slDic = tb.slDic
		local len = LuaTool.Length(slDic)
		--纹印孔是否镶嵌满
		local sealDic=PropMgr.GetSealByPart(part)
		if len==num then
			for index,gemid in pairs(slDic) do
				local gem = tSealData[tostring(gemid)]
				local ischange = false
				--1.是否有更高级的替换
				if sealDic then 
					for i,v in ipairs(sealDic) do
						local gem1 = tSealData[tostring(v)]
						if gem==nil then
							iTrace.Error("soon","无数据 id="..gemid)
							return
						end
						if gem1.lv>gem.lv then ischange=true break end
					end
				end
				if ischange==true then  
					My.wenyinPartDic[part]=true 
					isred=true
					break
				else
					--2.升级
					local dic = {}
					local isup = My.GetSealUp(gemid,part)
					if isup==true then isred=true My.wenyinPartDic[part]=true break end
					My.wenyinPartDic[part]=false
				end			
			end
		else
			local state = false
			if sealDic then state=true  isred=state end
			My.wenyinPartDic[part]=state 
		end
	end
	if isred~=My.redBool["5"] then 
		My.redBool["5"]=isred 
		My.eRed(isred,5)  
	end	
	My.eChangeRed(5)
end

--淬炼
function My.cuilianRed( )
	if OpenMgr:IsOpen(My.sysDic["4"])==false then return end
	local isred =My.SetHonRedDic()
	if isred~=My.redBool["4"] then My.redBool["4"]=isred My.eRed(isred,4)  end	
	My.eChangeRed(4)
end

function My.SetHonRedDic()
	local hasCanHon = false;
	for part,tb in pairs(My.hasEquipDic) do
		local stDic = tb.stDic
		local honDic = tb.honDic
		local canHon,canHonDic = My.ChkHonHoles(stDic,honDic);
		if canHon == true then
			hasCanHon = true;
		end
		My.cuilianPartDic[part] = canHon;
	end
	return hasCanHon;
end

--检查淬炼孔
function My.ChkHonHoles(stDic,honDic)
	local canHonDic = {}
	local canHon = false;
	for index,gemId in pairs(stDic) do
		local cHon = My.ChkHonCndt(index,gemId,honDic);
		canHonDic[index] = cHon;
		if cHon == true then
			canHon = cHon;
		end
	end
	return canHon,canHonDic;
end

--获取第一个可淬炼的孔
function My.ChkHonHole(stDic,honDic)
	local tmpIndex = 100;
	for index,gemId in pairs(stDic) do
		local idx = tonumber(index);
		local cHon = My.ChkHonCndt(index,gemId,honDic);
		if cHon == true then
			if idx < tmpIndex then
				tmpIndex = idx;
			end
		end
	end
	if tmpIndex == 100 then
		return nil;
	end
	return tmpIndex;
end

--检查满足淬炼条件
function My.ChkHonCndt(index,gemId,honDic)
	local gem = GemData[tostring(gemId)]
	if gem == nil then
		return false;
	end
	if gem.lv < 4 then
		return false;
	end
	index = tostring(index);
	local honId = honDic[index];
	if honId == nil or honId == 0 then
		honId = gem.type * 100;
	end
	honId = honId + 1;
	local honInfo = HonInfo[tostring(honId)];
	if honInfo == nil then
		return false;
	end
	local needItems = honInfo.needItems;
	local len = #needItems;
	if len == 0 then
		return true;
	end
	for k,item in pairs(needItems) do
		local id = item.k;
		local val = item.v;
		local hasNum = PropMgr.TypeIdByNum(id);
		if hasNum < val then
			return false;
		end	
	end
	return true;
end

function My.GetGemUp(gemid,part)
	local hasnum = PropMgr.TypeIdByNum(gemid)
	local data = GemData[tostring(gemid)]
	if data.canGem==nil then return false end
	local num = data.num-1
	local lerp = num-hasnum
	if lerp<=0 then
		return true 
	else
		for k,gem in pairs(GemData) do
			if gem.canGem==gemid then
				local hasnum1 = PropMgr.TypeIdByNum(gem.id)
				local num1 = lerp*(gem.num)
				local lerp1 = num1-hasnum1
				if lerp1<=0 then
					return true 
				else
					for k1,gem1 in pairs(GemData) do
						if gem1.canGem==gem.id then
							local hasnum2 = PropMgr.TypeIdByNum(gem1.id)
							local num2 = lerp1*(gem1.num)
							local lerp2 = num2-hasnum2
							if lerp2<=0 then
								return true 
							else
								return false
							end
						end
					end
				end
			end
		end
	end
	return false
end

function My.GetSealUp(gemid,part)
	local hasnum = PropMgr.TypeIdByNum(gemid)
	local data = tSealData[tostring(gemid)]
	if data.canGem==nil then return false end
	local num = data.num-1
	local lerp = num-hasnum
	if lerp<=0 then
		return true 
	else
		for k,gem in pairs(tSealData) do
			if gem.canGem==gemid then
				local hasnum1 = PropMgr.TypeIdByNum(gem.id)
				local num1 = lerp*(gem.num)
				local lerp1 = num1-hasnum1
				if lerp1<=0 then
					return true 
				else
					for k1,gem1 in pairs(GemData) do
						if gem1.canGem==gem.id then
							local hasnum2 = PropMgr.TypeIdByNum(gem1.id)
							local num2 = lerp1*(gem1.num)
							local lerp2 = num2-hasnum2
							if lerp2<=0 then
								return true 
							else
								return false
							end
						end
					end
				end
			end
		end
	end
	return false
end
function My.InitTable()
	My.InitConsice()
	My.InitGem()
	My.InitSeal()
	-- My.InitGood()
end

--装备洗炼品质表
function My.InitConsice()
	for i,v in ipairs(EquipConcise) do
		local part = v.part
		local tb = My.conciseDic[tostring(part)]
		if not tb then 
			tb={}
			My.conciseDic[tostring(part)]=tb
		end
		tb[#tb+1]=i
	end
end

--宝石合成
function My.InitGem()
	local list=My.gemList
	list[1]={}
	list[2]={}
	list[3]={}
	for k,v in pairs(GemData) do
		if(v.canGem~=nil)then
			local tb = list[v.type]
			if(tb==nil)then
				tb={}
				list[v.type]=tb
			end
			tb[#tb+1]=k
			if(#tb>1)then
			 	table.sort( tb, My.SortT1)
			end
		end
	end
	if(list[2]==nil)then
		list[2]={}
	end
end
--纹印合成
function My.InitSeal()
	local list=My.sealList
	list[1]={}
	list[2]={}
	list[3]={}
	for k,v in pairs(tSealData) do
		if(v.canGem~=nil)then
			local tb = list[v.type]
			if(tb==nil)then
				tb={}
				list[v.type]=tb
			end
			tb[#tb+1]=k
			if(#tb>1)then
			 	table.sort( tb, My.SortT2)
			end
		end
	end
	if(list[2]==nil)then
		list[2]={}
	end
end

function My.SortT1(a,b)
	return GemData[a].lv<GemData[b].lv
end
function My.SortT2(a,b)
	return tSealData[a].lv<tSealData[b].lv
end

--道具合成
function My.InitGood()
	for k,v in ipairs(My.goodDic) do
		ListTool.Clear(v)
	end
	TableTool.ClearDic(My.goodDic)

	
	local dic = My.goodDic
	local c = User.instance.MapData.Category
	for i,v in ipairs(SynInfo) do
		if v.work==c or v.work==0 then 
			local tb = dic[tostring(v.type)]
			if(tb==nil)then tb={} dic[tostring(v.type)]=tb end
			tb[#tb+1]=i
		end
	end
end

--装备，饰品合成
function My.InitEquip()
	local list = My.equipList
	for i,v in ipairs(list) do
		for k1,v1 in pairs(v) do
			for k2,v2 in pairs(v1) do
				TableTool.ClearDic(v2)
			end
			TableTool.ClearDic(v1)
		end
		TableTool.ClearDic(v)
	end

	local c = User.instance.MapData.Category
	for k,v in pairs(EquipCompound) do
		if v.work==c or v.work==0 then
			local equip = EquipBaseTemp[k]
			if not equip then iTrace.eError("xiaoyu","装备基础属性表为空 id: "..tostring(k))
			else
				local part = equip.wearParts
				local dic=nil
				if part<=6 then 
					dic=list[1] --装备
				elseif part >=7 and part <= 8  then
					dic=list[2] -- 饰品 （护符  项链）
				elseif part >=9 and part <= 10 then
					dic=list[3] -- 首饰 （戒指  手镯）
				end
				local type = v.type
				local typeDic=dic[tostring(type)]
				if not typeDic then typeDic={} dic[tostring(type)]=typeDic end
				local rank = v.rank
				local rankDic = typeDic[tostring(rank)]
				if not rankDic then rankDic={} typeDic[tostring(rank)]=rankDic end
				rankDic[tostring(part)]=k 
			end
		end
	end
end

function My.SortRank(a,b)
	return a<b
end

-- 设置首饰进阶信息
function My:SetJJInfo(id)
	local info = {}
	local id1 = tostring(id)
    local item = EquipBaseTemp[id1]
	info.js = item.wearRank
	local qua = ItemData[id1].quality
    info.co = UIMisc.GetColorLb(qua)
    info.att = item.atk
    info.jia = item.arm
    info.num = item.holesNum
    My.jjInfos[#My.jjInfos + 1] = info
end

function My:ClearJJInfo()
	while #My.jjInfos>0 do
		My.jjInfos[#My.jjInfos]=nil
	end
end

--获取同心结图标
function My.KnotCell()
	local path =nil
	local id = MarryInfo.data.knotid
	local knot = KnotData[id+1]
	if knot then 
		local rank = knot.rank
		local global = GlobalTemp["73"]
		local val = global.Value1
		for i,v in ipairs(val) do
			if v.value==rank then
				path=v.id
				break
			end
		end
	end
	return path
end

------------------------------铸魂

--请求激活
function My:ReqActivte(id, cfgId)
    local msg = ProtoPool.GetByID(21231)
	msg.equip_id = id
	msg.equip_location_id = cfgId
    ProtoMgr.Send(msg)
end

--响应激活
function My.ResqActivte(msg)
    local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	local part = PropTool.FindPart(tostring(msg.equip_id))
	local tb = My.hasEquipDic[part]
	tb.forgeSoulProId = msg.forge_soul
	My:UpAction()
	My.eForgeSoul(21, part)
end

--请求铸魂升级
function My:ReqUpgrade(id)
    local msg = ProtoPool.GetByID(21233)
    msg.equip_id = id
    ProtoMgr.Send(msg)
end

--响应铸魂升级
function My.ResqUpgrade(msg)
	local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	local part = PropTool.FindPart(tostring(msg.equip_id))
	local tb = My.hasEquipDic[part]
	tb.forgeSoulLv = msg.forge_soul_cultivate
	My:UpAction()
	My.eForgeSoul(22, part)
end

--根据部位获取激活数据
function My:GetInfoFromPart(part)
    for i,v in ipairs(CastingSoulProCfg) do
        local temp = math.floor((v.id % 1000)/10)
        if tonumber(part) == temp then
            return v
        end
    end
    return nil
end

--获取部位的铸魂阶数
function My:GetClassFromPart(part)
	local tb = My.hasEquipDic[part]
	if tb == nil then return nil end
    local cfg = EquipBaseTemp[tostring(tb.type_id)]
	if cfg == nil then return nil end
    return cfg.wearRank
end

--切换装备时铸魂提示
function My:IsTips(part, id)
	if not OpenMgr:IsOpen(505) then return false end
	if not My:IsCasting(part) then return false end
	local class = My:GetClassFromPart(part)
	if class == nil or class < 7 then return false end
	local cfg = EquipBaseTemp[tostring(id)]
	if cfg == nil then return false end
	if cfg.wearRank < 9 then
		return true
	end
	return false
end

--传入配置获取x阶x星
function My:GetClass(cfg)
    local temp1 = cfg.lv%10
    local temp2 = math.floor(cfg.lv/10)
    local star = (temp1 == 0) and 10 or temp1
    local class = (temp1 == 0) and temp2 or temp2+1
    return class, star
end

--传入等级获取ID
function My:GetId(part)
	local tb = My.hasEquipDic[part]
    if tb == nil then return 0 end
    for i,v in ipairs(CastingSoulCfg) do
        if tonumber(part) == v.part and tb.forgeSoulLv == v.lv then
            return v.id
        end
    end
    return 0
end

--判断当前部位是否能铸魂
function My:IsCasting(part)
    for i,v in ipairs(ZHTowerPartOpen) do
        if v.part == tonumber(part) then
			local class = My:GetClassFromPart(part)
			return CopyMgr:IsFinishCopy(v.copyId, false) and (class >= 7)
        end
    end
    return false
end

--获取下一级的激活数据
function My:GetNextData(index)
    local cfg = CastingSoulProCfg
    local temp1 = cfg[index]
    local temp2 = cfg[index+1]
    if temp2 == nil then
        return temp1, true
    else
        local part1 = math.floor((temp1.id % 1000)/10)
        local part2 = math.floor((temp2.id % 1000)/10)
        if part1 ~= part2 then
            return temp1, true
        end
    end
    return temp2, false
end

--根据部位获取数据
function My:GetDataFromPart(part)
    for i,v in ipairs(CastingSoulCfg) do
        if tonumber(part) == v.part then
            return v
        end
    end
    return nil
end

--判断是否能升级
function My:IsUpgrade(id)
	local cfg, index = BinTool.Find(CastingSoulCfg, id)
	local temp1 = CastingSoulCfg[index]
    local temp2 = CastingSoulCfg[index+1]
    if temp2 == nil then
        return false
    else
        if temp1.part ~= temp2.part then
            return false
        end
    end
    return true
end

--更新红点
function My:UpAction()
	if OpenMgr:IsOpen(My.sysDic["6"])==false then return end
	local isred = false
	for k,v in pairs(My.hasEquipDic) do
		local cfg = EquipBaseTemp[tostring(v.type_id)]
		local part = tostring(cfg.wearParts)
		local isCasting = My:IsCasting(part)
		local state1, state2 = false, false
		if isCasting then
			local data1, index1 = BinTool.Find(CastingSoulProCfg, v.forgeSoulProId)
			local id = My:GetId(part)
			local data2, index2 = BinTool.Find(CastingSoulCfg, id)
			--是否能激活
			if data1 then
				local class, star = 1, 1
				if data2 then
					class, star = My:GetClass(data2)
				end
				local temp, isEnd = My:GetNextData(index1)
				local cond1 = class >= temp.classCond
				local cond2 = CopyMgr:IsFinishCopy(temp.layerCond, false)
				state1 = cond1 and cond2 and not isEnd
			else
				if data2 then
					local class1, star1 = EquipMgr:GetClass(data2)
					local data4 = My:GetInfoFromPart(part)
					local cond1 = class1 >= data4.classCond
					local cond2 = CopyMgr:IsFinishCopy(data4.layerCond, false)
					state1 = cond1 and cond2
				end
			end
			
			local id = My:GetId(part)
			local cfg, index = BinTool.Find(CastingSoulCfg, id)
			local nextCfg = EquipMgr:GetNextCfg(index)
			local data3 = (cfg == nil) and My:GetDataFromPart(part) or nextCfg
			local isUp = (id == 0) and true or My:IsUpgrade(id)
			state2 = RoleAssets.Essence >= data3.expend and isUp
			if state1 or state2 then
				isred = true
			end
			My.red5Dic[part] = state1 or state2
		else
			My.red5Dic[part] = false
		end
	end
	if isred ~= My.redBool["6"] then 
		My.eRed(isred, 6)
		My.redBool["6"] = isred
	end
	My.eChangeRed(6)
end

--获取下一个阶级的配置
function My:GetNextCfg(index)
    local cfg = CastingSoulCfg
    local temp1 = cfg[index]
    local temp2 = cfg[index+1]
    if temp2 == nil then
        return temp1
    else
        if temp1.part ~= temp2.part then
            return temp1
        end
    end
    return temp2
end

function My.Clear()
	My.freeTime=0
	isFirstBetterEquip4=false
	isFirstBetterEquip5=false
	TableTool.ClearDicToPool(My.hasEquipDic)	
	TableTool.ClearDic(My.redBool)
	TableTool.ClearDic(My.redBoolCom)
	for k,v in pairs(My.lockDic) do
        TableTool.ClearDic(v)
    end
	TableTool.ClearDic(My.lockDic)
end

local strList = {}
function My.SetUserData()
	ListTool.Clear(strList)
	local str = ObjPool.Get(StrBuffer)
	str:Apd(UnityEngine.Application.persistentDataPath):Apd("/"):Apd(User.instance.MapData.UID):Apd(".txt")
	local filePath = str:ToStr()
	local file = System.IO.File
	for k,v in pairs(My.lockDic) do
		str:Dispose()
		str:Apd(k)
		for index,istrue in pairs(v) do
			str:Apd("_"):Apd(index)
		end
		table.insert(strList, str:ToStr())
	end
	file.WriteAllLines(filePath,strList)
	ObjPool.Add(str)
end

function My.GetUserData()
	local str = ObjPool.Get(StrBuffer)
	str:Apd(UnityEngine.Application.persistentDataPath):Apd("/"):Apd(User.instance.MapData.UID):Apd(".txt")
	local filePath = str:ToStr()
	local file = System.IO.File
	local isExit = file.Exists(filePath)
	if isExit==false then return end
	local strList = file.ReadAllLines(filePath)
	local count = strList.Length
	if count==0 then return end
	for i=0,count-1 do
		local str = strList[i]
		local indexList = StrTool.Split(str,'_')
		local dic=nil
		for i,v in ipairs(indexList) do
			if i==1 then
				dic=My.lockDic[indexList[1]]
				if not dic then dic={} My.lockDic[v]=dic end
			else
				if StrTool.IsNullOrEmpty(v)~=true then dic[v]=true end
			end
		end
	end
	ObjPool.Add(strbu)
end

function My.Dispose()
	CopyMgr.UpdateCopyRedPoint:Remove(My.UpAction)
end

return My