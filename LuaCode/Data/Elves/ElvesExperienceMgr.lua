
--[[
    小精灵体验时间管理类
--]]
ElvesExperienceMgr = {Name = "ElvesExperienceMgr"}

local My = ElvesExperienceMgr

function My:Init()
    self.id = 40003
    self.MissionId = GlobalTemp["106"].Value2[1]
    self:SetLnsr("Add")
    euiclose:Add(self.CloseUI,self);
end

--设置监听
function My:SetLnsr(func)
    MissionMgr.eCompleteEvent[func](MissionMgr.eCompleteEvent,self.LsnrMssn, self)
    -- PropMgr.eAdd[func](PropMgr.eAdd,self.RespAdd,self)
    -- PropMgr.eUpdate[func](PropMgr.eUpdate,self.RespUpdate,self)
end

--响应任务完成 打开小精灵体验
function My:LsnrMssn(missionId)
    local id = missionId
    if id ~= self.MissionId then
        return
    end
    UIMgr.Open(UIElvesExperience.Name)
end

--响应添加物品 打开小精灵体验
function My:RespAdd(tb,action)
    local id = tb.type_id
    if id ~= self.id then
        return
    end
    if action == 10101 then
        return
    end
    UIMgr.Open(UIElvesExperience.Name)
end

--响应背包更新
function My:RespUpdate()
    -- local num = PropMgr.TypeIdByNum(self.id)
    -- if num < 1 then
    --     return
    -- end
    -- UIMgr.Open(UIElvesExperience.Name)


    -- local now= TimeTool.GetServerTimeNow()*0.001
    -- local lerp= propData.endTime - now
    -- if lerp >= 0 then
    -- end
end

--关闭UI
function My:CloseUI(uiName)
    local cfg = UICfg[uiName];
    if cfg == nil then
        return;
    end
   if uiName == UIElvesExperience.Name then
    self:OpenUIShowPendant()
   end
end

function My:OpenUIShowPendant()
	UIMgr.Open(UIShowPendant.Name, self.OpenModCb, self)
end

function My:OpenModCb(name)
	local temp = GlobalTemp["109"].Value2
	if not temp then return end
	local ui = UIMgr.Get(name)
	if ui then
		ui:ShowPendantItem(temp)
	end
end

--清理缓存
function My:Clear()

end

--释放资源
function My:Dispose()
    self:SetLnsr("Remove")
    euiclose:Remove(self.CloseUI,self);
end

return My