--region ChapterMgr.lua
--Date
--此文件由[HS]创建生成

ChapterMgr = {Name="ChapterMgr"}
local M = ChapterMgr
local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr

M.InitChapter = Event()
M.UpdateChapter = Event()

M.ChapterDic = {}

function M:Init()
	self.CurMissionID = 0
	self.StartEffTemp = nil
	self.EndEffTemp = nil
	self:AddEvent()
end

function M:AddEvent()
	self.OnInitOwner = EventHandler(self.InitOwner, self)
	self:UpdateEvent(EventMgr.Add)
	self:SetEvent("Add")
	self:ProtoHandler(ProtoLsnr.Add)
end

function M:RemoveEvent()
	self:UpdateEvent(EventMgr.Remove)
	self:SetEvent("Remove")
	self:ProtoHandler(ProtoLsnr.Remove)
end

function M:UpdateEvent(M)	
	--local EH = EventHandler
	--M("UpdateMission", EH(self.UpdateMission, self))
	--M("MissionCancel", EH(self.MissionCancel, self))
end

function M:SetEvent(fn)
end

function M:ProtoHandler(Lsnr)
	Lsnr(22600, self.RespChapterInfo, self)	
	Lsnr(22602, self.RespChapterUpdateInfo, self)	
	Lsnr(22604, self.RespChapterRewardInfo, self)	
end
-----------------------------------------------------
--章节信息推送
function M:RespChapterInfo(msg)
	local list = msg.chapter_list
	for i,v in ipairs(list) do
		local data = {}
		data.ID = v.id
		data.Num = v.num
		data.IsReward = v.is_reward
		self.ChapterDic[tostring(v.id)] = data
	end
	self.InitChapter()
end

--章节更新推送
function M:RespChapterUpdateInfo(msg)
	local v = msg.chapter
	local key = tostring(v.id)
	local data = self.ChapterDic[key]
	if not data then 
		self.ChapterDic[key] = {} 
		data = self.ChapterDic[key]
	end
	data.ID = v.id
	data.Num = v.num
	data.IsReward = v.is_reward
	self.UpdateChapter(data.ID)
end

--章节奖励领取返回
function M:RespChapterRewardInfo(msg)
	if not CheckErr(msg.err_code) then return end
	local v = msg.chapter
	local key = tostring(v.id)
	local data = self.ChapterDic[key]
	if not data then 
		self.ChapterDic[key] = {} 
		data = self.ChapterDic[key]
	end
	data.ID = v.id
	data.Num = v.num
	data.IsReward = v.is_reward
	self.UpdateChapter(data.ID)
end
------------------------------------------------------
--章节奖励领取
function M:ReqChapterRewardTos(id)
	local msg = ProtoPool.GetByID(22603)
	msg.chapter_id = id
	Send(msg)
end
------------------------------------------------------
function M:UpdateMission(id, status, succ, init)
	if self.CurMissionID == id then return end
	local temp = MissionTemp[tostring(id)]
	if temp and temp.type == MissionType.Main then
		self.CurMissionID = id
		if User.IsInitLoadScene then 
			return 
		end

		if not init and temp.cStart then
			local chapter = temp.cStart
			local c = chapter % 100
			local cTemp = ChapterTemp[c]
			if cTemp then
				if cTemp.openEff == id then
					self.StartEffTemp = cTemp
					--UIMgr.Open(UIChapterEff.Name, self.OpenEffUI, self)
				end
			else
				iTrace.eError("hs", string.format("启动章节【%s】效果失败, chapter求余 = [%s]", chapter, c))
			end
		end
	end
end

function M:MissionCancel(id, isComplete)
	if self.CurMissionID ~= id or (self.CurMissionID == id and not isComplete) then return end
	local temp = MissionTemp[tostring(id)]
	if temp and temp.type == MissionType.Main then
		if temp.cEnd then
			local chapter = temp.cEnd
			local c = chapter % 100
			local cTemp = ChapterTemp[c]
			if cTemp then
				self.EndEffTemp = cTemp
				--UIMgr.Open(UIChapterEff.Name, self.CompleteEffUI, self)
			else
				iTrace.eError("hs", string.format("完成章节【%s】效果失败, chapter % 100 = [%s]", chapter, c))
			end
		end
	end
end


function M:OpenEffUI(name)
	local ui = UIMgr.Get(UIChapterEff.Name)
	if ui then
		ui:ShowStart(self.StartEffTemp)
	end
end


function M:CompleteEffUI(name)
	local ui = UIMgr.Get(UIChapterEff.Name)
	if ui then
		ui:ShowEnd(self.EndEffTemp)
	end
end

function M:GetChapter(temp)
	local len = #ChapterTemp
	for i=1,len do
		if temp.chapter == ChapterTemp[i].id then
			return ChapterTemp[i]
		end
	end
	return nil
end

------------------------------------------------------


function M:ClearTimer()
end

function M:Clear()
	TableTool.ClearDic(self.ChapterDic)
	self.CurMissionID = 0
	self.StartEffTemp = nil
	self.EndEffTemp = nil
end

function M:Dispose()
	self:Clear()
	self:RemoveEvent()
end

return M