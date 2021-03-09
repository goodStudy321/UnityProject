UIBigRecord=Super:New{Name="UIBigRecord"}
local My = UIBigRecord;
My.bjlst = {};
local bigRCD = require("UI/UICloudBuy/bigRCD");
function My:Init( root )
    local UC = UITool.SetLsnrClick;
    UC(root, "close", self.Name, self.Close, self);
    self.Grid=ComTool.Get(UIGrid,root,"sv/Grid");
    local TF = TransTool.Find;    
    self.bigrcd=TF(root,"sv/Grid/bigrcd").gameObject;
    soonTool.setPerfab(self.bigrcd,"bigrcd");
    self:doshow()
end

function My:doshow( )
    ListTool.ClearToPool(My.bjlst)
    local cbl = CloudBuyMgr.bigBuyInfo;
    for i=1,#cbl do
        if cbl[i].type == 1 then
            local go =soonTool.Get("bigrcd");
            local obj = ObjPool.Get(bigRCD);
            table.insert(My.bjlst, obj)
            obj:show(go, cbl[i])
            obj.go.name=100+i;
        end
    end
    self.Grid:Reposition();
    
end

function My:Close( )
    UICloudBuy:OpenBigRecord(false);
    self:Clear();
end

function My:Clear()
    ListTool.ClearToPool(My.bjlst)
    TableTool.ClearUserData(self);
end

return My;