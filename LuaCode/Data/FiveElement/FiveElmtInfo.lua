require("Data/FiveElement/FvElmtMons")
FiveElmtInfo = Super:New{Name = "FiveElmtInfo"}
local My = FiveElmtInfo;

function My:Ctor()
    self.fvElmtMonsList = {}
end

--初始化信息
function My:InitInfo(copyId,monsId,pos)
    self.copyId = copyId;
    self:SetFvElmntInfo(monsId,nil,pos);
end

--设置CD列表
function My:SetCDList(cdList)
    if cdList == nil then
        return;
    end
    local len = #cdList;
    for i = 1,len do
        local monsId = cdList[i].id;
        local rfrTime = cdList[i].val;
        self:SetFvElmntInfo(monsId,rfrTime,nil);
    end
end

--设置五行信息
function My:SetFvElmntInfo(monsId,rfrTime,pos)
    local monsInfo = self.fvElmtMonsList[monsId];
    if monsInfo == nil then
        monsInfo = ObjPool.Get(FvElmtMons);
        self.fvElmtMonsList[monsId] = monsInfo;
    end
    monsInfo:SetInfo(monsId,rfrTime,pos);
end

--释放
function My:Dispose()
    TableTool.ClearDicToPool(self.fvElmtMonsList);
end