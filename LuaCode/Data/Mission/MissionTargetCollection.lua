--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetCollection = baseclass(MissionTarget)
local M = MissionTargetCollection
local Error = iTrace.Error

--构造函数
function M:Ctor()
	self.CTemp = nil			--采集物配置表
	self.Wild = nil 			--野外刷新配置表
	self.IsActive = false
end

function M:ServerData(t, v, n)
	if self.Num and n > self.Num then 
		self.IsActive = false
		MissionMgr:Execute(false)
	end
	self:Super("ServerData", t, v, n)
end

--更新目标数据
function M:UpdateTarData(tar)
	self.TID = tar[1] 			--怪物ID
	self.SID = tar[2]
	self.LNum = tar[3]
	self:Super("UpdateTarData",tar)
	self:AddOpenUIEvent()
	if self.Num and self.LNum and self.Num >= self.LNum then
    	--EventMgr.Remove("UIOpen", self.OnOpenCollectionUI)
    	euiopen:Remove(self.OnOpenCollectionUI, self)
    end
end

function M:UpdateTabelData()
	self.CTemp = BinTool.Find(CollectionTemp,self.TID)--CollectionTemp[tostring(self.TID)]
	if not self.CTemp then 
   		Error("hs", string.format("采集物物ID：%s 不存在！！", self.TID))
   	end
	if not self.STemp then return end
   	local len = #self.STemp.update
   	for i=1, len do
   		local temp = WildMapTemp[tostring(self.STemp.update[i])]
   		if temp and self.TID == temp.cID then
   			self.Wild = temp
   			return
   		else
   			temp = nil
   		end
   	end
end

--执行任务目标
function M:AutoExecuteAction(fly, execute)
	self.Execute = execute
	local isHg = Hangup:GetAutoHangup();
	if isHg == false then
		return;
	end
	if self:CollectionPosNavPath() then return end
	if not self.STemp or not self.Wild or not self.CTemp then return end
	local state = UIMgr.GetActive(UICollection.Name)
	if state ~= 1 then
		self:NavPath(self.CollectionPos, self.SID, 0, 0, fly)
	else
		self:OpenCollectionUI(UICollection.Name)
	end
	MissionMgr:Execute(true)
end

function M:CustomNPComplete()
	if not self.CTemp or not self.STemp then return end
	if self.Num and self.LNum and self.Num >= self.LNum then
		local main = MissionMgr.Main
		if main then
			main:AutoExecuteAction()
		end
		return
	end
	self:CollectionPosNavPath()
	--User:PathfindingToCollectionPos(self.CTemp.id, self.STemp.id, self.cDis)
end

function M:CollectionPosNavPath()
	local lbPos = self.Wild.lbPos
	local rtPos = self.Wild.rtPos
	self.CollectionPos = Vector3.New((lbPos.x + rtPos.x) / 2 * 0.01, 0, (lbPos.y + rtPos.y) / 2 * 0.01)
	local rolePos = Vector3.New(User.Pos.x, 0, User.Pos.z)
	local dis = self:Distance(rolePos, self.CollectionPos)
	local cDis = self.CTemp.dis * 0.01
	if dis <= cDis then
		coroutine.start(MissionNavPath.CollectionPosNavPath, self.CTemp.id, self.STemp.id, cDis, self.Execute)
		return true
	end
	return false
end

--任务描述
function M:TargetDes()
	local des = ""
	local tarName = "采集物名字"
	if self.CTemp then tarName = self.CTemp.name end
	local num = self.Num or 0
	des = string.format("获取[%s]%s[-](%s/%s)", "%s", tarName, num, self.LNum) 
	return des
end

function M:Einterupt(id, err)
	CollectMgr.einterupt:Remove(self.Einterupt, self)
	self.IsActive = false
	MissionMgr:Execute(false)
    --EventMgr.Remove("UIOpen", self.OnOpenCollectionUI)
end

--[[[
function M:CloseUI(uiname)
	if name ~= UICollection.Name then return end
	self.IsActive = false
	MissionMgr:Execute(false)
    euiclose:Remove(self.CloseUI,self);
end
]]--

function M:OpenCollectionUI(name, ui)
	if name ~= UICollection.Name then return end
	if not CollectMgr.cfg then return end
	if CollectMgr.cfg.id ~= self.TID then return end
	if CollectMgr.state == CollectState.Running then return end
	local isHg = Hangup:GetAutoHangup();
	if isHg == false then return end
	if self:RemoveOpenUI() then
		return
	end
	User:StopNavPath()
   -- euiclose:Add(self.CloseUI,self);
   	CollectMgr.ReqBeg()
end


function M:AddOpenUIEvent()
	if self.IsActive == true then return end
	self.IsActive = true
	--self.OnOpenCollectionUI = EventHandler(self.OpenCollectionUI, self)
	CollectMgr.einterupt:Add(self.Einterupt, self)
    euiopen:Add(self.OpenCollectionUI, self);
end

function M:RemoveOpenUI()
	if self.Num and self.LNum and self.Num >= self.LNum then
    	euiopen:Remove(self.OnOpenCollectionUI, self)
    	self.IsActive = false
    	return true
	end
	return false
end

--释放或销毁
function M:Dispose(isDestory)
	euiopen:Remove(self.OnOpenCollectionUI, self)
    --EventMgr.Remove("UIOpen", self.OnOpenCollectionUI)
	self.CTemp = nil			
	self.Wild = nil 		
	self.CollectionPos = nil
	self:Super("Dispose", isDestory)
end
--endregion
