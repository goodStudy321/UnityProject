IslDetal ={Name="IslDetal"}
local My = IslDetal;
--当前选中
-- My.what=2;

function My:Init( root)
    self.title=nil;
    self.go=root.gameObject;
    local CG =  ComTool.Get
    self.desj=CG(UILabel,root,"num");
    self.tip=CG(UILabel,root,"TIP");
    self.dec=CG(UILabel,root,"dec")
    self.timlb=CG(UILabel,root,"timelb")
    self.timlb.text=InvestDesCfg["1600"].des
    -- NetBoss.eIslandInfo:Add(self.setnum,self);
end


function My:Setdesj(name,what,num,type)
    self.go:SetActive(true);    
    local str = "";
    local active = false
    if type==7 then
       what=what+10;
       active=true
    end
    self.timlb.gameObject:SetActive(active)
    str=InvestDesCfg[tostring(1200+what)].des;
    self.tip.text=name;
    self.title=name
    self.desj.text=string.format( "[F4DDBDFF]剩余%s数量：[-][00FF00FF]%s[-]",name,num) ;      
    self.dec.text=str;
end

function My:Clear( )
    -- NetBoss.eIslandInfo:Remove(self.setnum,self);
    -- My.what=2;
end