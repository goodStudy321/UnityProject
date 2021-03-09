OffLHead = { Name = "OffLHead"}
local My = OffLHead;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

--初始化UI
function My:InitUIInfo(go)
    self.root = go;
    local trans = go.transform;
    local name = go.name;
    local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;

    self.Icon = CG(UITexture,trans,"Icon",name,false);
    self.Level = CG(UILabel,trans,"Level",name,false);
    self.mName = CG(UILabel,trans,"Name",name,false);
    self.Sld = CG(UISlider,trans,"HPSlider",name,false);
    self.SldHp = CG(UILabel,trans,"HPSlider/HpRateLab",name,false);
    self.Fight = CG(UILabel,trans,"Fighting",name,false);
    self.Sld.value = 1;
end

--初始化数据
function My:RefreshUI(item)
    if self.root == nil then
        return;
    end
    self.roleId = item.roleId;
    self.maxHp = item.maxHp;
    self:SetHeadIcon(item.ctgry);
    self.mName.text = item.name;
    self.Level.text = tostring(item.level);
    self.SldHp.text = string.format( "%s/%s",item.maxHp,item.maxHp);
    self:SetFightVal(item.fightVal);
end

--设置战力
function My:SetFightVal(fValue)
    if self.Fight == nil then
        return;
    end
    self.Fight.text = tostring(fValue);
end

--刷新血量
function My:RefreshHp(curHp)
    if self.SldHp == nil then
        return;
    end
    self.SldHp.text = string.format("%s/%s",curHp,self.maxHp);
    local hp = math.LongToNum(curHp);
    local maxHp = math.LongToNum(self.maxHp);
    self.Sld.value = hp/maxHp;
end

function My:SetHeadIcon(category)
    local path = string.format( "head%s.png", category)
    self.headName = path;
	AssetMgr:Load(path,ObjHandler(self.LoadDone, self))
end

--加载完成
function My:LoadDone(texture)
    if self.Icon == nil then
        return;
    end
	self.Icon.mainTexture = texture;
end

--卸载纹理
function My:UnloadTex()
    if self.headName ~= nil then
        AssetMgr:Unload(self.headName,".png",false);
        self.headName = nil;
    end
end

function My:Clear()
    self:UnloadTex();
    TableTool.ClearUserData(self);
end

function My:Dispose()
    self:Clear();
end