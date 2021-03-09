
require("UI/UIBoss/BossCopyItem")
BossCopyLst=Super:New{Name="BossCopyLst"}
local My=BossCopyLst;

My.trueId = 1
function My:Init( go )
    self.root = go
    local trans = self.root;
    local CG = ComTool.Get;
    local TFC = TransTool.FindChild;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;
    local UCS = UITool.SetLsnrSelf;
    local svRoot = TF(trans,"Info/sv",name);
    self.svRooot=svRoot;
    self.sv=svRoot.gameObject;
    self.sv1 = TFC(svRoot,"1",name);
    self.UITable = CG(UITable,svRoot,"1/ScrollView1/Table",name,false);
    self.sv1:SetActive(true);
    self.sv2 = TFC(svRoot,"2",name);
    self.sv2:SetActive(false);
    self.sv3 = TFC(svRoot,"3",name);
    self.sv3:SetActive(false);
    self.tip1=TFC(trans,"Info/bg/tip1",name);
    self.tip2=TFC(trans,"Info/bg/tip2",name)
    self.tip1:SetActive(true);
    self.tip2:SetActive(false);
    self.hittg =TFC(trans,"Info/bg/mosBtn",name);
    self.hittg:SetActive(false);
    self.hit=TFC(trans,"Info/hit",name);
    self.hit:SetActive(false);
    self.BossItem = TFC(svRoot,"1/ScrollView1/Table/BossItem",name);
    soonTool.setPerfab(self.BossItem,"BossItem")
    self.objLst ={}
    self:doItem()
    self:Lsnr( "Add" )
end

function My:Lsnr( fun )
    CopyMgr.eCopyState[fun](CopyMgr.eCopyState,self.BossKill,self)
end

function My:BossKill( state )
    if state==1 then
        self.objLst[My.trueId]:SetReTime()
        NetBoss:PleaseGoOut()
    end
end

function My:doItem(  )
    for i=1,#tBossCopy do
        local obj = ObjPool.Get(BossCopyItem)
        obj:setInfo(tBossCopy[i])
        table.insert( self.objLst,obj )
    end
    self.UITable.repositionNow = true;
end

function My:clear( )
    if self.root~=nil then
       soonTool.ObjAddList(self.objLst)
       self:Lsnr( "Remove" )
    end
end