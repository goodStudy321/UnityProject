
local GameObject = UnityEngine.GameObject

UIBuff = {}
local M = UIBuff

function M:New(go)
	local transform = go.transform;
	local name = "buff界面";
	
	--self.UIGrid = ComTool.Get(UIGrid,transform,"Container",name,false);
	self.UIGrid = go:GetComponent("UIGrid")
	self.BuffItem = TransTool.FindChild(transform, "BuffItem");
	self.BuffItem:SetActive(false);

	self.SKills = {}
	return self
end

function M:AddBuff(buffId,iconName)
	--[[
	local path = "Container/" .. buffId;
	local grid = self.UIGrid
	if LuaTool.IsNull(grid) == false then
		local buff = self.UIGrid.transform:Find(tostring(buffId));
		if(buff == nil) then
			buff = GameObject.Instantiate(self.BuffItem);
			buff:SetActive(true);
			buff.name = tostring(buffId);
			local trans = buff.transform
			trans.parent = self.UIGrid.transform;
			trans.localPosition = Vector3.zero;
			trans.localScale = Vector3.one;
			local iconGameobj = TransTool.FindChild(trans,"Icon");
			self:SetIcon(iconGameobj,iconName);
			self.UIGrid.enabled = true;
			self.SKills[tostring(buffId)] = iconName
		end
	end
	]]--
end

function M:SetIcon(iconGameobj,iconName)
	
	--[[
	local del = ObjPool.Get(Del1Arg)
	del:SetFunc(self.SetTex, self)
	del:Add(icon)
	AssetMgr:Load(iconName,ObjHandler(del.Execute,del))
	]]--
end

function M:SetTex(tex,icon)
	if icon then
		icon.mainTexture = tex
	end
end

function M:SetCD(buffId,cdTime)
	--[[
	local path = "Container/" .. buffId;
	local buff = self.UIGrid.transform:Find(tostring(buffId));
	if(buff == nil) then return end
	local cdSprite = ComTool.Get(UISprite,buff,"CD",name,false);
	cdSprite.fillAmount = cdTime;
	]]--
end

function M:DelBuff(buffId)
	--[[
	local path = "Container/" .. buffId;
	local buff = self.UIGrid.transform:Find(tostring(buffId));
	if(buff == nil) then return end
	GameObject.Destroy(buff.gameObject);
	self.SKills[tostring(buffId)] = nil
	table.remove(self.SKills, tostring(buffId))
	]]--
end

function M:Open()
	--[[
	if not self.SKills then return end
	for k,v in pairs(self.SKills) do
		local buff = self.UIGrid.transform:Find(k);
		if(buff ~= nil) then
			local iconGameobj = TransTool.FindChild(buff.transform,"Icon");
			self:SetIcon(iconGameobj,v);
		end
	end
	]]--
end

return M