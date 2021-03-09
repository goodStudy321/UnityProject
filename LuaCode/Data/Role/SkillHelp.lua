SkillHelp = {Name="SkillHelp"}
local My = SkillHelp

--type
My.type=2;
My.tb=0;
My.skillBaseId=0
local baseLst = {}
function My:Init( )
    local typeId = tostring(User.instance.MapData.UnitTypeId);
    local SKLst = RoleAtt[typeId].skills;
    local skLen = #SKLst;
    for i=1,skLen do
        local skill = SKLst[i]
        local info = SkillLvTemp[tostring(skill)]
        if info==nil then
            iTrace.Error("soon","无此技能id的配置检查角色属性表和技能配置表"..skill);
            break;
        end
        local base = info.baseid
        baseLst[base]=SKLst[i]
    end
end

function My.ShowMsg( weit, id,xAdd,yAdd )
    if xAdd==nil or yAdd==nil then
        xAdd=0
        yAdd=0 
    end
    local trans = weit.transform
    My.type_id=id
    local x,y = UIMisc.GetInputDir()
    My.xy=Vector3.New(x+xAdd,y+yAdd,0)
    local pos = trans.position
    pos.x=pos.x+xAdd
    pos.y=pos.y+yAdd
    PropTip.pos=pos
    PropTip.xy=My.xy
    PropTip.width=weit.width*trans.localScale.x
    UIMgr.Open(PropTip.Name,My.OpenCb)
end
function My.OpenCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then 
        ui:UpData(My.type_id)
	end
end
function My.OpenSkillWithid(skillbaseId)
    My.type=2
    local baseid = skillbaseId[1]
    local strBase = tostring(baseLst[baseid])
    local info = SkillLvTemp[strBase]
    if info~=nil then
        My.tb=info.tb
        My.skillBaseId=baseid   
        return true
    else
        return false
    end
end
function My.OpenSealWithid(skillbaseId)
    --1男0女
    local userSex = User.MapData.Sex
    local sexid=userSex==1 and userSex or 2
    My.type=2
    local baseid = skillbaseId[sexid]--1男2女
    local strBase = tostring(baseLst[baseid])
    local info = SkillLvTemp[strBase]
    if info~=nil then
        My.tb=info.tb
        My.skillBaseId=baseid
    end
end

function My.Clear(  )
    My.type=2
    My.tb=0;
    My.skillBaseId=0
end
function My.Change(  )
    My.type=2
    My.tb=0;
    My.skillBaseId=0
end

return My;