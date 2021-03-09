require("Data/Role/InnateInfo")
InnateMgr={Name="InnateMgr"}
local My = InnateMgr
local TNB = tInnateBase
local TTB = tInnateTb
local TIS = tInnateSys
--角色等级
My.rolelvl=0
--天赋点
My.UpPoint=0;
--红点
My.red=false;
--页签红点
My.tbRed={false,false,false}
-- My.treeRed={}
--天赋技能
My.SkillList={};
--选中天赋树0无天赋树id
My.Select={0,0,0}
--初始化天赋
My.eInnate=Event();
--升级成功
My.eUp=Event();
--红点
My.eRed=Event();
--天赋点改变
My.ePoint=Event();
--消耗天赋点
My.costPoint=0;
--树名字
My.TreeNameLst=nil;
--树投入点数
My.treePoint={}
function My:Init( )
    local PA =  ProtoLsnr.AddByName;
    PA("m_talent_info_toc", self.setInLoad, self);
    PA("m_talent_point_toc", self.setPoint, self);
    PA("m_talent_reset_toc", self.rePoint, self);
    PA("m_talent_skill_toc", self.upSuc, self);
    UserMgr.eLvEvent:Add(self.lvUpdate)
    EventMgr.Add("SelectSuc", My.brigde)
    OpenMgr.eOpenNow:Add(My.BossOpenSet)
end
function My.BossOpenSet(isUpdate, list )
    if isUpdate==1 then
     if My.IsOpen() then
        My:UpdateRed( )
     end
    end
  end
function My.brigde(  )
    My.DoTabelInStart( )
end

function My.lvUpdate( )
    My:UpdateRed( )
    My.eInnate();
end

function My.DoTabelInStart( )
    if #My.SkillList~=0 then
        return;
    end 
    for k,v in pairs(TNB) do
        local msg = ObjPool.Get(InnateInfo)
        msg:setTNB(v)
        local tree = msg.tree
        -- if tree==nil then
        --     break;
        -- end
        local dic = My.SkillList[tree]
        if dic==nil then
            dic={}
        end
        dic[msg.grp]=msg
        My.SkillList[tree]=dic
    end
    for i=1,#My.SkillList do
        My.treePoint[i]=0
    end
    My.TreeNameLst=tInnateTb[1].treeNameLst
end
function My.tbUnLock(tb )
    local point = TTB[tb].need
--    iTrace.eError("soon","花费天赋为 "..My.costPoint)
    if My.costPoint+My.UpPoint>=point then
        return true
    else
        return false
    end
end

function My.OnTreeSeclt( tree )
    for i=1,#My.Select do
        if tree==My.Select[i] then
            return true
        end
    end
    return false
end

--红点更新
function My:UpdateRed( )
    My.rolelvl= User.instance.MapData.Level   
    local b = false;
    My.tbRed={false,false,false}
    -- My.ClearList( My.treeRed )
    if My.IsOpen() then
        for i=1,#My.Select do
            if not My.tbUnLock(i) then
                break;
            end
           if My.Select[i]==0 then
            local treelist = tInnateTb[i].tree
            for k=1,#treelist do
                local tree =treelist[k]
                -- if not My.OnTreeSeclt( tree ) then
                   local lst = My.SkillList[tree]
                   local isred = My.canLv(lst[1])
                   if isred then
                        lst[1].Error="第一个红点"
                        My.tbRed[i]=true
                        -- My.treeRed[tree]="第一个红点"
                        b=true
                   end
                -- end
            end
           else
            local tree = My.Select[i]
            local lst = My.SkillList[tree]
            if lst==nil then
                break;
            end
            for kj=1,#lst do
                local isred = My.canLv(lst[kj])
                if isred then
                    My.tbRed[i]=true
                    b=true
               end
            end
           end
        end
    end
    My.red=b;
    My.eRed(b);
end

function My.IsOpen( )
    return OpenMgr:IsOpen(65) 
end

--是否可以升级
function My.canLv( info )
    if info.nextId=="max" then
        info.Error="已达到最大等级"
        info.rad=false
        return false
    end
    if My.rolelvl<info.lmLv then
        info.Error="等级不足"
        info.rad=false
        return false
    end
    if My.treePoint[info.tree]<info.lmPoint then
        info.Error="天赋点投入不足"
        info.rad=false
        return false
    end
    local lmt = info.lmt
    if lmt~="" then
     local infolmt = TIS[lmt]
     if infolmt==nil then
        iTrace.Error("soon","配置表没找到次限制id"..lmt)
        return
     end
     local tree = infolmt.tree;
     local grp = TNB[infolmt.baseId].grp
     local findInfo = My.SkillList[tree][grp]
     if infolmt.lv>findInfo.lv then
        info.Error="需要解锁前置天赋"
        info.rad=false
        return false
     end
    end
    if My.UpPoint<info.exp then
        info.Error="天赋点不足"
        info.rad=false
        return false
    end
    info.rad=true
    return true
end

function My.needErrorLst(info )
    local lst = {{},{},{},{}}
    local redColer = "[F21919FF]"
    if My.rolelvl<info.lmLv then
        --"等级不足"
            lst[1].start=redColer
            lst[1].endstr="[-]"
    else
        lst[1].start=""
        lst[1].endstr=""
    end
    local lmt = info.lmt
    if lmt=="" then
        lst[2].start=""
        lst[2].endstr=""
    else
        local infolmt = TIS[lmt]
        if infolmt==nil then
            return
        end
        local tree = infolmt.tree;
        local grp = TNB[infolmt.baseId].grp
        local findInfo = My.SkillList[tree][grp]
        if infolmt.lv>findInfo.lv then
            --"需要解锁前置天赋"
            lst[2].start=redColer
            lst[2].endstr="[-]"
            else
            lst[2].start=""
            lst[2].endstr=""
        end
    end
    if My.treePoint[info.tree]<info.lmPoint then
        --"天赋点投入不足"
        lst[3].start=redColer
        lst[3].endstr="[-]"
        else
        lst[3].start=""
        lst[3].endstr=""
    end
    if My.UpPoint<info.exp then
        --"天赋点不足"
        lst[4].start=redColer
        lst[4].endstr="[-]"
        else
        lst[4].start="[F4DDBDFF]"
        lst[4].endstr=""
     end
    return lst
end

--是否可1级解锁
function My.unlock( info )
    local ts = TIS[info.id]
    if info.lv~=0 or ts.lmt=="" then
        return true
    end
    local lmt = tonumber(ts.lmt)
    local grp= TIS[ts.lmt].grp;
    local nowinfo = My.SkillList[grp]
    local id = tonumber(nowinfo.id) 
    if id>=lmt and nowinfo.lv~=0 then
        return true;
    end
    return false
end

--登陆设置
function My:setInLoad( msg )
    My.rolelvl= User.instance.MapData.Level   
    My.DoTabelInStart( )
    My.UpPoint = msg.talent_points;
    local lst = msg.talent_skills;
    for i=1,#lst do
        self.doOneTb(lst[i])
    end

    self:UpdateRed( )
    self.eInnate();
end

function My.doOneTb(p_tab_skill )
    local tb = p_tab_skill.tab_id
    local skills = p_tab_skill.skills
    if skills==nil and #skills  then
        My.Select[tb]=0
        return;
    end
    local tree = 0
    for i=1,#skills do
        tree=My.doInfo(skills[i])
    end
    My.Select[tb]=tree
end

function My.reBefore(tab_skills )
    local tb = tab_skills.tab_id
    local tree = My.Select[tb]
    My.treePoint[tree]=0
    local lst = My.SkillList[tree]
    My.Select[tb]=0
    local len = #lst
    for i=1,len do
       local info = lst[i]
       My.costPoint=My.costPoint+0-info.backPoint;
       local baseId = info.baseId
       local TNBInfo = TNB[baseId]
       info:setTNB(TNBInfo)
    end
end

--处理数据
function My.doInfo( id)
    local nextId = tostring(id+1)
    local strId = tostring(id);
    local info = TIS[strId];
    local baseId = info.baseId
    local sssss = TNB[baseId]
    if sssss==nil then
        iTrace.Error("soon","没有配置基础id为"..tostring(baseId))
        return
    end
    local grp = TNB[baseId].grp
    local tree = info.tree;
    local treeNode = My.SkillList[tree]
    local msg = treeNode[grp]
    local lv =info.lv
    local lmt = 0;
    local exp = 0;
    local lmPoint = 0;
    local lmLv = 0
    local backPoint=info.backPoint
    local add = backPoint-msg.backPoint
    local treePt = My.treePoint[tree]
    My.treePoint[tree]=treePt+add
    My.costPoint=My.costPoint+add
    if lv<msg.max then
        local infonext = TIS[nextId];
        if infonext==nil then
            return
        end
        lmt=infonext.lmt
        exp=infonext.exp
        lmPoint=infonext.lmPoint
        lmLv=infonext.lmLv
    else
        nextId="max"
     
    end
    msg:SetInfo(strId,lv,backPoint,nextId,lmt,exp,lmPoint,lmLv)
    return tree ,msg
end

--重置天赋
function My:rePoint( msg )
    if msg.err_code==0 then
        My.UpPoint = msg.talent_points;
        local tab_skills = msg.tab_skills;
        self.reBefore(tab_skills)
        self:UpdateRed( )
        self.eInnate();
        UITip.Log("重置天赋成功")
    else
        UITip.Log(ErrorCodeMgr.GetError(msg.err_code));
    end
end



--天赋点改变
function My:setPoint( msg )
    My.UpPoint=msg.talent_points;
    self.ePoint();
    self:UpdateRed( );
end

--重置天赋
function My:toRePoint(tb )
    local msg = ProtoPool.Get("m_talent_reset_tos");
    msg.tab_id=tb
    ProtoMgr.Send(msg);
end

--升级技能
function My:sendUpLevel( tb,id )
    local msg = ProtoPool.Get("m_talent_skill_tos");
    local id = tonumber(id);
    msg.tab_id=tb;
    msg.talent_skill_id=id;
    ProtoMgr.Send(msg);
end

--升级成功
function My:upSuc(msg )
    if msg.err_code==0 then
        My.UpPoint = msg.talent_points;
        local tab_skills = msg.learn_skill
        local tree,info = My.doInfo(tab_skills )
        My.Select[UIInnate.tb]=tree
        self:UpdateRed( );
        My.eUp(info);
    else
        UITip.Log(ErrorCodeMgr.GetError(msg.err_code));
    end
end

function My:Clear(isReconnect  )
    if isReconnect then
        return
    end
    My.UpPoint=0;
    My.costPoint=0;
    soonTool.ClearList(My.SkillList)
    soonTool.ClearList(My.treePoint)
end

return My;