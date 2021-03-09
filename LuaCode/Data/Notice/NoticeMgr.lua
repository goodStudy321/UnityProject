--[[
公告管理
--]]
NoticeMgr={Name="NoticeMgr"}
local My=NoticeMgr

My.showList={}
My.noShowList={}
My.noticeList={}

My.isRefresh=false
My.isOpen=true
local tp = nil
My.eRefresh=Event()
local str = ObjPool.Get(StrBuffer)

function My.Init()
	My.AddLnsr()
end

--添加事件
function My.AddLnsr()
  local Add = ProtoLsnr.Add
  Add(20880, My.ResqNotice)
end

function My.ResqNotice(msg)
	local id = msg.id
	local texts = msg.text_string
	local goods = msg.goods_list
	local infos = msg.role_info
	
	local notice=Notice[tostring(id)]
	if not notice then iTrace.Error("xiaoyu","公告表为空 id"..tostring(id)) return end
	local showType = notice.showType
	if showType==1 then --聊天频道仙盟
		local tbb=ObjPool.Get(ChatTb)
		tbb:InitNotice(msg)
		ChatMgr.Msg(tbb,2)
	elseif showType==2 then --大字广播
		local tbb=ObjPool.Get(NoticeTb)
		tbb:Init(id,texts,goods)
		My.noticeList[#My.noticeList+1]=tbb
	elseif showType==4 then --聊天队伍
		local tbb=ObjPool.Get(ChatTb)
		tbb:InitNotice(msg)
		ChatMgr.Msg(tbb,3)
	end

	if notice.show==-1 then return end
	local tb=ObjPool.Get(NoticeTb)
	tb:Init(id,texts,goods)
	local refresh = notice.refresh
	local count=0	
	if(notice.show==1)then
		table.insert(My.showList,tb)
		count=#My.showList
	else
		table.insert(My.noShowList,tb)
		count=#My.noShowList
	end	

	if refresh==1 then --即时刷新
		My.eRefresh(notice.show,count)
	end

	local key = tostring(User.SceneId)
	local scene = SceneTemp[key]
	if scene and scene.mapchildtype == SceneSubType.OffL1V1Map then
		return
	end

	local ui = UIMgr.Get(UINotice.Name)
	if not ui then 
		UIMgr.Open(UINotice.Name)
	else
		ui:Open()
	end
end

function My.DealTx(tb)
	local texts=tb.textList
 	local props=tb.propList

 	local notice=Notice[tostring(tb.id)]
 	local new=notice.content

 	--人名
	if(texts~=nil)then
 		for i,v in ipairs(texts) do
 		 	new=string.gsub(new,"#",v,1)
 		end
 	end

 	--道具名字
	if(props~=nil)then
		 for i,v in ipairs(props) do
			local id=tostring(v.type_id)
			local item=UIMisc.FindCreate(id)
			if not item then iTrace.eError("xiaoyu","道具表为空 id: "..id)return end
			local color = UIMisc.LabColor(item.quality)
			str:Dispose()
			str:Apd(color):Apd("[u][url=道具_"):Apd(id):Apd("]"):Apd(item.name):Apd("[-][/u][-]")
 			new=string.gsub(new,"*",str:ToStr(),1)
 		end
 	end
 	return new
end

local propId=nil
function My.DealUrl(id,url)
	if not url then return end
	My.OpenPrivate(url,id)

	local notice = Notice[id]
	if not notice then return end
	local open = notice.open
	if not open then return end
	My.OpenNotice(open[1],open[2])
end

--自定义超链接格式
function My.OpenPrivate(url,id)
	if StrTool.IsNullOrEmpty(url)then return end	
	local list = StrTool.Split(url,"_")
	if #list>1 then
		local name = list[1]
		local id=list[2]
		if(name=="道具")then
			My.DealProp(id)
		elseif(name=="背包道具")then
			My.DealBag(list[2].."_"..list[3])
		elseif(name=="充值")then
			My.DealCharge()
		elseif(name=="升级")then
			My.DealLv()
		elseif(name=="组队")then
			My.DealTeam(tonumber(id))
		elseif(name=="地图")then
			My.DealMap(list,1)
		elseif name=="我要助战" or name=="前往助战" then
			My.DealMap(list,100)
		elseif name=="查看信息" then
			My.RoleInfo(id,list[3])
		elseif name=="立即前往" then
			FamilyEscortMgr:ReqRoleEscortRobBack(tonumber(id))
		end
	end
end

--系统公告表配置的超链接
function My.OpenNotice(openName,tp)	
	if tp then tp=tonumber(tp) end
	QuickUseMgr.Jump(openName,tp)
end

--道具Tip
function My.DealProp(id)
	propId=id
	local item=ItemData[id]
	if item.uFx==1 then
		UIMgr.Open(EquipTip.Name,My.PropCb)
	else
		UIMgr.Open(PropTip.Name,My.PropCb)
	end
end

--背包道具Tip
local good=nil
function My.DealBag(id)
	good=ChatMgr.goodDic[id]
	if good then
		local item=UIMisc.FindCreate(tostring(good.type_id))
		if item.uFx==1 then
			UIMgr.Open(EquipTip.Name,My.OpenCb)
		else
			UIMgr.Open(PropTip.Name,My.OpenCb)
		end
	end
end

function My.OpenCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then 
		ui:UpData(good)
	end
end

--申请加入队伍
function My.DealTeam(teamId)
	TeamMgr:ReqTeamApply(teamId,0)
end

function My.DealMap(list,lp)
	if not list or #list==0 then return end
	local SceneId = tonumber(list[2])
	local scene= SceneTemp[list[2]]
	if not scene then iTrace.eError("xiaoyu","场景表为空 id: "..SceneId)return end
	local x = list[3]
	local y = list[4]
	local po = Vector3.New(tonumber(x)/lp,0,tonumber(y)/lp)
	if scene.type==3 then
		UITip.Error("该地图无法传送")
		return 
	end
	if User.instance.SceneId==SceneId then
		if scene.type==1 then 
			My.TransferScene(SceneId,po,scene.map)
		else
			User.instance:StartNavPathPure(po,scene.map)
		end
	else
		local data = SceneTemp[tostring(User.instance.SceneId)]
		if data.isBassScene==1 then UITip.Error("您在打宝地图中，不能进行传送")return end

		if scene.type==1 and scene.unlocklv>User.instance.MapData.Level then
			UITip.Error("等级不符合要求，无法传送") 
			return 
		end
		local ischange = SceneMgr:IsChangeScene()
		if ischange==false then return end
		if scene.isBassScene==1 then --调用打宝接口
			BossEnter:enterPos(SceneId,po)
		else
			My.TransferScene(SceneId,po,scene.map)
		end
	end
end

--传送
function My.TransferScene(SceneId,po,mapid)
	if VIPMgr.GetVIPLv()>0 or PropMgr.typeIdDic["31015"] then --有飞鞋用飞鞋

		if VIPMgr.GetVIPLv() <= 0 then
			UITip.Log("消耗小飞鞋 x 1");
		end
		MapHelper.instance:LittleFlyShoes(SceneId, po)
	else
		User.instance:StartNavPathPure(po,mapid)
	end	
end

function My.PropCb(name)
	local ui=UIMgr.Get(name)
	if ui then
		ui:UpData(propId)
	end
end

function My.RoleInfo(id,server_name)
	local isCross = false
	if server_name~=tostring(FamilyBossInfo.server_name) then isCross=true end
	UserMgr:ReqRoleObserve(tonumber(id),isCross) 
end

function My.Clear()
	ListTool.ClearToPool(My.showList)
	ListTool.ClearToPool(My.noShowList)
end

return My