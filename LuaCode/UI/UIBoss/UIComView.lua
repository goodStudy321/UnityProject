require("UI/UIBoss/UIBossCell");
UIComView = {Name = "UIComView"}

local My = UIComView;

--当前Boss格子创建次数
My.curLgth = nil;
--数据长度
My.length = nil;
--BossCell列表
My.BCList = {};

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

function My:Init(root)
    self.root = root;
    local name = root.name;
    local TF = TransTool.Find;
    local CG = ComTool.Get;
    local grid = "ScrollView/Grid";
    self.Grid = TF(root,grid,name);
    self.GridC = CG(UITable,root,grid,name,false);
    self.sv = CG(UIScrollView,root,"ScrollView",name,false);
end

function My:Open(bossList,type)
    type=tonumber(type);
    self:ClearBCL();
    local bl = bossList;
    local len = #bl;
    self.length = len;
    self.curLgth = 0;
   if type == 3 then
        for i = 1, len do
            self:InitBC(i,bl[i].type_id,true,nil,nil);
        end
    else
        for i = 1, len do
            local info = bl[i]
            self:InitBC(i,info.type_id,info.is_alive,info.next_refresh_time,info.remain_num,info.role_num,info.can_enter);
        end
    end
    self.GridC:Reposition();
    self.sv:ResetPosition()
    if BossHelp.CurCell~=nil then
        soonTool.ChooseInScrollview(BossHelp.CurCell.root,self.sv)
    end
end

--初始化boss格子
function My:InitBC(index,typeid,isAlive,time,curNum,roleNum,canEnter)
    local bcl = self.BCList;
    local bsv = nil;
    bsv = ObjPool.Get(UIBossCell);
    bsv:InitD(typeid,isAlive,time,curNum,roleNum,canEnter);
    bsv:LoadCell(index,self.Grid,self);
    self.BCList[index] = bsv;
end

function My:Close()
    self:ClearBCL();
    self.length = nil;
    self.root = nil;
    self.Grid = nil;
    self.GridC = nil;
    self.callBack = nil;
end

function My:Dispose()

end

--清除boss格子列表
function My:ClearBCL()
    if self.length == nil then
        return; 
    end
    local bc = nil;
    for i = self.length, 1,-1 do
        bc = self.BCList[i];
        if bc then
            bc:Close();
        end
    end
end
--加载一个格子完成
function My:LoadCD()
    self.curLgth = self.curLgth + 1;
    if self.curLgth < self.length then
        return;
    end
 
end