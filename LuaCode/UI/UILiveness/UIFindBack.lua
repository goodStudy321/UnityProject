UIFindBack= Super:New{Name="UIFindBack"};
local My = UIFindBack;
require("UI/UILiveness/FindBackItem");
require("UI/UILiveness/FindBackTip");
My.gbjList={};
My.objList={};
--当前模式1绑元2银两
My.type = 2;
--状态改变
My.eChange=Event();

function My:Init(root)
   
    self.root=root
    local tip = self.Name;
    local CG = ComTool.Get;
    local TF = TransTool.Find
    local TFC = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;
    --sv
    self.grid=CG(UIGrid,root,"sv/Grid",tip);
    self.findBackItem=TFC(self.grid.transform,"findBackItem",tip);
    soonTool.setPerfab(self.findBackItem,"findBackItem");
    --按钮设置
    local btRoot = TF(root,"btn",tip);
    UC(btRoot, "say",tip, self.sayHow, self);
    UC(btRoot, "yuan",tip, self.typeChange, self);
    UC(btRoot, "mney",tip, self.typeChange, self);
    self.mney=CG(UIToggle,btRoot,"mney");
    self.mney.value=true;
    self:lsnr("Add");
    self:FindShow();
    self.FBT = TF(root,"findTip");
    self.FBT.gameObject:SetActive(false);
    self.FBTobj=ObjPool.Get(FindBackTip);
    self.FBTobj:Init(self.FBT);
    self:CheckChange(My.type);
    self.lv=User.instance.MapData.Level;
end
--说明
function My:sayHow( )
    local str=tFindBack[1].say;
    UIComTips:Show(str, Vector3(-427,-231,0),nil,nil,nil,nil,UIWidget.Pivot.BottomLeft);
end
--改变状态
function My:typeChange(go)
    if go.name=="yuan" and (self.lv<GlobalTemp["94"].Value3) then
        UITip.Log("达到300级以上的玩家可使用绑元追回");
        self.mney.value=true;
        return;
    end
    if go.name=="yuan" then
        self:CheckChange(1);
    else
        self:CheckChange(2);
    end
end
function My:CheckChange(num)
    if num==My.type then
        return;
    end
    My.type=num;
    self.eChange(num);
end

--监听
function My:lsnr(fun)
    FindBackMgr.eFind[fun](FindBackMgr.eFind,self.FindShow,self);
    FindBackMgr.eBuy[fun](FindBackMgr.eBuy,self.FindSuc,self);
end

--展示显示
function My:FindShow( )
    soonTool.AddList(self.gbjList,"findBackItem",true);
    soonTool.ObjAddList(self.objList);
    local FFL = FindBackMgr.FindList;
    if FFL==nil then return; end
    for k,v in pairs(FFL) do
        if v~=nil then
            local go = soonTool.Get("findBackItem");
            local obj = ObjPool.Get(FindBackItem);
            go.name=100+v.id;
            obj:Init(go,v.id);
            self.gbjList[v.id]=go;
            self.objList[v.id]=obj;
        end
    end
    self.grid:Reposition();
end

function My:FindSuc(id)
  local t = FindBackMgr.FindList[id];
  if t==nil then
     return;
  end
  if t.bas==0 and t.ext==0 then
    local tb = self.objList[t.id];
    tb:Clear();
    self.objList[t.id]=nil
    local go = self.gbjList[t.id];
    self.gbjList[t.id]=nil;
    GameObject.DestroyImmediate(go);
    FindBackMgr.FindList[id]=nil;
  else
    self.objList[id]:BuySuc();
  end
  self.grid:Reposition();
end

function My:Clear( )
    My.type = 2;
    soonTool.AddList(self.gbjList,"findBackItem");
    soonTool.ObjAddList(self.objList);
    soonTool.DesGo("findBackItem");
    self:lsnr("Remove");
    self.FBTobj:Clear();
end


return My;