OffLBatUISet = {Name = "OffLBatUISet"}
local My = OffLBatUISet;
--对象列表
My.GoList = {}
--过滤名字列表
My.filtedNames = {}
local names = My.filtedNames;
names["virtualbox"] = true;
names["SkillView"] = true;
names["LeftCenter"] = true;

--设置主界面UI
function My.SetMMUI()
    local ui = UIMgr.Get(UIMainMenu.Name);
    if ui == nil then
        return;
    end
    TableTool.ClearDic(My.GoList);
    My.ShowUISkill();--打开不在屏幕内的UI技能按钮界面
    local trans = ui.root;
    local len = trans.childCount;
    for i = 0,len-1 do
        local child = trans:GetChild(i);
        local filted = My.GetFilt(child.name);
        My.AddToList(child.gameObject,filted);
    end
    My.SetStrgBtn(ui);
end

--还原主界面UI
function My.RevertMMUI()
    local list = My.GoList;
    if list == nil then
        return;
    end
    for k,v in pairs(list) do
        My.SetGoState(v,true);
    end
end

--设置设置变强按钮
function My.SetStrgBtn(mainMenu)
    local go = UIStrengthenList.Root;
    local filted = false;
    My.AddToList(go,filted);
end

--显示技能按钮图标界面
function My.ShowUISkill()
    local ui = UIActivityBtnsView;
    if ui.IsBottomStatus == true then
        return;
    end
    ui:ClickSBtn(nil);
end

--获取过滤对象
function My.GetFilt(name)
    for k,v in pairs(My.filtedNames) do
        if name == k then
            return true;
        end
    end
    return false;
end

--添加到列表
function My.AddToList(go,filted)
    if filted == true then
        return;
    end
    if go == nil then
        return;
    end
    if go.activeSelf == false then
        return;
    end
    local list = My.GoList;
    list[#list+1] = go;
    My.SetGoState(go,false);
end

--设置对象状态
function My.SetGoState(go,active)
    if go == nil then
        return;
    end
    go:SetActive(active);
end