bigRCD=Super:New{Name="bigRCD"};
local My = bigRCD;

function My:show(go,info)
    local tip = self.Name;
    local CG = ComTool.Get;
    local TF = TransTool.Find;
    local root = go.transform;
    self.go = go
    self.grid=TF(root,"Grid",tip);
    self.time=CG(UILabel,root,"time",tip);
    self.name=CG(UILabel,root,"name",tip);
    --做显示
    self.cell=soonTool.AddOneCell(self.grid,info.reward,1,1);
    self.name.text=info.name;
    self.time.text=DateTool.GetDate(info.time):ToString("yyyy.MM.dd HH:mm");
end

function My:Dispose()
    self:Clear()
    soonTool.desOneCell(self.cell);
end

function My:Clear(  )
    -- self:Dispose();
    Destroy(self.go)
    TableTool.ClearUserData(self);
end

return My;