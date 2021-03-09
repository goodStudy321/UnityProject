--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetPathfinding = baseclass(MissionTarget)
local M = MissionTargetPathfinding
local MNW = MissionNetwork
local Error = iTrace.Error
--构造函数
function M:Ctor()
	self.Pos = nil
	self.TPos = nil
	self.Effect = nil
	self.Cs = nil
end

function M:Init()
	self.EffectName = "FX_EndPoint"
	MissionMgr.eNavPathEvent:Add(self.NavPathEvent,self)
end

--更新目标数据
function M:UpdateTarData(tar)
	local x = tar[1]
	local y = 200000
	local z = tar[2]
	self.Pos = Vector3.New(x * 0.01, y * 0.01, z * 0.01)
	self.TID = x
	if self.TID  < 0 then self.TID  = self.TID * -1 end
	self.SID = tar[3]
	self.LNum = 1
	self:Super("UpdateTarData", tar)
	self:UpdateEffect()
	--self:SetRayHitPosition(self.Pos)
end

--执行任务目标
function M:AutoExecuteAction(fly, execute)
	self.Execute = execute
	local isHg = Hangup:GetAutoHangup();
	if isHg == false then
		return;
	end
	self:UpdateEffect()
	if not self.Pos or not self.SID then return end

	local desPos = Vector3.New(self.Pos.x,0,self.Pos.z);
	local scrPos = Vector3.New(User.Pos.x,0,User.Pos.z);
	local dis = Vector3.Distance(scrPos, desPos);
	if dis < 0.4 then
		self:CustomNPComplete();
		return;
	end
	
	--iTrace.sLog("hs","----------------> ".. tostring(User.Pos).."/" ..tostring(self.Pos))
	self:NavPath(self.Pos, self.SID, 0, 0, fly)
end

--自定义寻路完成
function M:CustomNPComplete()
	if self.SID ~= User.SceneId then
		return
	end
	self:UnloadEffect()
	
    MNW:ReqTriggerMission(self.Temp.tarType, self.TID)
end

function M:UpdateEffect()
	if not self.Effect then
		if self.Pos then
			self:SetRayHitPosition(self.Pos)
		end
	end
end

function M:SetRayHitPosition(pos)
	local ray = Ray.New(Vector3.down, pos)
    local layer = 2 ^ LayerMask.NameToLayer('Ground')
    local flag, hit = UnityEngine.Physics.Raycast(ray, nil, 5000, layer)             
    if not flag then
   	 	layer = 2 ^ LayerMask.NameToLayer('ShadowCaster')
    	flag, hit = UnityEngine.Physics.Raycast(ray, nil, 5000, layer)        
   	end   
    --local flag, hit = UnityEngine.Physics.Raycast(ray, RaycastHit.out, 5000, layer)
    if flag or hit then
        self.TPos = hit.point
        self:LoadEffect()
    end
end

function M:LoadEffect()
	if not self.EffectName then return end
	if self.Effect then
		if self.Effect.name == self.EffectName then
			return
		end
	end
	Loong.Game.AssetMgr.LoadPrefab(self.EffectName, GbjHandler(self.LoadEffectCb, self))
end

function M:LoadEffectCb(go)
	self.Effect = go
	self.Cs = ComTool.Add(go, EndPoint)
	self.Effect.transform.localEulerAngles = Vector3.zero
	self.Effect.transform.localPosition = self.TPos
    self.Effect:SetActive(true);
end

function M:ChangeEndEvent(isLoad)
	if not LuaTool.IsNull(self.Effect) then
		self:UnloadEffect()
	end
	self.Effect = nil
	if User.SceneId ~= self.SID then 	
		return 
	end
	if self.Pos then
		self:SetRayHitPosition(self.Pos)
	end
end

--任务描述
function M:TargetDes()
	local des = "位置"
	if self.TPos then
        local targetName = string.format("(%s,%s)", self.TPos.x, self.TPos.y)
        if StrTool.IsNullOrEmpty(targetName) == false then 
        	targetName = "[%s]" .. targetName .. "[-]"
        	des = string.format("移动到%s(%s/%s)", targetName, mNum, mLimitNum);
       	end
	end
	return des
end

function M:UnloadEffect()
	if self.Effect then
		if self.Effect.name == nil then return end
		if GbjPool:Exist(self.Effect.name) then
			GameObject.Destroy(self.Effect)		
			AssetMgr:Unload(self.EffectName,".prefab", false)
		else
			if self.Cs then
				Destroy(self.Cs)
				self.Cs = nil
			end
			GbjPool:Add(self.Effect)
		end
		self.Effect = nil
	end
end

function M:NavPathEvent()
	self:CustomNPComplete()
end

--释放或销毁
function M:Dispose(isDestory)	
	self:UnloadEffect()
	MissionMgr.eNavPathEvent:Remove(self.NavPathEvent,self)
	self.Pos = nil
	self.Cs = nil
	self:Super("Dispose", isDestory)
end
--endregion
