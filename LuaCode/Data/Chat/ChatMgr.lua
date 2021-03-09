--[[
聊天管理类
--]]
require("Data/Chat/ChatTb")
require("Data/Chat/PlayerTb")

ChatMgr={Name="ChatMgr"}
local My=ChatMgr
My.eRemove=Event()
My.eAddChat=Event()
My.eSys=Event()
My.eTop=Event()
My.eDelTop=Event()
My.eBan=Event()
My.eRecord=Event()

local GetError = nil
local MAXCOUNT=50
-- My.playNum=0
local indexDic={} --从1开始
My.MsgDic={}--消息记录 --ChatTb
My.TeamList={} --组队消息
My.SysList={} --系统消息
My.BanDic={} --屏蔽得玩家列表
My.goodDic={} --物品信息 key:roleId_id value:tb
My.PrivateDic={} --私聊信息
My.TopDic={} --置顶消息 
My.tpDic={} --聊天频道筛选
My.quaDic={} --聊天频道掉落颜色筛选
My.isSend={} --能否发送（计时10秒）
local timer = {}
local isPosSend = true
local posTimer = nil
local str = ObjPool.Get(StrBuffer)

My.writeRecord={} --输入文字记录

function My.Init()
	GetError = ErrorCodeMgr.GetError

	My.AddLnsr()
	My.GetUserData()

	--EventMgr.Add("SelectSuc",My.CheckVoice)
	
end

function My.CheckVoice()
	if App.platform == Platform.Android and Device.SysSDKVer>22 then 
		local tp=Activity.Instance:Check("RECORD_AUDIO")
		if tp==-1 then --拒绝
			Activity.Instance:Req("RECORD_AUDIO")
		end
	end
end

--添加事件
function My.AddLnsr()
  local Add = ProtoLsnr.Add
  Add(20892, My.ResqText)
  Add(20894, My.ResqTop)
  Add(20896, My.ResqDelTop)
  Add(20898, My.ResqPos)
  Add(20902,My.ResqBanInfo)
  Add(20904,My.ResqBanAdd)
  Add(20906,My.ResqBanDel)
  Add(26200,My.ResqHistory)
end

-----------------------------------------协议
--聊天历史记录
function My.ResqHistory(msg)
	local list=msg.chat_list
	local posList=msg.pos_list
	for i,v in ipairs(list) do
		My.SetChat(v,false)
	end
	for i,v in ipairs(posList) do
		My.SetPos(v,false)
	end
	local daoting = My.MsgDic["2"]
	if daoting and #daoting>0 then table.sort( daoting, My.SortTime ) end
	local shijie = My.MsgDic["1"]
	if shijie and #shijie>0 then table.sort( shijie, My.SortTime ) end
	local haoyou = My.PrivateDic
	for k,v in pairs(haoyou) do
		if #v>0 then table.sort( v, My.SortTime ) end
	end
	My.eRecord()
end

function My.SortTime(a,b)
	return a.time<b.time
end

--聊天
function My.ReqText(cTp,cId,voice,msgs,idList,url)
	My.channelType = cTp
	My.channelId = cId
	My.voiceSec = voice
	My.chatMsg = msgs
	My.goodsIdList = idList
	My.voiceUrl = url

	if Sdk then
		local sdkIndex = Sdk:GetSdkIndex()
		if sdkIndex == 8 then
			local url = App.BSUrl .. "Index/zhangchuang/filterChat"
			local user = User.instance
			local data = user.MapData
			local serverId = user.ServerID --区服ID
			local roleId = data.UIDStr  --角色ID
			local roleName = data.Name  --角色名称
			local message = My.chatMsg  --聊天内容
			local extern = ""  --透传参数(Response的时候会原样带回)

			message = UIMisc.urlEncode(message)

			local sb = ObjPool.Get(StrBuffer)
			sb:Apd(url):Apd("?server_id="):Apd(serverId)
			sb:Apd("&role_id="):Apd(roleId)
			sb:Apd("&role_name="):Apd(roleName)
			sb:Apd("&message="):Apd(message)
			sb:Apd("&ext="):Apd(extern)
			local fullPath = sb:ToStr()
			ObjPool.Add(sb)
			iTrace.Log("lgs","Lua  聊天文字 向后台发送  url: ",fullPath)
			WWWTool.LoadText(fullPath, My.NotifyUrl)
		else
			My.SendMsgToServer(cTp,cId,voice,msgs,idList,url)
		end
	else
		My.SendMsgToServer(cTp,cId,voice,msgs,idList,url)
	end
end

function My.SendMsgToServer(cTp,cId,voice,msgs,idList,url)
	local msg = ProtoPool.GetByID(20891)
	msg.channel_type=cTp
	msg.channel_id=cId
	msg.voice_sec=voice
	msg.msg=msgs
	for i,v in ipairs(idList) do
		msg.goods_id_list:append(tonumber(v))
	end
	msg.voice_url=url or "0"

	ProtoMgr.Send(msg)
	if cTp~=1 and cTp~=6 then return end
	My.isSend[tostring(cTp)]=false
	local ti=timer[tostring(cTp)]	
	if ti==nil and cTp==1 then ti=ObjPool.Get(iTimer) ti.complete:Add(My.DealSendTime1) end
	if ti==nil and cTp==6 then ti=ObjPool.Get(iTimer) ti.complete:Add(My.DealSendTime6) end
	if ti then 
		ti:Stop()
		ti.seconds=6
		ti:Start()
	end
	My.channelType = nil
	My.channelId = nil
	My.voiceSec = nil
	My.chatMsg = nil
	My.goodsIdList = nil
	My.voiceUrl = nil
end

function My.NotifyUrl(text,err)
    iTrace.Log("lgs","聊天文字发送成功，后台返回 result, text: ",text,", err: ",err)
    if(StrTool.IsNullOrEmpty(err)) then
        local res = json.decode(text)
        local status = res.status
        local code = status.code
		local msg = status.msg
		local data = res.data
        if code == 10200 then --校验成功
			local cTp = My.channelType
			local cId = My.channelId
			local voice = My.voiceSec
			local msgs = data
			local idList = My.goodsIdList
			local url = My.voiceUrl
			My.SendMsgToServer(cTp,cId,voice,msgs,idList,url)
        else
            UITip.Error(msg)
        end
    end
end

function My.DealSendTime1()
	My.isSend["1"]=true
end

function My.DealSendTime6()
	My.isSend["6"]=true
end

--0系统消息 1世界频道 2家族 3队伍 4私聊 5组队 6区服
function My.ResqText(msgs)
	local err = msgs.err_code
	if(err==0)then
		My.SetChat(msgs)
	else
		UITip.Log(GetError(err))
	end
end

function My.SetChat(msgs,isevent)
	local tb = ObjPool.Get(ChatTb)
	tb:Init(msgs)
	local cTp = msgs.channel_type
	if(cTp==0)then
		My.SetSys(tb,nil,isevent)
	elseif(cTp==4)then
		My.SetPrivate(tb,isevent)
	else
		My.Msg(tb,cTp)
	end
end

--置顶消息
function My.ResqTop(msg)
	local cTp=msg.channel_type
	local msg=msg.msg
	local tb=My.TopDic[tostring(cTp)]
	if(tb==nil)then tb={} My.TopDic[tostring(cTp)]=tb end
	tb[#tb+1]=msg
	My.eTop(cTp)
end

--置顶消息移除
function My.ResqDelTop()
	My.eDelTop()
end

--发送坐标位置
function My.ReqPos(cTp,cId,pos)
	if not posTimer then posTimer=ObjPool.Get(iTimer) posTimer.complete:Add(My.PosTimeEnd) end
	if isPosSend==false then UITip.Error("您发送位置真活跃，休息下再发吧") return end
	isPosSend=false
	posTimer:Stop()
	posTimer.seconds=10
	posTimer:Start()
	local msg = ProtoPool.GetByID(20897)
	msg.channel_type=cTp
	msg.channel_id=cId
	msg.pos=pos
	ProtoMgr.Send(msg)
end

function My.PosTimeEnd()
	isPosSend=true
end

--发送坐标位置返回
function My.ResqPos(msg)
	local err = msg.err_code
	if(err==0)then
		My.SetPos(msg)
	else
		UITip.Log(GetError(err))
	end
end

function My.SetPos(msg,isevent)
	local cTp = msg.channel_type
	local tb = ObjPool.Get(ChatTb)
	tb:InitPos(msg)
	if cTp==4 then --私聊			
		My.SetPrivate(tb,isevent)
	else
		My.Msg(tb,cTp,isevent)
	end
end

function My.DealPos(pos)
	local index = string.find(pos,"_")
	local x = string.sub(pos,1,index-1)
	local z = string.sub(pos,index+1)
	return math.ceil( x ),math.ceil( z )
end

--区域屏蔽
function My.ResqBanInfo(msg)
	local list = msg.role_infos
	if list and #list>0 then
		for i,v in ipairs(list) do
			local tb=ObjPool.Get(PlayerTb)
			tb:Init(v)
			My.BanDic[tostring(v.role_id)]=tb
		end
	end
end

function My.ReqBanAdd(id)
	local msg = ProtoPool.GetByID(20903)
	msg.add_role_id=id
	ProtoMgr.Send(msg)
end

function My.ResqBanAdd(msg)
	local err = msg.err_code
	if err==0 then
		UITip.Log("屏蔽成功")
		local info = msg.add_role_info
		local id = info.role_id
		local tb=My.BanDic[tostring(id)]
		if not tb then tb=ObjPool.Get(PlayerTb) end
		tb:Init(info)
		My.BanDic[tostring(id)]=tb

		My.eBan(1,id)
	else
		UITip.Log(GetError(err))
	end
end

--解除屏蔽
function My.ReqBanDel(id)
	local msg = ProtoPool.GetByID(20905)
	msg.del_role_id=id
	ProtoMgr.Send(msg)
end

function My.ResqBanDel(msg)
	local err = msg.err_code
	if err==0 then
		UITip.Log("解除成功")
		local id = tonumber(msg.del_role_id)
		if id==0 then --0代表所有
			TableTool.ClearDicToPool(My.BanDic)
		else
			local tb = My.BanDic[tostring(id)]
			ObjPool.Add(tb)
			My.BanDic[tostring(id)]=nil
		end
		My.eBan(2,id)
	else
		UITip.Log(GetError(err))
	end
end

---------------------------------------------私有方法
--系统消息 ismain是否显示主界面
function My.SetSys(msg,id,ismain)
	if msg==nil then iTrace.eError("xiaoyu","                   公告id： "..id)return end
	local tb = My.SysList
	if(#tb==MAXCOUNT)then
		local kv = tb[1]
		ObjPool.Add(kv)
		table.remove(tb,1)
		My.eRemove(0) --删除旧记录（不保存）删除的索引
	end
	local kv = ObjPool.Get(KV)
	kv:Init(msg,id)
	tb[#tb+1]=kv
	My.eSys(0,#tb,ismain)
end

local str=ObjPool.Get(StrBuffer)
function My.SetTeam(name,mapId,minLv,maxLv,teamId,index)
	local tb=My.TeamList
	str:Dispose()
	local map =SceneTemp[tostring(mapId)]
	-- minLv=UserMgr:chageLv(minLv)
	-- maxLv=UserMgr:chageLv(maxLv)
	if not map then iTrace.eError("xiaoyu","场景表为空 id: "..tostring(mapId))return end	
	local mapName = map.name
	if index==1 then mapName="藏宝图" end
	-- str:Apd(name):Apd(": "):Apd(mapName):Apd("开组了，等级"):Apd(minLv):Apd(" - ")
	-- :Apd(maxLv):Apd("的小伙伴赶紧进组，[u][url=组队_"):Apd(teamId):Apd("][00FF00FF]申请入队[-]"):Apd("[-][/u]")
	str:Apd("玩家[F39800FF]"):Apd(name):Apd("[-]开启"):Apd(mapName):Apd("组队副本，"):Apd("全体组员收益共享，")
	:Apd(minLv):Apd(" - "):Apd(maxLv):Apd("等级的玩家赶紧进组，[u][url=组队_"):Apd(teamId):Apd("][00FF00FF]申请入队[-]"):Apd("[-][/u]")
	local msg=str:ToStr()
	if(#tb==MAXCOUNT)then
		table.remove(tb,1)
		My.eRemove(5) --删除旧记录（不保存）删除的索引
	end
	tb[#tb+1]=msg
	My.eSys(5,#tb)
end

--私聊消息
function My.SetPrivate(chatTb,isevent)
	local cId=tostring(chatTb.cId)
	local tb = My.PrivateDic[cId]
	if(tb==nil)then
		tb={}
		My.PrivateDic[cId]=tb
	end
	if(#tb==MAXCOUNT)then
		local one = tb[1]
		ObjPool.Add(one)
		table.remove(tb,1)
		--删除私聊
		My.eRemove(4)
	end
	
	tb[#tb+1]=chatTb
	if isevent~=false then My.eAddChat(4,#tb,chatTb)end
end

--聊天消息
function My.Msg(chatTb,cTp,isevent)
	--频道
	local cTb=My.MsgDic[tostring(cTp)]
	local maxIndex=indexDic[tostring(cTp)]
	local msg = chatTb.msg
	local message = msg
	
	--检测当前添加频道数量
	if(maxIndex==MAXCOUNT)then
		local min=cTb[1]
		ObjPool.Add(min)
		table.remove(cTb,1)
		My.eRemove(cTp) --删除旧记录（不保存）删除的索引
	end

	if(maxIndex==nil)then maxIndex=1 
	elseif(maxIndex<MAXCOUNT)then maxIndex=maxIndex+1 end

	if(cTb==nil)then 
		cTb={}
		My.MsgDic[tostring(cTp)]=cTb
	end

	--标记道庭答题系统消息
	if cTp == 2 and chatTb.info and tonumber(chatTb.info.rId) == 2 then
		message = "[67cc67]"..msg.."[FFFFFFFF]学识渊博，为道庭获得了1点积分。"
	elseif cTp == 2 and  chatTb.info and tonumber(chatTb.info.rId) == 1 then
		message = "[67cc67]"..msg.."[FFFFFFFF]学识渊博，为道庭获得了1点积分，题目已全部答完。"
	end
	chatTb.msg=message
	cTb[maxIndex]=chatTb
	if isevent~=false then 
		My.eAddChat(cTp,maxIndex,chatTb) 
	end
	indexDic[tostring(cTp)]=maxIndex
end

--==============================--
--desc:
--time:2018-12-30 08:59:32
--@return 
--==============================------------
local mTp = nil
function My.OpenChat(tp)
	if tp==nil then tp=0 end
	mTp=tonumber(tp)
	UIMgr.Open(UIChat.Name,My.ChatCb)
end

function My.ChatCb(name)
	local ui=UIMgr.Get(name)
	if ui then
		if User.SceneId == 30007 then
			ui:SwatchTg(2)
		else
			ui:SwatchTg(mTp)
		end
		ui:SetTween(true)
	end
end

function My.Clear()
	--My.playNum=0
	TableTool.ClearDic(indexDic)
	for k,v in pairs(My.MsgDic) do
		ListTool.ClearToPool(v)
		My.MsgDic[k]=nil
	end
	ListTool.Clear(My.TeamList)
	ListTool.ClearToPool(My.SysList)
	--TableTool.ClearDic(My.PlayerDic)
	for k,v in pairs(My.PrivateDic) do
		ListTool.ClearToPool(v)
		My.PrivateDic[k]=nil
	end
	TableTool.ClearDic(My.writeRecord)
end

function My.SetUserData()
	local strList={}
    local filePath = string.format( "%s/ChatSave.txt",UnityEngine.Application.persistentDataPath)
	local file = System.IO.File
	local str = ObjPool.Get(StrBuffer)
	local quaDic = My.quaDic
	for k,v in pairs(quaDic) do
		local bo = v==true and 1 or -1
		str:Apd(k):Apd("_"):Apd(bo):Apd("_")
	end
	strList[1]=str:ToStr()
	str:Dispose()
	local tpDic = My.tpDic
	for k,v in pairs(tpDic) do
		local bo = v==true and 1 or -1
		str:Apd(k):Apd("_"):Apd(bo):Apd("_")
	end
	strList[2]=str:ToStr()
	file.WriteAllText(filePath,"")
    file.WriteAllLines(filePath,strList)
end

function My.GetUserData()
	TableTool.ClearDic(My.tpDic)
    local filePath = string.format( "%s/ChatSave.txt",UnityEngine.Application.persistentDataPath)
    local file = System.IO.File
	local isExit = file.Exists(filePath)
    if isExit==false then My.InitTpDic() return end
    local strList = file.ReadAllLines(filePath)
	local count = strList.Length
	if count==0 then 
		My.InitTpDic()
	else
		local str1 = strList[0]
		My.SetDic(str1,My.quaDic)
		local str2 = strList[1]
		My.SetDic(str2,My.tpDic)
	end
    
end

function My.InitTpDic()
	for i=0,6 do
		if i~=4 then
			My.tpDic[tostring(i)]=true
		end
	end  
	TableTool.ClearDic(My.quaDic)
	for i=1,6 do
		My.quaDic[tostring(i)]=true
	end    
end

function My.SetDic(str,dic)
	local list = StrTool.Split(str,"_")
	if #list==0 then return end
	for i,v in ipairs(list) do
		local x,xx = math.modf(i/2 )
		if xx==0 then 
			local k = list[i-1]
			local bo = v=="1" 
			dic[tostring(k)]=bo
		end
	end
end

return My