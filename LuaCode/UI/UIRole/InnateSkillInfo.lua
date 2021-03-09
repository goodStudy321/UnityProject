InnateSkillInfo={Name="InnateSkillInfo"}
local My = InnateSkillInfo
local SLT= SkillLvTemp
local TIS = tInnateSys

function My:Init( root  )
    local TF = TransTool.Find;
    local TFC = TransTool.FindChild;
    local CG = ComTool.Get;
    self.root=root
    self.go=root.gameObject
    self.nowDec =CG(UILabel,root,"nowDec")
    self.nexDec =CG(UILabel,root,"nexDec")
    self.lmtDec =CG(UILabel,root,"bfsk/dec")
    self.sklName =CG(UILabel,root,"name")
    self.icon=CG(UITexture,root,"di/icon")
    self.curLv=CG(UILabel,root,"lv")
    self.ndPoint=CG(UILabel,root,"point")
    self.propDec=CG(UILabel,root,"prop/dec")
    self.UpLvBtn=TFC(root,"Uplv")
    local UC = UITool.SetLsnrClick
    UC(root, "Uplv", name, self.Uplv, self)
    UC(root, "close", name, self.onClose, self,false)
    self:myActive(false)
end

function My:onClose(  )
    self:myActive( b )
end

function My:myActive( b )
    self.go:SetActive(b)
end

--升级按钮
function My:Setbtn( info )
    local lv = info.lv;
    if lv == info.max then
        self.UpLvBtn:SetActive(false);
    else
        self.UpLvBtn:SetActive(true);
    end
    if info.rad and info.changError~="当前页只能选择一个天赋"  then
        UITool.SetNormal(self.UpLvBtn)
    else
        UITool.SetGray(self.UpLvBtn)
    end
end
--点击升级
function My:Uplv( )
    InnateMgr:sendUpLevel( UIInnate.tb,self.info.nextId);
end
function My:Update(info )
    self.info=info;
    local sltInf = SLT[info.skillId]
    self.IconTex = sltInf.icon;
    AssetMgr:Load(self.IconTex,ObjHandler(self.LoadIcon,self));  
    local lv = info.lv
    local max=info.max
    local nextinfo = TIS[info.nextId]
    --限制展示
    local lmtStr="[F4DDBDFF]已满级[-]"
    local lstLmtColor =  InnateMgr.needErrorLst(info )
    if lv~=max and nextinfo~=nil then
        local roleLmt = info.lmLv
        local lmPoint=info.lmPoint
        local p_sb = ObjPool.Get(StrBuffer)
        if info.red then
            p_sb:Apd( "[F4DDBDFF]玩家达到"):Apd(roleLmt):Apd("级\n")
            if nextinfo.lmt~="" then
                local Strname = SLT[info.lmt].name;
                local lmtinfo =  TIS[info.lmt];
                local skilllmtLv = lmtinfo.lv
                p_sb:Apd("需要"):Apd(Strname):Apd("天赋达到"):Apd(skilllmtLv):Apd("级\n")
            end
            if lmPoint~=0 then
                p_sb:Apd("需要投入天赋点总点数达到"):Apd(lmPoint):Apd("点[-]")
            end
        else
            p_sb:Apd( "[F4DDBDFF]"):Apd(lstLmtColor[1].start):Apd("玩家达到"):
            Apd(roleLmt):Apd("级\n"):Apd(lstLmtColor[1].endstr)
            if nextinfo.lmt~="" then
                local Strname = SLT[info.lmt].name;
                local lmtinfo =  TIS[info.lmt];
                local skilllmtLv = lmtinfo.lv
                p_sb:Apd(lstLmtColor[2].start):Apd("需要"):Apd(Strname):Apd("天赋达到")
                :Apd(skilllmtLv):Apd("级\n"):Apd(lstLmtColor[2].endstr)
            end
            if lmPoint~=0 then
                local start = lstLmtColor[3].start
                p_sb:Apd(start):Apd("需要此天赋树已投入"):Apd(lmPoint):Apd("点[-]"):Apd(lstLmtColor[3].endstr)
            end
        end
        lmtStr=p_sb:ToStr()
        ObjPool.Add(p_sb);
    end
    self.lmtDec.text=lmtStr;
    --名字 等级
    self.sklName.text=sltInf.name;
    self.curLv.text=string.format("(%s/%s)",lv,max )
    --描述
    local strNow = "[F39800FF]本级效果:[-][F4DDBDFF]无[-]"
    local strNex = "[F39800FF]已达到最高等级[-]"
    local strprop = 1
    self.propDec.text=sltInf.hurtDec
    local ndPt = "";
    if lv~=0 then
        strNow="[F39800FF]本级效果:[-][F4DDBDFF]".. sltInf.desc
    end
    if info.nextId~="max" then
        strNex ="[F39800FF]下级效果:[-][F4DDBDFF]".. SLT[info.nextId].desc
        ndPt = string.format("%s需要天赋点数：%s[-]",lstLmtColor[4].start,info.exp)
    end
    self.nowDec.text = strNow;
    self.nexDec.text = strNex;
    self.ndPoint.text = ndPt;
    self:Setbtn(info);
end

--加载icon完成
function My:LoadIcon(obj)
	if self.icon == nil then
        AssetTool.UnloadTex(obj.name)
        return;
    end
    self.icon.mainTexture=obj;    
end


function My:Dispose( )
    AssetMgr:Unload(self.IconTex,false);
end

function My:Clear(  )
    -- My:Dispose( )
    TableTool.ClearUserData(self);
end

return My;