require("UI/UIBoss/RecordItem")
DropRecord ={Name = "DropRecord"}

local My = DropRecord;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end
My.RcdItems = {}
My.RcdItems2 = {}
function My:UpBRcd(num)
    local tb = self.UITable
    local  name="boosRcd1"
    local list = WBossRecord.WBRcdInfos
    local itemLst = My.RcdItems
    if num==2 then
         tb = self.UITable2
         name="boosRcd2"
         list = WBossRecord.smRcdInfos
         itemLst = My.RcdItems2
    end
    for i=1,#list do
        local obj = ObjPool.Get(RecordItem)
        local go = soonTool.Get(name)
        obj:Init(go,num,name)
        obj:SetContext(list[i])
        itemLst[i] =obj
    end
    if tb~=nil then
        self.UITable:Reposition();
        self.UITable2:Reposition();
    end
end

function My:Open(go)
    local name = go.name;
    local CG = ComTool.Get;
    local TFC = TransTool.FindChild;
    self.UITable = CG(UITable,go,"big/Table",name,false);
    self.RcdItem = TFC(go,"big/Table/DropItem",false);
    self.UITable2 = CG(UITable,go,"smal/Table",name,false);
    self.RcdItem2 = TFC(go,"smal/Table/DropItem",false);
    soonTool.setPerfab(self.RcdItem,"boosRcd1")
    soonTool.setPerfab(self.RcdItem2,"boosRcd2")
    WBossRecord.eUpBRcd:Add(self.UpBRcd,self);
    NetBoss:ReqWBLog();
end

function My:Close()
    WBossRecord.eUpBRcd:Remove(self.UpBRcd,self);
    self.UITable = nil;
    WBossRecord:Clear();
    soonTool.ObjAddList(My.RcdItems )
    soonTool.ObjAddList(My.RcdItems2 )
end