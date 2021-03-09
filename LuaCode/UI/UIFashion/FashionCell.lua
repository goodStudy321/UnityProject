FashionCell = Super:New{Name = "FashionCell"}

local M = FashionCell

function M:Ctor()
    self.texList = {}
end

function M:Init(go)
    local FG = TransTool.FindChild
    local G = ComTool.Get
    local trans = go.transform
    self.go = go
    self.bg = FG(trans, "bg")
    self.lock = FG(trans, "Lock")
    self.highlight = FG(trans, "Highlight")
    self.redPoint = FG(trans, "RedPoint")
    self.putOn = FG(trans, "PutOn")
    self.name = G(UILabel, trans, "Name")
    self.endTime = G(UILabel, trans,"EndTime");
    self.icon = G(UITexture, trans, "bg/Icon")
    UITool.SetLsnrSelf(go, self.OnClick, self,nil, false)
    self:SetTimeState(false);
    self:SetActive(true)
end

function M:UpdateCell(data, _type)
    self.data = data
    self._type =  _type
    local cfg = data.cfg
    if not cfg then return end

    self.name.text = cfg.name
    self.putOn:SetActive(data.isUse)
    self.lock:SetActive(not data.isActive)  
    self:SetNorFashionRedP();
    self:SetLimtFashionRedP();
    self:SetGray(not data.isActive) 
    
    local temp = FashionCfg[tostring(data.baseId)]
    if not temp then return end
    local icon = User.MapData.Sex==1 and temp.mIcon or temp.wIcon
    AssetMgr:Load(icon, ObjHandler(self.SetIcon, self))
    self:UpdateTime();
end

--设置正常时装红点
function M:SetNorFashionRedP()
    local data = self.data;
    if data.isLimitTime == true then
        return;
    end
    local nCfg = data.nCfg
    if nCfg then
        local item = data.cfg.comsume[1]
        local num = PropMgr.TypeIdByNum(item.k)
        self:UpdateRedPoint(num>=item.v)
    else
        self:UpdateRedPoint(false)
    end
end

--设置限时时装红点
function M:SetLimtFashionRedP()
    local data = self.data;
    if data.isLimitTime ~= true then
        return;
    end
    if data.isActive == true then
        self:UpdateRedPoint(false);
    else
        local item = data.cfg.comsume[1]
        local num = PropMgr.TypeIdByNum(item.k,nil,true)
        self:UpdateRedPoint(num>=item.v)
    end
end

function M:SetIcon(tex)
    if self.data then
        self.icon.mainTexture = tex
        if self._type == 3  then
            self.icon:SetDimensions(64,64) 
        else
            self.icon:SetDimensions(128,128) 
        end
        table.insert(self.texList, tex.name)
    else
        AssetTool.UnloadTex(tex.name)
    end
end

function M:UpdateRedPoint(bool)
    self.redPoint:SetActive(bool)
end

function M:SetGray(isGray) 
    if isGray then
        UITool.SetAllGray(self.bg)
    else
        UITool.SetAllNormal(self.bg)
    end
end

function M:OnClick()
    if not self.data  then return end
    self.func(self.handler, self.data.baseId)  
    FashionMgr:TryGetSkin(self.data.curId)
end

function M:SetHandler(func, handler)
    self.func = func
    self.handler = handler
end

function M:SetHighlight(bool)
    self.highlight:SetActive(bool)
end

function M:SetActive(bool)
    self.go:SetActive(bool or false)
end

function M:ActiveSelf()
    return self.go.activeSelf
end

--设置时间文本对象显示状态
function M:SetTimeState(active)
    local atSelf = self.endTime.gameObject.activeSelf;
    if active == atSelf then
        return;
    end
    self.endTime.gameObject:SetActive(active);
end

--设置时间
function M:SetTime()
    if self.data == nil then
        return;
    end
    local timer = self.data.timer;
    if timer == nil then
        return;
    end
    self.endTime.text = timer.remain;
end

--计时到时间
function M:TimeOut()
    if self.data == nil then
        return;
    end
    self:SetTimeState(false);
end

function M:UpdateTime()
    local timer = self.data.timer;
    if timer == nil then
        self:SetTimeState(false);
        return;
    end
    if self.isInitTime == nil then
        self.isInitTime = true;
        timer.invlCb:Add(self.SetTime,self);
        timer.complete:Add(self.TimeOut,self);
    end
    self:SetTime();
    self:SetTimeState(true);
end

function M:ClearLsnr()
    local data = self.data;
    if data == nil then
        return;
    end
    local timer = data.timer;
    if timer == nil then
        return;
    end
    timer.invlCb:Remove(self.SetTime,self);
    timer.complete:Remove(self.TimeOut,self);
end

function M:Dispose()
    AssetTool.UnloadTex(self.texList)
    TableTool.ClearUserData(self)
    self:ClearLsnr();
    self.func = nil
    self.handler = nil
    self.data = nil
    self._type = nil
    self.isInitTime = nil;
end

return M