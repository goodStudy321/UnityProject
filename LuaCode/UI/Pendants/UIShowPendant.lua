--region UIShowPendant.lua
--控制面板
require("Tool/LuaTool")

local Event = EventMgr
local time = UnityEngine.Time
local Animation = UnityEngine.Animation
local GameObject = UnityEngine.GameObject

UIShowPendant = UIBase:New{Name = "UIShowPendant"}
local M = UIShowPendant

function M:InitCustom()
	local name = "lua挂件"
	local trans = self.root;
	local C = ComTool.Get
	local TF = TransTool.FindChild;
	self.PendantRoot = TF(trans, "PendantRoot");
	self.CloseG = TF(trans,"CloseBtn");
	self.OnShowItem = EventHandler(self.ShowPendantItem, self)
	self.Icon = C(UITexture, trans, "Icon", name, false)
	self:InitPdtNG(trans);
	self:AddEvent()
end

--初始化挂件名对象
function M:InitPdtNG(trans)
	local TF = TransTool.FindChild;
	self.PdtNameG = {}
	for i = 1,7 do
		local go = TF(trans,tostring(i));
		go:SetActive(false);
		self.PdtNameG[i] = go;
	end
end

--重置名字对象
function M:ResetNGState()
	for i = 1,7 do
		self:SetNGState(i,false);
	end
end

--设置名字对象
function M:SetNGState(index,state)
	local go = self.PdtNameG[index];
	if go == nil then
		return;
	end
	go:SetActive(state);
end

function M:AddEvent()
	Event.Add("ShowItem", self.OnShowItem);
	if self.CloseG then	
		UITool.SetLsnrSelf(self.CloseG, self.Close, self, nil, false)
	end
end

function M:RemoveEvent()
	Event.Remove("ShowItem", self.OnShowItem);
end

--[[
	因触发方式不同，小精灵体验和养成走不同的配置，不同的逻辑处理
--]]

--显示养成UI模型
function M:ShowPendantItem(temp, data)
	self.Temp = temp
	if not temp then 
		self:Close()
	end
	self.sysId = temp.id or 7
	local id = temp.modid or temp[1]
	local showTime = temp.delay or temp[2]
	local baseTemp = RoleBaseTemp[tostring(id)]
	if not baseTemp then self:Close()  return end
	self:PauseHg();
	self:ResetNGState();
	self:SetNGState(self.sysId,true);
	self:UnloadMod()
	TransTool.ClearChildren(self.PendantRoot.transform);
	self.ShowTime = showTime * 0.001;
	self.ModName = baseTemp.path
	Loong.Game.AssetMgr.LoadPrefab(baseTemp.path, GbjHandler(self.SetPendant,self))
	if data == nil or self.sysId == 7 then return end
	if StrTool.IsNullOrEmpty(temp.icon[1]) then return end
	self.LoadName = temp.icon[1]
	local del = ObjPool.Get(DelLoadTex)
	del:Add(data)
	del:SetFunc(self.SetTex, self)
	AssetMgr:Load(self.LoadName,ObjHandler(del.Execute,del))

end

--设置挂件
function M:SetPendant(obj)
	if LuaTool.IsNull(obj) then
		iTrace.eError("HS","加载挂件资源对象为空");
		return;
	end
	self.PendantGameObject = go;
	if self.active ~= 1 then 
		self:UnloadMode()
		return
	 end
	local go = obj
	local trans = obj.transform
	go.transform.parent = self.PendantRoot.transform;
	local pos = Vector3.New(0, 0, 0);
	go.transform.localPosition = pos;
	LayerTool.Set(trans,19)
	go:SetActive(true);
end

--加载设置Icon
function M:SetTex(tex,data)
	if not self.Icon then 
		Destroy(tex)
		self:UnloadIcon()
		return
	end
	self.Icon.mainTexture = tex

	local fly = data.flyType
	if not fly then return end
	local go = self.Icon.gameObject
	local copy = GameObject.Instantiate(self.Icon.gameObject)
	copy.transform.name = tostring(data.Temp.id)
	copy.transform.localPosition = go.transform.position;
	copy.transform.localRotation = go.transform.rotation;
	copy.transform.localScale = go.transform.localScale;
	OpenMgr:ShowFlyEffect(data, copy)
end

function M:UnloadMod()
	if self.PendantGameObject then 
		Destroy(self.PendantGameObject)
		if not StrTool.IsNullOrEmpty(self.ModName) then
			AssetMgr:Unload(self.ModName, ".prefab", false)
		end
	end
	self.ModName = nil
	self.PendantGameObject = nil
end

function M:UnloadIcon()
	if not StrTool.IsNullOrEmpty(self.LoadName) then
		AssetMgr:Unload(self.LoadName, ".png", false)
	end
	self.LoadName = nil
end

function M:CloseCustom()
	self:UnloadMod()
	self:UnloadIcon()
	MountGuide:Open(self.sysId);
	self.sysId = nil;
	 self.renders = nil
	 self.pdtNameG = nil;
	 self:RsmHg();
	TransTool.ClearChildren(self.PendantRoot.transform);
	if self.Temp then
		OpenMgr.eOpen(self.Temp.lvid)
	end
end

--停止挂机
function M:PauseHg()
	Hangup:Pause(self.Name);
end

--恢复挂机
function M:RsmHg()
	--self:Close();
	Hangup:Resume(self.Name);
end

function M:Update()
	if self.ShowTime == nil then
		return;
	end
	if self.ShowTime > 0 then
		self.ShowTime = self.ShowTime - time.deltaTime;
	else
		self:Close();
		--UIMgr.OpenRecords(self.Name);
	end
end

return M

--endregion
