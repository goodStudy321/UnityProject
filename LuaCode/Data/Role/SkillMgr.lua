require("Data/Role/SkillHelp")
require("Data/Role/SkillInfo")
SkillMgr={Name="SkillMgr"}
local My =SkillMgr;

local SLT = SkillLvTemp
local sexStr={"女","男"}
--技能状态
My.SkillSateList={};
--技能排序
My.doSortLst={};
--先移除道具再升级技能
--上线也是先推背包再推送技能
--技能大红点
My.Allred=false
My.redLst={false,false,false}
--所有的技能
My.SkillLst={}
--技能更新完毕
My.eSkillUpdate=Event()
My.eRed=Event()
--升级成功
My.lvUp=Event();
--选择成功
My.choseSuc=Event();
function My:Init( )
    local PA =  ProtoLsnr.AddByName;
    PA("m_skill_up_toc",self.reSkillUp,self)
    PA("m_skill_seal_choose_toc",self.reChooseEPG,self)
    PA("m_skill_seal_level_toc",self.reSealUp,self)
    PA("m_skill_seal_reset_toc",self.reResetEPG,self)
    EventMgr.Add("SkillUpdate", My.SkillUpdate);
    EventMgr.Add("SelectSuc", My.brigde)  
    PropMgr.eUpdate:Add(My.SetAllSkillRed)
    EventMgr.Add("AddSkill", My.Addskill)  
    EventMgr.Add("RemoveSkill", My.RemoveSkill)  
    UserMgr.eLvEvent:Add(self.SetAllSkillRed)
end

--执行开始改变
function My.brigde(  )
    My.openLisnr("Add") 
    SkillHelp:Init( )
end
function My.openLisnr( func )
    EventMgr[func]("OnChangeScene", My.openOnce)
end
function My.DoTabelInStart(  )
    local typeId = tostring(User.instance.MapData.UnitTypeId);
    local SKLst = RoleAtt[typeId].skills;
    local skLen = #SKLst;
    for i = 1, skLen do
        local msg = ObjPool.Get(SkillInfo)
        local skillid = SKLst[i]
        msg:setbase(skillid)
        My.SkillLst[msg.baseid]=msg
    end
end


function My.SkillUpdate(  )
    My.Allred=false
    My.redLst={false,false,false}
    local SKLst = User.instance.MapData.SkillInfoList;
    local len = SKLst.Count - 1;
    if len<0 then
      return;
    end
    for i = 0, len do
        local pskill = SKLst[i]
        local strid = tostring(pskill.skill_id)
        local info = SLT[strid]
        local baseid = info.baseid
        local msg = My.SkillLst[baseid]
        if msg==nil then
            iTrace.Error("soon","角色等级表没找到此技能基础id"..baseid)
            return
        end
        msg:UpdateInfo(pskill,info)
    end
    local fKLst = User.instance.MapData.FashionSkillInfoList;
    local len = fKLst.Count - 1;
    if len>-1 then
      for i = 0, len do
        local pskill = fKLst[i]
        local strid = tostring(pskill.skill_id)
        local info = SLT[strid]
        local baseid = info.baseid
        local msg = My.SkillLst[baseid]
        if msg==nil then
            iTrace.Error("soon","角色等级表没找到此技能基础id"..baseid)
            return
        end
        msg:UpdateInfo(pskill,info)
      end
    end
    My.SetAllSkillRed()
end

function My.SetAllSkillRed( )
    My.lvl= User.instance.MapData.Level  
    My.Allred=false
    My.redLst={false,false,false}
    for k,v in pairs(My.SkillLst) do
        My.SkillRed(v)
    end
    My.eSkillUpdate()
    My.eRed( My.Allred)
    if My.Allred then
        SystemMgr:ShowActivity(ActivityMgr.JN, 2)
    else
        SystemMgr:HideActivity(ActivityMgr.JN, 2)
    end
end

function My.findSealInLst( p_skill,sealId )
    local lstSeal = p_skill.seal_id_list
    local len = lstSeal.Count
    if len<1 then
        return false,sealId
    end
    len=len-1
    for i=0,len do
        local info =tSkillEpg[tostring(lstSeal[i])]
        local base=info.baseId
        if base==sealId then
             return true,lstSeal[i]
        end 
    end
    return false,sealId
end

function My.SealCanLv(sealred, sealid,unlock)
    local sealInfo = tSkillEpg[tostring(sealid)]
    if sealInfo.curLvl==sealInfo.maxLvl then
        sealred.max=true
        return false
    end
    if unlock then
        sealid= sealid+1
    end
    sealInfo = tSkillEpg[tostring(sealid)]
    local costls = sealInfo.cost
    local len = #costls
    if len==0 then
        sealred.seal_up=true
        return true
    end
    for i=1,len do
        local info = costls[i]
        local id = info.k
        local num = info.v
        local hasNum = PropMgr.TypeIdByNum( id);
        if sealInfo.lmLvl<=My.lvl  then
            sealred.seal_unlmt=true
            if hasNum>=num  then
                sealred.seal_exp=true
                sealred.seal_up=true
                return true
            end
        end
    end
    return false
end

function My.SealCostEnough( sealnextInfo)
   local costls = sealnextInfo.cost
   local len = #costls
   if len==0 then
       return true
   end
   for i=1,len do
       local info = costls[i]
       local id = info.k
       local num = info.v
       local hasNum = PropMgr.TypeIdByNum( id);
       if hasNum>=num  then
          return true
       end
   end
   return false
end
function My.SkillRed( p_skill )
    -- p_skill.seal_red_list={false,false,false}
    p_skill.red=false
    p_skill.upred=false
    p_skill.seal_up=false
    p_skill.seal_exp=false
    if My.lvl==nil then
        return
    end
   if p_skill.isOpen then
      if p_skill.Seallim~=nil and p_skill.Seallim<=My.lvl then
       p_skill.seal_Open = true
      end
      if p_skill.tb~=3 and p_skill.Seallim~=nil and p_skill.Seallim<=My.lvl  then
        local sealLst = p_skill.seal_base_list
        for i=1,#sealLst do
            local baseid = sealLst[i]
            -- if baseid==1002101 then
            --     iTrace.Error("ss")
            -- end
            local unlock , sealid= My.findSealInLst(p_skill,baseid)
            local sealred = {}
            sealred.seal_unlmt=false
            sealred.seal_exp=false
            sealred.seal_up=false
            sealred.max=false
            local sealbool = My.SealCanLv(sealred, sealid,unlock)
            p_skill.seal_upred_list[i]=sealred
            if sealbool then
                p_skill.red = true
                My.Allred=true;
                p_skill.seal_up=true
                My.redLst[p_skill.tb]=true
            end
        end
      end
--[[
      if p_skill.seal_id==0 and p_skill.tb~=3 and p_skill.Seallim~=nil and p_skill.Seallim<=My.lvl then
        if p_skill.seal_id_list~=nil and p_skill.seal_id_list.Count>0 then
            p_skill.red = true
            p_skill.chosered=true
            My.Allred=true;
            My.redLst[p_skill.tb]=true
        else
         local sealLst = p_skill.seal_base_list
          for i=1,#sealLst do
            local sealid = sealLst[i]
            local sealbool = My.SealCanLv( sealid)
            if sealbool then
                p_skill.red = true
                p_skill.chosered=true
                My.Allred=true;
                My.redLst[p_skill.tb]=true
                break;
            end
        end
        end
    else
        p_skill.chosered=false
        if p_skill.Seallim~=nil and p_skill.seal_id~=0 then
            local sealInfo = tSkillEpg[tostring(p_skill.seal_id)]
            p_skill.curLvl=sealInfo.curLvl
            if sealInfo.curLvl<sealInfo.maxLvl then
                p_skill.maxLvl=sealInfo.maxLvl
                local sealNext = p_skill.seal_id+1
                local sealnextInfo = tSkillEpg[tostring(sealNext)]
                local sealbool = My.SealCostEnough( sealnextInfo)
                if sealbool then
                    p_skill.seal_exp=true
                end
                if sealnextInfo.lmLvl<=My.lvl then  
                    p_skill.seal_lmLvl= sealnextInfo.lmLvl
                    p_skill.seal_unlmt=true 
                else
                    p_skill.seal_unlmt=false 
                    p_skill.seal_up=false
                end
                if  p_skill.seal_exp and  p_skill.seal_unlmt then
                    p_skill.red = true
                    p_skill.chosered=false
                    p_skill.seal_up=true
                    My.Allred=true;
                    My.redLst[p_skill.tb]=true
                else
                    p_skill.seal_up=false
                end
            end
        end
    end
--]]
    end
    if p_skill.undermax==false or p_skill.cost==nil or p_skill.itemId ==nil then
        return 
    end
    local hasNum = PropMgr.TypeIdByNum( p_skill.itemId );
    if hasNum-p_skill.itemNum >=0 then
        My.Allred=true;
        My.redLst[p_skill.tb]=true
        p_skill.red = true
        p_skill.upred=true
    else
        p_skill.upred=false
    end
end
--快速升级
function My:quickUpLv( item,id)
    -- local b=false 
    -- for k,v in pairs(My.SkillLst) do
    --  if v.itemId==item.id then
    --     self:SkillUp( v.skill_id )
    --     b=true
    --     break;
    --  end
    -- end
    -- if b then
    --     UITip.Log("无法升级")
    -- end
    local value = QuickUseMgr:LimJump(item,id)
    if value then return end
    local sexSame = true
    if item.skillBaseId~=nil then
        if item.uFx==82 then
            sexSame = SkillHelp.OpenSkillWithid(item.skillBaseId)
        elseif item.uFx==85 then
            SkillHelp.OpenSealWithid(item.skillBaseId)
        end
    end
    if sexSame==false then
        UITip.Log("该职业无法使用此技能书")
        return;
    end
    local isOpen= UIRole.roleOpen
    if isOpen ==false  then
        UIRole:SelectOpen( SkillHelp.type,SkillHelp.tb )
    else
        UIRole.tb=SkillHelp.tb
        UIRole.SkillBtnTog.value=true
        local iso= UIMgr.GetActive(PropTip.Name);
        if  isOpen ~=-1  then
            UIMgr.Close(PropTip.Name)
        end        
        UIRole:SBActive(SkillHelp.type)
    end
end

function My.SealUpSend( skill,EpgId )
    local msg = ProtoPool.Get("m_skill_seal_level_tos");
    msg.skill_id=skill
    msg.seal_id=EpgId
    ProtoMgr.Send(msg);
end

function My:reSealUp( msg )
    local err_code = msg.err_code;
    if err_code==0 then
        UITip.Log("铭文升级成功")
        My.choseSuc()
    else
      local err = ErrorCodeMgr.GetError(err_code);
      UITip.Log(err)
    end
end


function My.ChooseEPG( skill,EpgId )
    local msg = ProtoPool.Get("m_skill_seal_choose_tos");
    msg.skill_id=skill
    msg.seal_id=EpgId
    ProtoMgr.Send(msg);
end


function My:reChooseEPG( msg )
    local err_code = msg.err_code;
    if err_code==0 then
        UITip.Log("铭文选择成功")
        My.choseSuc()
    else
      local err = ErrorCodeMgr.GetError(err_code);
      UITip.Log(err)
    end
end


function My:ResetEPG( skill )
    local msg = ProtoPool.Get("m_skill_seal_reset_tos");
    msg.skill_id=skill
    ProtoMgr.Send(msg);
end
function My:reResetEPG( msg )
    local err_code = msg.err_code;
    if err_code==0 then
        UITip.Log("铭文应用成功")    
    else
      local err = ErrorCodeMgr.GetError(err_code);
      UITip.Log(err)
    end
end

function My:SkillUp( skill )
    local msg = ProtoPool.Get("m_skill_up_tos");
    msg.skill_id=skill
    ProtoMgr.Send(msg);
end
function My:reSkillUp( msg )
    local err_code = msg.err_code;
    if err_code==0 then
        UITip.Log("升级成功")
        My.lvUp()
    else
      local err = ErrorCodeMgr.GetError(err_code);
      UITip.Log(err)
    end
end



function My.Addskill(skill )
    local skill = tostring(skill)
    local b = true;
    for i=1,#My.doSortLst do
       if skill==My.doSortLst[i] then
          b=false;
          break;
       end
    end
    if b then
        table.insert( My.doSortLst,1, skill);
        My.ToSendSort(My.doSortLst);
        local Name2 = tostring(User.instance.MapData.UID).."SkillSort";
        SettingSL:OnSave(SkillMgr.doSortLst,Name2);
    end
end

function My.RemoveSkill(skill )
    skill=tostring(skill);
    for i=1,#My.doSortLst do
        if My.doSortLst[i]==skill then
            table.remove(My.doSortLst , i)
            My.ToSendSort(My.doSortLst);
            local Name2 = tostring(User.instance.MapData.UID).."SkillSort";
            SettingSL:OnSave(My.doSortLst,Name2);
            break;
        end
    end
end


function My.openOnce( )
    local Name = tostring(User.instance.MapData.UID).."Skill";    
    My.SkillSateList=SettingSL:ReadName(Name)
    My.readSort();
    My.SendSkill(My.SkillSateList) 
    My.DoTabelInStart(  )
    My.openLisnr("Remove")
end
function My.readSort( )
    local Name = tostring(User.instance.MapData.UID).."SkillSort";   
    local tLst=SettingSL:ReadName(Name);
    for k,v in pairs(tLst) do
        if type(k) == "number" then
            break;
        end
        tLst[tonumber(k)]=v;
    end
    for k,v in pairs(tLst) do
        if type(v) == "string" then
            break;
        end
        tLst[k]=tostring(v);
    end
    My.doSortLst=tLst;
    My.ToSendSort(tLst);
end
--发送false状态id
function My.SendSkill(dic)
    if dic==nil then
        return
    end
    for k,v in pairs(dic) do
        if v==false then
            EventMgr.Trigger("SetSkState",k)
        end
    end
end

function My.ToSendSort( list )
    if list==nil or #list==0 then
        return;
    end
    for i=1,#list do
        EventMgr.Trigger("SkillPlayOrder",i,list[i]);
    end
end

--xiaoyu 
function My:ReqSkillUp(skillBaseId)
    local dic=My.SkillLst
    for key, value in pairs(dic) do
        if key==skillBaseId then
            -- My:SkillUp(value.skill_id)
            if value.level >= value.limLv then
                My:SkillUp(value.skill_id)
            else
                My:SkillUp(value.next_skilid)
            end
        end
    end
end
--


function My:Clear(isReconnect)
    if isReconnect then
        return
    end
    SkillHelp.Change(  )
   soonTool.ClearList(My.SkillLst)
end
return My;
