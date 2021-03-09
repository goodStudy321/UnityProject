bKillRcd=Super:New{Name="bKillRcd"}
local My = bKillRcd;
--info信息
My.infoLst={};

function My:Init(root)
    local CG = ComTool.Get;
    self.root=root;
    self.root.gameObject:SetActive(true);
    local TF = TransTool.Find;
    UITool.SetLsnrClick(root,"close",self.name,self.Close,self);
    UITool.SetLsnrClick(root,"lock",self.name,self.Close,self);
    
    for i=1,5 do
        local path = string.format("info/rcd%s",i);
        My.infoLst[i]=TF(root,path);
        self:Factory(CG,My.infoLst[i],"",nil)
    end
    self:lsnr("Add");
    --请求数据
    NetBoss:islKillTos(BossHelp.SelectId)
end

function My:lsnr(fun)
    NetBoss.eKillRcd[fun](NetBoss.eKillRcd,self.Show,self);
end

function My:Show( )
    local CG = ComTool.Get;
    local NISL = NetBoss.islKillLst;
    for i=1,5 do
        local info = NISL[i];
        if info==nil then
            self:Factory(CG,self.infoLst[i],"",nil);
        else
            self:Factory(CG,self.infoLst[i],info.role_name,info.kill_time);
        end
    end
end

function My:Factory(CG,root,name,time)
    if  LuaTool.IsNull(root) then
        return ;
       end
    local nametxt = CG(UILabel,root,"name");
    local timetxt = CG(UILabel,root,"time");
    nametxt.text=name;
    if time==nil then
        timetxt.text="";
    else
        local time1 = DateTool.GetDate(time):ToString("HH:mm:ss");
        timetxt.text=time1;
    end
end

function My:Close( )
    BossHelp:CloseModCam()
end
function My:Clear()
   if  LuaTool.IsNull(self.root) then
    return ;
   end
   self.root.gameObject:SetActive(false);
   TableTool.ClearUserData(self);
end
return My;