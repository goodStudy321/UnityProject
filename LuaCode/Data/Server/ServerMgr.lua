--region ServerMgr.lua
--Date
--此文件由[HS]创建生成
require("Data/Server/ServerData")

ServerMgr = {}
local M = ServerMgr
local Data = ServerData

M.LoadSucc = Event()
M.LoadFail = Event()
--是否获取中 防止重复启动协程获取
M.Init = true
M.IsLoad = false
--获取计时 超时重连
M.Timer = nil
M.Page = nil

--==============================--
--数据
--==============================-------------

 function M:Catch(msg)
	iTrace.eError("hs", "err Json decode:", msg)
 end
--==============================--
--load服务器数据
--==============================-------------
function M:SelectPage(index)
	local d = Data.AllData.titles[index]
	if d then
		if d.IsLoadEnter == true then	--登入过的服务器
			coroutine.start(self.LoadEnterServerData, self)
			return
		end
		if not d.IsNew then		--推荐服务器
			self.Page = d.page
		else
			self.Page = nil
		end
		coroutine.start(self.LoadServerData, self)
	end
end


function M:Load()
	self:Clear()
	local load = self.IsLoad
	if load and load == true then return end
	load = true
	--启动协程
	coroutine.start(self.LoadServerData, self)
end

--请求后台读取服务器信息
function M:LoadServerData()
	local page = self.Page
	local path = nil
	local gcid = Data:GetGameChannelID()
	--local gcid =111197
	local ver = App.Ver
	--local ver = "1.134.0"
	local url = App.BSUrl
	--local url = DomainCfg[1].exter
	local sb = ObjPool.Get(StrBuffer)
	sb:Apd(url):Apd("index/Server/entranceList?")
	sb:Apd("game_channel_id="):Apd(gcid)
	sb:Apd("&version_name="):Apd(ver)
	sb:Apd("&server_option="):Apd(App.SvrOp)
	sb:Apd("&imei="):Apd(DeviceEx:GetIMEI())
	if page ~= nil then
		sb:Apd("&page="):Apd(page)
	end
	path = sb:ToStr()
	ObjPool.Add(sb)
	if StrTool:IsNullOrEmpty(path) then
		iTrace.eError("hs", "LoadServerData path is nil")
		return
	end
	if App.CanDebug then
		iTrace.Log("hs","正在获取服务器信息。。。",path)
	end
	self.Timer = os.time()		--计时 超过事件未收到数据返回判定掉线
	WWWTool.LoadText(path, self.OnWWWCallback, self )
end

--后台返回服务器信息数据
function M:OnWWWCallback(text, err)
	local s = text
	if StrTool.IsNullOrEmpty(err) == false or StrTool.IsNullOrEmpty(s) == true then
		self.LoadFail()
		iTrace.eLog("hs", string.format("读取服务器文件失败,重新进行获取", path))
		return
	end
	if StrTool.IsNullOrEmpty(s) == false then
		xpcall(self.JsonDecode, self.Catch, self, s)
	end
end

--解析json
function M:JsonDecode(s)
	local t = json.decode(s)

	if Data:CheckServer(t) == false then	
		MsgBox.ShowYes("没有可用的服务器")	
		self.LoadSucc()
		return
	end
	TableTool.print(t[1])		--输出

	Data:ServerInfo(t[1].pagination)
	Data:UpdateServer(t[1].servers)
	Data:UpdateTitle(t[1].category, self.Page)
	iTrace.eLog("hs", "读取服务器文件完成")
	--启动协程
	if self.Init == true then
		coroutine.start(self.LoadEnterServerData, self)
	end
end

---获取登入过的服务器数据
function M:LoadEnterServerData()
	local sb = ObjPool.Get(StrBuffer)
	sb:Apd(App.BSUrl):Apd("index/Server/serverHistory")
	local path = sb:ToStr()
	ObjPool.Add(sb)
	if StrTool:IsNullOrEmpty(path) then
		iTrace.eError("hs", "LoadEnterServerData path is nil")
		return
	end
	iTrace.eLog("hs","正在获取登入过的服务器信息。。。",path)
	self.Timer = os.time()
	local form = WWWForm.New()
	form:AddField("uid", UserMgr:GetAccount())
	form:AddField("version", 2)
	form:AddField("version_name", App.Ver)
	form:AddField("game_channel_id", User.GameChannelId)
	local www = UnityWebRequest.Post(path,form)
	www:SendWebRequest();
    coroutine.www(www)
	local err = www.error
	if not StrTool.IsNullOrEmpty(err) then
	  iTrace.Error("hs", "加载:", path, ", 错误:", err)
	else
	  err = nil
	end
	self:OnEnterWWWCallback(www.downloadHandler.text, err)
	www:Dispose()
end

function M:OnEnterWWWCallback(text, err)
	self.Timer = nil
	local s = text
	if StrTool.IsNullOrEmpty(err) == false or StrTool.IsNullOrEmpty(s) == true then
		MsgBox.CloseOpt = MsgBoxCloseOpt.Yes
		MsgBox.ShowYes(string.format("读取登入服务器错误:%s",err),self.LoadEnterServerData,self)	
		iTrace.eLog("hs", string.format("读取登入过的服务器文件失败,重新进行获取", path))
		return
	end
	if StrTool.IsNullOrEmpty(s) == false then
		xpcall(self.LoadEnderJsonDecode, self.Catch, self, s)
	end
end

function M:LoadEnderJsonDecode(s)
	local t = json.decode(s)
	TableTool.print(t.data)

	Data:UpdateRecordData(t.data)
	if self.Init == true then
		self.Init = false
		self.LoadSucc()
		return
	end
	iTrace.eLog("hs", "读取登入过的服务器文件完成")
end

function M:LoadServerFail()
	self:Load()
end

--写入缓存数据
function M:RecordWrite(index, uid, serverid)
	coroutine.start(self.Write,self,uid,serverid)
end

function M:Write(uid, serverid)
	local sb = ObjPool.Get(StrBuffer)
	sb:Apd(App.BSUrl):Apd("index/Server/serverRecording")
	local path = sb:ToStr()
	ObjPool.Add(sb)
	local form = WWWForm.New()
	form:AddField("uid",uid)
	form:AddField("server_id",  serverid)
	form:AddField("version", 2)
	form:AddField("version_name", App.Ver)
	form:AddField("game_channel_id", User.GameChannelId)
	local www = UnityWebRequest.Post(path, form)
	www:SendWebRequest()
	coroutine.www(www)
	local err = www.error
	www:Dispose()
end

function M:EnterRecordWrite()
	local j = json.encode(Data.RecordData)
	if StrTool.IsNullOrEmpty(j) == true then return end
	User.EnterRecord = j
end

function M:Update()
	if self.Timer then 
		if os.time() - self.Timer >= 10 then
			self:Clear()
			--MsgBox.ShowYes("获取服务器超时, 重新获取",self.LoadServerFail,self)	
			self.LoadFail("连接超时")
		end
	end
end

function M:Clear()
	iTrace.eLog("hs", "清除服务器数据，设置IsLoad = false")
	self.IsLoad = false
	self.Init = true
	self.Page = nil
	Data:Clear()
end

function M:Dispose()
	-- body
end

return M
