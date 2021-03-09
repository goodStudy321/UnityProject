BossDetal ={Name="BossDetal"}
local My = BossDetal;


function My:Init( go)
    local name = "BossDetal";
	local trans = go.transform;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;
    local FC = TransTool.FindChild;
    local CG = ComTool.Get;
    UC(trans,"hstBtn",name,self.OpenModCam,self);
    self.hstBtn=FC(trans,"hstBtn")
    self.what3Lb =FC(trans,"what3Lb")
    self.IslDetal = FC(trans,"IslDetal");
    local IslDetal = self.IslDetal.transform
    self.BossRwd = TF(trans,"BossRwd",name);
    self.dec=CG(UILabel,IslDetal,"dec")
    self.desj=CG(UILabel,IslDetal,"num");
    PBossRwd:Init(self.BossRwd)
end

--打开记录
function My:OpenModCam( )
    BossHelp:OpenModCam(1)
end

function My:Setdesj(monsId,name,what,num,type)
    PBossRwd:SetRwd(monsId);
    self:whatSet(name,what,num,type);
end

function My:whatSet( name,what,num,type )
    self.what3Lb:SetActive(false)
    if what==1 then
        self:setIsl( name,what,num,type)
        self.hstBtn:SetActive(false)
    elseif what==2 then
        self:setIsl( name,what,num,type)
        self.hstBtn:SetActive(false)
    elseif what==3 then
        self.what3Lb:SetActive(true) 
        self.hstBtn:SetActive(false)
        self.IslDetal:SetActive(false)
    else
        self.IslDetal:SetActive(false)
        self.hstBtn:SetActive(true)
    end
end

function My:setIsl( name,what,num,type)
    self.IslDetal:SetActive(true)  
    local str = "";
    local active = false
    if type==7 then
       what=what+10;
       active=true
    end
    str=InvestDesCfg[tostring(1200+what)].des;
    self.desj.text=string.format( "[F4DDBDFF]剩余%s数量：[-][00FF00FF]%s[-]",name,num) ;      
    self.dec.text=str;
end

function My:Clear( )
 
end