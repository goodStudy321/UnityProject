DropEffInfo = Super:New{Name = "DropEffInfo"}
local My = DropEffInfo;

--设置信息
function My:SetData(dropId,pos,tarPos)
    self.dropId = dropId;
    self.pos = pos;
    self.tarPos = tarPos;
    self.go = nil;
    self.curTime = 0;
    self:SetPos();
    self:SetMoveTime(tarPos);
end

--设置移动需要的总时间
function My:SetMoveTime(tarPos)
    local dis = Vector3.Distance(self.pos,tarPos);
    self.moveTime = dis/2;
    if self.moveTime == 0 then
        self.moveTime = 0.1;
    end
end

--设置位置
function My:SetPos()
    local pos = self.pos;
    local cam = SecretDropEff.MainCam;
    pos = cam:WorldToScreenPoint(pos);
    cam = UIMgr.Cam;
    self.pos = cam:ScreenToWorldPoint(pos);
    self.pos.z = 0;
end

--加载完成回调
function My:LoadCb(go)
    local trans = go.transform;
    trans.position = self.pos;
    trans.localScale = Vector3.one;
    self.go = go;
end

--更新
function My:Update()
    return self:UpdatePos();
end

--更新位置
function My:UpdatePos()
    local eff = self.go;
    local isNull = LuaTool.IsNull(eff);
    if isNull == true then
        return;
    end
    self.curTime = self.curTime + Time.deltaTime * 2;
    local radio = self.curTime/self.moveTime;
    local trans = eff.transform;
    trans.position = self:GetPos(radio);
    return self.curTime > 1;
end

--获取当前位置
function My:GetPos(radio)
    radio = Mathf.Clamp01(radio);
    local pos = self.pos;
    local tarPos = self.tarPos;
    local curPos = pos + (tarPos - pos) * radio;
    return curPos;
end

function My:DestroyGo()
    local isNull = LuaTool.IsNull(self.go);
    if isNull == true then
        return;
    end
    local name = self.go.name;
    Destory(self.go);
    AssetMgr:Unload(name..".prefab");
end

function My:Dispose()
    self.dropId = nil;
    self.pos = nil;
    self.tarPos = nil;
    self.curTime = nil;
    self.moveTime = nil;
    self.go = nil;
end