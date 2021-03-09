FashionHelper = Super:New {Name = "FashionHelper"}

local My = FashionHelper;
My.IsCouple = false;

--创建皮肤单元
function My.CreateSkinUnit(IsCouple)
    My.IsCouple = IsCouple;
    My.CreateFormCfg(WingCfg);
    My.CreateFormCfg(PetTemp);
    My.CreateFormCfg(MWCfg);
    My.CreateFormCfg(GWCfg);
    My.CreateFormCfg(MountCfg);
    My.CreateFormCfg(ThroneCfg);
end

function My.CreateFormCfg(cfgs)
    for k,v in pairs(cfgs) do
        My.CreateFashionUnit(v);
    end
end

--创建时装数据结构
function My.CreateFashionUnit(data)
    if data == nil then
        return;
    end
    if data.type ~= 1 then
        return;
    end
    local unit = ObjPool.Get(FashionUnit);
    local baseId = data.id;
    unit.baseId = baseId;   --时装基础id
    unit.uid = baseId * 100;  --道具Id
    unit.curId = baseId * 100;   --当前ID
    unit.name = data.name;
    --unit.type = data.type;   --时装类型
    unit.isActive = false;    --是否激活
    unit.isUse = false;  --是否使用
    unit.mIcon = data.icon; --男图标
    unit.wIcon = data.icon; --女图标
    if My.IsCouple == true then
        FashionMgr.coupleFashionDic[tostring(baseId)] = unit;
    else
        FashionMgr.fashionDic[tostring(baseId)] = unit;
    end
    return unit
end

--获取激活数
function My.GetActNum(data)
    if data.isActive == true then
        local type = data.type;
        if type == 1 then
            return nil;
        else
            local xlData = FashionMgr:GetCoupleSuitUnit(data.id);
            if  xlData.isActive == true then
                return nil;
            end
        end
    end

    local fashionList = data.fashionList;
    if fashionList == nil then
        return nil;
    end
    local attrs = data.attrList;
    local skillInfo = data.skillInfo;
    local hasActNum = data.activeNum;
    local curActNum = 0;
    local num = nil;
    num,curActNum = My.GetActNumInfo(fashionList,attrs,skillInfo,curActNum,hasActNum);
    if num ~= nil then
        return num;
    end

    --检查仙侣套装
    if data.type == 2 then
        local data = FashionMgr:GetCoupleSuitUnit(data.id);
        if data == nil then
            return nil;
        end
        local fashionList = data.fashionList;
        if fashionList == nil then
            return nil;
        end
        num,curActNum = My.GetActNumInfo(fashionList,attrs,skillInfo,curActNum,hasActNum);
        return num;
    end
    return nil;
end

--获取套装可激活数量信息
function My.GetActNumInfo(fashionList,attrs,skillInfo,curActNum,hasActNum)
    local len = #fashionList;
    for k = 1, len do
        local curActive = fashionList[k].isActive;
        if curActive == true then
            curActNum = curActNum + 1;
            for i = 1, #attrs do
                if attrs[i] ~= nil then
                    local num = attrs[i].num;
                    if num > hasActNum and num == curActNum then
                        return num, curActNum;
                    end
                end
            end
            if skillInfo ~= nil then
                local num = skillInfo.k;
                if num > hasActNum and num == curActNum then
                    return num, curActNum;
                end
            end
        end
    end
    return nil,curActNum;
end

--获取套装部件激活数量
function My.GetSuitAtiveNum(data)
    if data == nil then
        return 0,false;
    end
    local fashionList = data.fashionList;
    if fashionList == nil then
        return 0,false;
    end
    local num = 0;
    local len = #fashionList;
    local active = false;
    for k = 1, len do
        if fashionList[k].isActive == true then
            num = num + 1;
        end
    end
    if num == len then
        active = true;
    end
    return num, active;
end

--获取仙侣套装部件激活数量
function My.GetCoupleSuitActNum(data)
    if data == nil then
        return 0;
    end
    if data.type ~= 2 then
        return 0;
    end
    local xlData = FashionMgr:GetCoupleSuitUnit(data.id);
    local num = My.GetSuitAtiveNum(xlData);
    return num;
end

--获取套装部位激活数量总接口
function My.GetAllSuitActNum(data)
    local num,active = My.GetSuitAtiveNum(data);
    local xlNum = My.GetCoupleSuitActNum(data);
    num = num + xlNum;
    return num,active;
end

--获取套装属性列表
function My.GetSuitAttrList(attrs)
    local list = {}
    for k=1,#attrs do
        local suitAttrs = attrs[k].val;
        for i=1,#suitAttrs do
            local kv = {}
            kv.k = suitAttrs[i].id;
            kv.v = suitAttrs[i].val;
            table.insert(list,kv);
        end
    end
    return list;
end

--获取时装时间
function My.GetFashionTime(endtime)
    if endtime == 0 or endtime == nil then
        return 0;
    end
    local svCurTime = TimeTool.GetServerTimeNow();
    svCurTime = svCurTime * 0.001;
    local leftTime = endtime - svCurTime;
    return leftTime;
end

--获取时装计时器
function My.GetFashionTimer(endtime)
    if endtime == 0 or endtime == nil then
        return nil;
    end
    local leftTime = My.GetFashionTime(endtime);
    if leftTime <= 0 then
        return nil;
    end
    local timer = ObjPool.Get(DateTimer);
    timer.fmtOp = 3;
    timer.apdOp = 2;
    return timer;
end