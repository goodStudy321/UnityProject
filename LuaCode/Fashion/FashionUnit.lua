FashionUnit = Super:New{Name="FashionUnit"}
local My = FashionUnit;

--设置时间
function My:SetTimer(endTime)
    local time = FashionHelper.GetFashionTime(endTime);
    if time <= 0 then
        if self.timer ~= nil then
            self.AutoToPool();
        end
        return;
    end
    if self.timer == nil then
        self.timer = FashionHelper.GetFashionTimer(endTime);
        self.timer.complete:Add(self.TimeComplete,self);
    end
    self.timer:Stop();
    self.timer.seconds = time;
    self.timer:Start();
end

--计时完成
function My:TimeComplete()
    if self.timer == nil then
        return;
    end
    self.timer:AutoToPool();
    self.timer = nil;
end

--强制计时完成
function My:ForceTCCmplt()
    
end

function My:Clear()
    self.baseId = 0   --时装基础id
    self.uid = 0  --道具Id
    self.curId = 0   --当前ID
    self.name = "";
    self.type = 0   --时装类型
    self.isLimitTime = false;     --是否限时时装
    self.isActive = false    --是否激活
    self.isUse = false  --是否使用
    self.worth = 0   --分解可获得精华数量
    self.mIcon = ""; --男图标
    self.wIcon = ""; --女图标
    self:ClearCfg();
end

--清理升星配置
function My:ClearCfg()
    if self.cfg ~= nil then
        ObjPool.Add(self.cfg);
        self.cfg = nil;
    end
    if self.nCfg ~= nil then
        ObjPool.Add(self.nCfg);
        self.nCfg = nil;
    end
end

--释放
function My:Dispose()
    self:TimeComplete();
    self:Clear();
end