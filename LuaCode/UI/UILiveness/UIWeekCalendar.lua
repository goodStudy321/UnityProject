UIWeekCalendar = Super:New{Name="UIWeekCalendar"};
local My = UIWeekCalendar;
local LIV = LivenessCfg
local TWC = tWeekCalendar 
--时间
local tmlst={};
--活动
local dtlst={};
--日期
My.week=1

function My:Init(root)
    self.root= root;
    local tip = self.Name;
    local CG = ComTool.Get;
    local TF = TransTool.Find;
    local TFC = TransTool.FindChild;

    self.sv=TF(root,"sv",tip);
    self.tmGrid=CG(UIGrid,self.sv,"tmGrid",tip);
    self.wcGrid=CG(UIGrid,self.sv,"wcGrid",tip);
    self.tmItem = TFC(self.sv,"tmGrid/tmItem",tip);
    self.dtItem = TFC(self.sv,"wcGrid/dtItem",tip);
    soonTool.setPerfab(self.tmItem,"tmItem");
    soonTool.setPerfab(self.dtItem,"dtItem");
    self:GetWeek();
    self:readTab();

end
--获取日期
function My:GetWeek()
    local day=System.DateTime.Today.DayOfWeek; 
    day = tostring(day);
    if day=="Monday" then
        My.week=1;
    elseif day=="Tuesday" then
        My.week=2;
    elseif day=="Wednesday" then
        My.week=3;
    elseif day=="Thursday" then
        My.week=4;
    elseif day=="Friday" then
        My.week=5;
    elseif day=="Saturday" then
        My.week=6;
    elseif day=="Sunday" then
        My.week=7;
    end
end

function My:readTab( )
    local CG = ComTool.Get;
    local UC = UITool.SetLsnrSelf;
    local TFC = TransTool.FindChild;
    local UL = UILabel;
    local path = "Label"
    for i=1,#TWC do
        --时间
        local go =  soonTool.Get("tmItem");
        go.name=100+i;
        CG(UL,go.transform,path).text=TWC[i].time;
        tmlst[i] = go;
        --活动
        local lst = TWC[i].active;
        for k=1,#lst do
            local go2 = soonTool.Get("dtItem");
            go2.name = i*10+k;
            local livId = lst[k]
            if livId==0 then
                    CG(UL,go2.transform,path).text="/";
                else
                    local cfg= BinTool.Find(LIV, livId);
                    if cfg==nil then
                        iTrace.Error("活跃度无此id","id=  "..livId);
                        return; 
                    end
                    CG(UL,go2.transform,path).text=cfg.name;
            end
            UC(go2,self.Onclick,self, nil, false);
            table.insert(dtlst,go2);
            if k==My.week then
                local red = TFC(go2.transform,"red");
                red:SetActive(true);
            end
        end
    end
    self.wcGrid:Reposition();
    self.tmGrid:Reposition();
end

function My:Onclick(go)
    local num = tonumber(go.name);
    local i,k = math.modf(num/10);
    k=  math.floor(k*10+0.1);
    local id =TWC[i].active[k]; 
    if id==0 then
        UILiveness.detail:SetMenuState(false);
        return;
    end
    local msg = BinTool.Find(LIV, id);
    UILiveness.detail:UpShow(msg);
    self:SetDesPos(i,k,go);
end


--设置描述坐标
function My:SetDesPos(i,k,go)
    local Add = TransTool.AddChild
    local it = UILiveness.detail
    local tran = go.transform;
    Add(self.wcGrid.transform, it.root)
    local vec = tran.localPosition.x
    local x = 1;
    if k > 3 then
         x =tonumber(vec)-205;
    else
         x =vec+205;
    end
    it:SetMenuState(true);
    it.root.localPosition=Vector3.New(x, -133, 0)
end

function My:Clear( )
    TableTool.ClearUserData(self);
    soonTool.AddList(tmlst,"tmItem");
    soonTool.AddList(dtlst,"dtItem");
    soonTool.DesGo("tmItem");
    soonTool.DesGo("dtItem");
end

return My;