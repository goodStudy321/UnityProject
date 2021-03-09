NewBlgTip = {Name = "NewBlgTip"}
local My = NewBlgTip;

function My:Init(trans)
    local name = trans.name;
    local TF = TransTool.Find;
    local CG = ComTool.Get;

    self.NewBlgTip = TF(trans,"NewBlgTip",name);
    self.TipLbl = CG(UILabel,trans,"NewBlgTip/Tip",name);
    self:SetTipState(false);
end

--设置击败提示状态
function My:SetTipState(active)
    local tipGo = self.NewBlgTip;
    if LuaTool.IsNull(tipGo) == true then
        return;
    end
    tipGo.gameObject:SetActive(active);
end

--隐藏提示
function My:HideTip()
    self:SetTipState(false);
end

--设置提示
function My:SetTip(beKilled,newBlg)
    local msg = string.format("[00ff00]%s[-]击败[ff2c2c]%s[-],成为新的归属者",newBlg, beKilled);
    self.TipLbl.text = msg;
    self:SetTipState(true);
    self:StartTimer();
end

--开始计时
function My:StartTimer()
    if self.actTimer == nil then
        self.actTimer = ObjPool.Get(iTimer);
        self.actTimer.complete:Add(self.HideTip,self);
    end
    if self.actTimer.running then
        self.actTimer:Stop();
    end
    self.actTimer.seconds = 3;
    self.actTimer:Start();
end