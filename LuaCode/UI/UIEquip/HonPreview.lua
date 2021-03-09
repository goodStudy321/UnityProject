HonPreview = { Name = "HonPreview"}
local My = HonPreview;
--装备部位
My.equipPart = nil;

function My:Init(go)
    self.root = go;
    local trans = go.transform;
    self:SetUIState(false);

	local CG = ComTool.Get;
    local TF=TransTool.FindChild;
    local UC = UITool.SetLsnrClick;

    self.InfoTitle = CG(UILabel,trans,"InfoTitle",false);
    self.GemRoot = TF(trans,"GemRoot",self.Name);
    self.AddAttr = TF(trans,"AddAttr",self.Name);
    self.AddAttr:SetActive(false);
    self.AddAtTbl = CG(UITable,trans,"AddAttrTbl",false);

    UC(trans,"UICollider",self.Name,self.Close,self);
end

--开启面板
function My:Open()
    self:SetUIState(true);
    self:SetInfo();
end

--关闭面板
function My:Close(go)
    self:SetUIState(false);
    self:Clear();
end

--设置信息
function My:SetInfo()
    local gemInfo = My.GetHgtGemInfo();
    if gemInfo == nil then
        return;
    end
    self:SetTitleCol(gemInfo.type);
    self:SetGem(gemInfo.id);
    self:SetHonInfo(gemInfo.type);
end

--设置标题颜色
function My:SetTitleCol(gemType)
    local ifTtl = self.InfoTitle;
    if ifTtl == nil then
        return;
    end
    if gemType == GemType.HP then
        ifTtl.color = Color.green;
    elseif gemType == GemType.Attack then
        ifTtl.color = Color.red;
    end
end

--设置宝石
function My:SetGem(gemId)
    local trans = self.GemRoot.transform;
    self.cell = ObjPool.Get(UIItemCell);
    self.cell:InitLoadPool(trans);
    self.cell:UpData(gemId);
end

--获取最高宝石信息
function My.GetHgtGemInfo()
    if My.equipPart == nil then
        return nil;
    end
    local gemLV = 0;
    local gemInfo = nil;
    for k,v in pairs(GemData) do
        local parts = v.parts;
        for idx,part in ipairs(parts) do
            part = tostring(part);
            if part == My.equipPart then
                local lv = v.lv;
                if gemLV < lv then
                    gemInfo = v;
                    gemLV = lv;
                end
            end
        end
    end
    return gemInfo;
end

--设置淬炼添加属性信息
function My:SetHonInfo(gemType)
    if gemType == nil then
        return;
    end
    local honId = gemType * 100 + 1;
    local honInfo = My.GetHonHgt(honId);
    if honInfo == nil then
        return;
    end
    self:SetHonAttr(honInfo);
    self.AddAtTbl:Reposition();
end

--获取最高粹炼度信息
function My.GetHonHgt(honId)
    local nextId = honId + 1;
    local nextId = tostring(honId + 1);
    local nextInfo = HonInfo[nextId];
    if nextInfo == nil then
        local id = tostring(honId);
        local honInfo = HonInfo[id];
        return honInfo;
    end
    return My.GetHonHgt(nextId);
end

--设置淬炼度属性
function My:SetHonAttr(info)
    local honTrans = self.AddAtTbl.transform;
	TransTool.ClearChildren(honTrans);
	if info == nil then
		return;
	end
	if info.gemAddPer ~= nil then
		local attStr = "宝石属性";
		local addVal = info.gemAddPer/100;
		self:SetAttr(honTrans,attStr,addVal);
	end
	for k,v in pairs(info.addAttrs) do
		local attStr = PropTool.GetNameById(v.k);
		local addVal = v.v/100;
		self:SetAttr(honTrans,attStr,addVal);
	end
end

--设置属性
function My:SetAttr(parent,attStr,addVal)
	local CG = ComTool.Get;
	local trans = self:CloneAttr(parent);
	local title = CG(UILabel,trans,"AttrTitle",trans.name);
	local addPer = CG(UILabel,trans,"AttrPer",trans.name);
	title.text = attStr .. "：";
	addPer.text = "+" .. addVal .. "%";
end

--克隆属性对象
function My:CloneAttr(parent)
	local go = GameObject.Instantiate(self.AddAttr);
	go:SetActive(true);
	local trans = go.transform;
	trans.parent = parent;
	trans.localPosition = Vector3.zero;
	trans.localScale = Vector3.one;
	return trans;
end


--设置对象状态
function My:SetUIState(active)
    local isNull = LuaTool.IsNull(self.root);
    if isNull == true then
        return;
    end
    self.root:SetActive(active);
end

--销毁宝石
function My:DestroyGem()
    if self.cell == nil then
        return;
    end
    self.cell:DestroyGo();
    ObjPool.Add(self.cell);
    self.cell = nil;
end

function My:Clear()
    self:DestroyGem();
end

function My:Dispose()
    self:Clear();
end