UIPeakMatch = {Name= "UIPeakMatch"}
local My = UIPeakMatch;

function My:Open(go)
    go:SetActive(true);
    self.root = go;
    local root = go.transform;
    local name = go.name;
    local CG = ComTool.Get;
    local UC = UITool.SetLsnrClick;
    self.TimeLbl = CG(UILabel,root,"TimeCount",name,false);
    self.TimeLbl.text = "0秒";
    UC(root,"CancelBtn",name,self.CancelC,self);
    self:Init();
end

function My:Init()
    self.Timer = ObjPool.Get(AddTimer)
	self.Timer.invlCb:Add(self.InvCountDown, self)
    self.Timer.complete:Add(self.EndCountDown, self)
    self.Timer:Start();
end

--取消匹配
function My:CancelC(go)
    Peak.ReqSoloMatch(0);
    self:Close();
end

function My:InvCountDown()
    if self.Timer == nil then
        return;
    end
    if self.TimeLbl == nil then
        return; 
    end
    self.TimeLbl.text = self.Timer.past;
end

function My:EndCountDown()
    self:CancelC();
end

function My:Close()
    if LuaTool.IsNull(self.root) == true then
        return;
    end
    self.root:SetActive(false);
    self.root = nil;
    if self.Timer == nil then
        return;
    end
    self.Timer:Stop();
    ObjPool.Add(self.Timer);
    self.Timer = nil;
end