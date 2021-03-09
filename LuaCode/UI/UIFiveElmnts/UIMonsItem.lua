UIMonsItem = Super:New{Name = "UIMonsItem"}
local My = UIMonsItem;

--设置信息
function My:SetInfo(go,bossInfo)
    local trans = go.transform;
    self.trans = trans;
    local name = trans.name;
    local CG = ComTool.Get;
    local TF = TransTool.Find;
    local UCS = UITool.SetLsnrSelf;

    self.NameLbl = CG(UILabel,trans,"Name",name,false);
    self.LevLbl = CG(UILabel,trans,"Level",name,false);
    self.RfrTime = CG(UILabel,trans,"RfrTime",name,false);
    self.RfrFlag = TF(trans,"RfrFlag",name);
    self.Select = TF(trans,"Select",name);
    self.BossFlag = TF(trans,"BossFlag",name);
    UCS(go,self.Click,self,name,false);

    local monsId = bossInfo.monsId;
    self.monsId = monsId;
    self:SetGoName(go);
    self:SetName(bossInfo.name);
    self:SetLevel(bossInfo.level);
    self:SetBossFlag(bossInfo.isBoss);
    self:SetRfr(bossInfo);
    self:SetLsnr(monsId,true);
    self:SetSelect(false);
end

--设置条目对象名
function My:SetGoName(go)
    if go == nil then
        return;
    end
    monsId = tostring(self.monsId);
    go.name = monsId;
end

--设置名字
function My:SetName(name)
    if self.NameLbl == nil then
        return;
    end

    self.NameLbl.text = name;
end

--设置等级
function My:SetLevel(level)
    if self.LevLbl == nil then
        return;
    end
    level = string.format( "%d级",level);
    self.LevLbl.text = level;
end

--设置刷新
function My:SetRfr(bossInfo)
    if bossInfo.isBoss == false then
        self:SetRfrFlag(false);
        self:SetRfrTimeFlag(false);
        return;
    end
    local isRfr = bossInfo.isRefresh;
    local remain = bossInfo:GetRemain();
    self:SetRfrFlag(isRfr);
    self:SetRfrTimeFlag(not isRfr);
    self:SetRfrTime(remain);
end

--设置刷新标识
function My:SetRfrFlag(isRfr)
    local rFrTrans = self.RfrFlag;
    local isNull = LuaTool.IsNull(rFrTrans);
    if isNull == true then
        return;
    end
    local go = rFrTrans.gameObject;
    if go.activeSelf == isRfr then
        return;
    end
    go:SetActive(isRfr);
end

--设置刷新时间标识
function My:SetRfrTimeFlag(active)
    local rFrLbl = self.RfrTime;
    local isNull = LuaTool.IsNull(rFrLbl);
    if isNull == true then
        return;
    end
    local go = rFrLbl.gameObject;
    if go.activeSelf == active then
        return;
    end
    go:SetActive(active);
end

--设置刷新时间
function My:SetRfrTime(remain)
    local rFrLbl = self.RfrTime;
    local isNull = LuaTool.IsNull(rFrLbl);
    if isNull == true then
        return;
    end
    rFrLbl.text = remain;
end

--设置boss标识
function My:SetBossFlag(isBoss)
    local trans = self.BossFlag;
    local isNull = LuaTool.IsNull(trans);
    if isNull == true then
        return;
    end
    local go = trans.gameObject;
    go:SetActive(isBoss);
end

--计时器间隔回调
function My:TimerInvl(remain)
    self:SetRfrFlag(false);
    self:SetRfrTimeFlag(true);
    self:SetRfrTime(remain);
end

--设置计时结束
function My:SetTimerEnd()
    self:SetRfrFlag(true);
    self:SetRfrTimeFlag(false);
end

--设置监听
function My:SetLsnr(monsId,add)
    self:SetInvlLsnr(monsId,add);
    self:SetEndLsnr(monsId,add);
end

--设置隔间监听
function My:SetInvlLsnr(monsId,add)
    local copyId = User.SceneId;
    local mgr = FiveElmtMgr;
    mgr.AddDelInvlCb(copyId,monsId,self.TimerInvl,self,add);
end

--设置结束监听
function My:SetEndLsnr(monsId,add)
    local copyId = User.SceneId;
    local mgr = FiveElmtMgr;
    mgr.AddDelEndCb(copyId,monsId,self.SetTimerEnd,self,add);
end

--点击
function My:Click(go)
    local monsId = go.name;
    UIFiveElmntAttr.SelectItem(self);
    UIFiveElmntView:Open(monsId);
end

--设置选择
function My:SetSelect(active)
    local select = self.Select;
    local isNull = LuaTool.IsNull(select);
    if isNull == true then
        return;
    end
    local go = select.gameObject;
    go:SetActive(active);
end

--释放
function My:Dispose()
    self:SetLsnr(self.monsId,false);
    self.monsId = nil;
    if self.trans ~= nil then
        Destory(self.trans.gameObject);
        self.trans = nil;
    end
end