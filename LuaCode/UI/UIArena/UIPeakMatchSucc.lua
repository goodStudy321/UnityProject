UIPeakMatchSucc = {Name= "UIPeakMatchSucc"}
local My = UIPeakMatchSucc;

function My:Open(go)
    go:SetActive(true);
    self.root = go;
    local root = go.transform;
    local name = go.name;
    local CG = ComTool.Get;
    self.TimeLbl = CG(UILabel,root,"TimeCount",name,false);
    self.TimeLbl.text = "3秒";
    self:Init();
end

function My:Init()
    self.Timer = ObjPool.Get(iTimer)
    self.Timer.seconds = 3;
	self.Timer.invlCb:Add(self.InvCountDown, self)
    self.Timer.complete:Add(self.EndCountDown, self)
    self.Timer:Start();
end

function My:InvCountDown()
    if self.Timer == nil then
        return;
    end
    local time = self.Timer:GetRestTime();
    time = math.floor(time + 0.5);
    self.TimeLbl.text = string.format("%d秒",time);
end

function My:EndCountDown()
    UIPeakMatch:Close();
    self:Close();
    SceneMgr:ReqPreEnter(30002, true, true)
end

function My:Close()
    self.Timer:AutoToPool();
    self.Timer = nil;
    self.root:SetActive(false);
    self.root = nil;
    self.TimeLbl = nil;
end