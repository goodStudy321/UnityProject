--region SurverMgr.lua
--Date
--此文件由[HS]创建生成

SurverMgr = {Name="SurverMgr"}
local M = SurverMgr

local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr
M.eUpdateSurverState = Event()

function M:Init()
	self.strList = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J"}
	self.State = false
	self.isAction = true
	self.surveyId = -1
	self.SurverInfo = {}
	self.awardList = {}
	self:AddEvent()
end

function M:AddEvent()
	self:ProtoHandler(ProtoLsnr.Add)
end

function M:RemoveEvent()
	self:ProtoHandler(ProtoLsnr.Remove)
end

function M:ProtoHandler(Lsnr)
	Lsnr(21000, self.RespSurverState, self)	
	Lsnr(21002, self.RespSurverInfo, self)	
	Lsnr(21004, self.RespSurverSummit, self)	
end

--更新调查状态
function M:RespSurverState(msg)
	self.State = msg.is_open
	local state = self.State
	self.eUpdateSurverState(state)
	self:UpAction(self.isAction)
end

--更新调查数据
function M:RespSurverInfo(msg)
	-- iTrace.Error("msg = "..tostring(msg))
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	self:AnalysisInfo(msg.questions)
	self:AddAward(msg.rewards)
	self.surveyId = msg.survey_id
	UIMgr.Open(UISurverPanel.Name)
end

--添加奖励
function M:AddAward(award)
	ListTool.Clear(self.awardList)
	local list = award
	for i,v in ipairs(list) do
		table.insert(self.awardList, v)
	end
end

--提交问卷返回
function M:RespSurverSummit(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	self.State = false
	self:eUpdateSurverState()
end

--请求调查数据
function M:ReqSurverInfo()
	local msg = ProtoPool.GetByID(21001)
	Send(msg)
end

--提交调查数据
function M:ReqSurverSummit(text, times)
	local msg = ProtoPool.GetByID(21003)
	msg.answer_string = text
	msg.answer_time = times
	msg.survey_id = self.surveyId
	Send(msg)
end

--解析数据
function M:AnalysisInfo(str)
	ListTool.Clear(self.SurverInfo)
	local list = json.decode(str)
	for i,v in ipairs(list) do
		local qaData = {}
		qaData.quesId = v.id
		qaData.id = v.index_id
		qaData.question = v.name
		qaData.type = v.type
		qaData.max = v.max_select
		qaData.sort = v.sort
		qaData.answer = {}

		if StrTool.IsNullOrEmpty(v.options) == false then
			for k1,v1 in pairs(v.options) do
				local info = {}
				info.key = k1
				info.name = v1.name
				info.img = v1.img
				info.write = v1.write
				info.nextId = v1.next_id
				qaData.answer[k1] = info
			end
		end
		table.insert(self.SurverInfo, qaData)
		table.sort(qaData.answer, function(a,b) return self.strList(a.key) < self.strList(b.key) end)
	end
end

--根据索引获取题目ID
function M:GetIdByIndex(id)
	for i,v in ipairs(self.SurverInfo) do
		if tonumber(v.id) == id then
			return i
		end
	end
	return nil
end

--更新红点
function M:UpAction(state)
	self.isAction = state
	local actId = ActivityMgr.DCWJ
	if state then
        SystemMgr:ShowActivity(actId)
    else
        SystemMgr:HideActivity(actId)
    end
end

function M:Clear()
	ListTool.Clear(self.SurverInfo)
end

function M:Dispose()
	self:RemoveEvent()
end

return M