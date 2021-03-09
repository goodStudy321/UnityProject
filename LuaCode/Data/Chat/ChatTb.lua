--[[
聊天
--]]

ChatTb=Super:New{Name="ChatTb"}
local My=ChatTb
local str = ObjPool.Get(StrBuffer)

--0系统消息 1世界频道 2家族 3队伍 4私聊 5组队 6区服
--------------------------------------------聊天
function My:Init(msgs)
	self.cId=msgs.channel_id
	self.msg=msgs.msg
	self.time=msgs.time
	self.voice=msgs.voice_sec or 0
	self.voiceUrl=msgs.voice_url
	local role_info = msgs.role_info
	if role_info then
		self.info = ObjPool.Get(PlayerTb)
		self.info:Init(role_info)
	end
	local goods_list = msgs.goods_list
	if goods_list then
		self:ParseGoodDic(goods_list)
	end
end

function My:ParseGoodDic(goods_list)
	for i,v in ipairs(goods_list) do
		local id=v.id
		local type_id = tostring(v.type_id)
		local item=ItemData[type_id]
		local color=UIMisc.LabColor(item.quality)
		local name=item.name
		str:Dispose()
		str:Apd(self.info.rId):Apd("_"):Apd(id)
		local key=str:ToStr()
		str:Dispose()
		str:Apd("[url=背包道具_"):Apd(key):Apd("]"):Apd(color):Apd("["):Apd(name):Apd("][-][-]")
		local url=str:ToStr()
		local pos=string.find(self.msg,id.."$#$#")
		if pos then
			self.msg=string.gsub(self.msg,id.."$#$#",url,1)
			local tb = ChatMgr.goodDic[key]
			if not tb then
				tb=PropMgr.ParseGood(v)
				ChatMgr.goodDic[key]=tb
			end
		end
	end
end

-------------------------------------公告
function My:InitNotice(msgs)
	local id = msgs.id
	local texts = msgs.text_string
	local goods = msgs.goods_list
	local infos = msgs.role_info

	local notice=Notice[tostring(id)]
	local new=notice.content
	 
	if texts then
		for i,v in ipairs(texts) do
			new=string.gsub(new,"#",v,1)
		end
	end
	if goods then
		for i,v in ipairs(goods) do
			local id=tostring(v.type_id)
			local item=UIMisc.FindCreate(id)
			if not item then iTrace.eError("xiaoyu","道具表为空 id: "..id)return end
			local color = UIMisc.LabColor(item.quality)
			str:Dispose()
			str:Apd(color):Apd("[u][url=道具_"):Apd(id):Apd("]"):Apd(item.name):Apd("[-][/u][-]")
			new=string.gsub(new,"*",str:ToStr(),1)
 		end
	end

	if infos then
		if not self.infos then self.infos={} end
		for i,v in ipairs(infos) do
			local info = ObjPool.Get(PlayerTb)
			info:Init(v)
			self.infos[tostring(info.rId)]=info
		end
	end
	self.msg=new
end

-------------------------------------位置
function My:InitPos(msgs)
	str:Dispose()
	local info = msgs.role_info
	local mapId = msgs.map_id
	local pos = msgs.pos
	local time = msgs.time

	local map =SceneTemp[tostring(mapId)]
	local x,z=ChatMgr.DealPos(pos)
	str:Apd("[url=地图_"):Apd(mapId):Apd("_"):Apd(pos):Apd("][67cc67][u]"):Apd(map.name):Apd("（"):Apd(x):Apd(","):Apd(z):Apd("）[-][-]")
	self.msg = str:ToStr()
	self.cId=msgs.channel_id
	self.time=time
	if info then
		self.info = ObjPool.Get(PlayerTb)
		self.info:Init(info)
	end
end

function My:Dispose()
	self.voice=nil
	self.cId=nil
	self.msg=nil
	self.time=nil
	self.voiceUrl=nil
	if self.info then ObjPool.Add(self.info) self.info=nil end
	if self.goodDic then TableTool.ClearDicToPool(self.goodDic) end
	if self.infos then TableTool.ClearDicToPool(self.infos) end
end