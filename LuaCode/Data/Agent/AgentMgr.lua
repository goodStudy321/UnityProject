--// 道庭系统管理器 

AgentMgr = Super:New{Name = "AgentMgr"}

local mgrPre = {};
local iLog = iTrace.eLog;
local iError = iTrace.Error;
local eError = iTrace.eError;
local ET = EventMgr.Trigger;


--// 初始化
function AgentMgr:Init()

	if mgrPre.init ~= nil and mgrPre.init == true then
 		return;
	end
	
	AgentMgr:AddLsnr();

	--// 代理ID
	mgrPre.agentId = -1;
	--// 服务器Id
	mgrPre.serverId = -1;
	--// 服务器名称
	mgrPre.serverName = "";

 	mgrPre.init = true;
end

--// 添加监听
function AgentMgr:AddLsnr()

	--// 创建帮派返回
	ProtoLsnr.AddByName("m_server_info_toc", self.RespServerInfo, self);
	
end

--// 清理
function AgentMgr:Clear()
	mgrPre.init = false;
end

function AgentMgr:Dispose()
	self:Clear();
end

---------------------------------- 向服务器请求 ----------------------------------



-------------------------------------------------------------------------------

---------------------------------- 服务器推送返回 ----------------------------------

--// 收到创建道庭返回
function AgentMgr:RespServerInfo(msg)
	if msg == nil then
		return;
	end

	-- if msg.err_code ~= nil and msg.err_code > 0 then
	-- 	UITip.Error(ErrorCodeMgr.GetError(msg.err_code));
	-- 	eError("LY", ErrorCodeMgr.GetError(msg.err_code));
	-- 	return;
	-- end

	mgrPre.agentId = msg.agent_id;
	mgrPre.serverId = msg.server_id;
	mgrPre.serverName = msg.server_name;
end

-------------------------------------------------------------------------------

---------------------------------- 监听函数部分 ----------------------------------



-------------------------------------------------------------------------------

---------------------------------- 处理数据部分 ----------------------------------



-------------------------------------------------------------------------------

---------------------------------- 获取数据部分 ----------------------------------

--// 获取代理Id
function AgentMgr:GetAgentId()
	if mgrPre.agentId == nil then
		return -1;
	end

	return mgrPre.agentId;
end

function AgentMgr:GetData( )
	return mgrPre;
end

-------------------------------------------------------------------------------

return AgentMgr

