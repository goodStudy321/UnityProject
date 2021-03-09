UIInnate = Super:New{Name="UIInnate"}
require("UI/UIRole/InnateSkillInfo")
require("UI/UIRole/InnateTreeItem")
require("UI/UIRole/InnateItem")
require("UI/UIRole/InnateTree")
local My = UIInnate;
--技能表
My.SklLst={};
--默认第一次生效
My.shoudSlct=1;
---当前选中
My.selectIndex=0;
--当前页签
My.tb=0
--当前树
My.tree=0;
--选中info
My.selectInfo=nil;
--注册的事件回调函数
My.petGetWay = {
	"境界","五行幻境", "未开启"
}
function My:Init(root )
    self.IntSkillLst = InnateMgr.SkillList
    self.root=root
	local TF = TransTool.Find
	local TFC = TransTool.FindChild
	local UC = UITool.SetLsnrClick
    local CG = ComTool.Get
    local tip = "天赋"
    UC(root, "Btn/reAllPoint", name, self.reAllPoint, self)
    UC(root, "Btn/tip", name, self.tipShow, self)
    UC(root, "Btn/AddPoint", name, self.AddPoint, self)
    self.pointNumtxt=CG(UILabel,root,"Btn/AddPoint/pointnum")
    local  skillBtnRoot =  TF(self.root, "Btn/skillbtn")
    self.skillBtnRoot=skillBtnRoot
    local siRoot = TF(root,"SkillInfo")
    InnateSkillInfo:Init(siRoot)
    self.item=TFC(skillBtnRoot,"item");
    soonTool.setPerfab(self.item,"InnateItem")
    for i=1,15 do
        local pos = TF( skillBtnRoot ,tostring(i));
        local obj = ObjPool.Get(InnateItem);
        local go = soonTool.Get("InnateItem")
        obj:Init(go.transform,pos,i);
        My.SklLst[i]=obj;
    end
    self.tbRoot=TF(root,"Btn/tb");
    self.tbLst={}
    for i=1,3 do
        local obj = {}
        obj.selcet = TFC(self.tbRoot,i.."/selcet",tip);
        obj.lock = TFC(self.tbRoot,i.."/lock",tip);
        obj.red = TFC(self.tbRoot,i.."/red",tip);
        self.tbLst[i]=obj
        UC(self.tbRoot,tostring(i), name, self.tbOnclick, self)
    end
    self.lineRoot= TF(root,"line");
    self.treeRoot=TF(root,"tree");
    InnateTree:Init(self.treeRoot);
    self.ismybuy=false 
end

function My:doTbmsg( )
    for i=1,3 do
       local info =  self.tbLst[i]
       info.red:SetActive(InnateMgr.tbRed[i])
       local lock= InnateMgr.tbUnLock(i)
       info.lock:SetActive(not lock)
    end
end

--监听
function My:lnsr( fun )
    StoreMgr.eBuyResp[fun](StoreMgr.eBuyResp,self.BuySucc,self);
    InnateMgr.eUp[fun](InnateMgr.eUp,self.lvUpSuc,self)
    InnateMgr.eInnate[fun](InnateMgr.eInnate,self.reAll,self)
    InnateMgr.ePoint[fun](InnateMgr.ePoint,self.PointChange,self)
    InnateMgr.eRed[fun](InnateMgr.eRed,self.doTbmsg,self)
    InnateTree.eSelct[fun](InnateTree.eSelct,self.UpdataTree,self)
end

--刷新树显示
function My:UpdataTree( tree )
    My.tree=tree;
    self.IntSkillLst = InnateMgr.SkillList
    -- My.selectIndex=0
    local nodelst = self.IntSkillLst[tree]
    local len = #nodelst
    if len~=#My.SklLst then
      iTrace.eError("soon","有漏掉数据或多数据天赋"..tree)
      return
    end
    for i=1,len do
        local info = nodelst[i]
        local obj = My.SklLst[i]
        obj:upateInfo(info)
        if i==My.shoudSlct then
            self:chooseSkill(info)
        end
    end
    self:PointChange()
    self:SetALLLine()
    local sclttree = InnateMgr.Select[My.tb] 
    -- if sclttree==0 then
    --     My.SklLst[1]:setLock(nodelst[1] )
    -- end
    if sclttree ~=0 and sclttree~=tree then
        My.SklLst[1]:treeFalseRed()
    end
end

function My:PointChange( )
    self.pointNumtxt.text=InnateMgr.UpPoint;
    self:reAllRed(  )
end

--连接线
function My:SetALLLine(  )
    for i=1,#My.SklLst do
        self:SetOneLine(i )
    end
end
--单个
function My:SetOneLine(grp )
    local TFC = TransTool.FindChild
    local nodeLst =self.IntSkillLst[My.tree]
    local nodeInfo = nodeLst[grp]
    if nodeInfo.line~=nil then
        local ls = nodeInfo.line
        local b =  nodeInfo.lv~=0 
        for i=1,#ls do
            if b then
                b =  nodeLst[i].lv~=0 
            end
            local num = ls[i]*100+grp;
            local line = TFC(self.lineRoot,tostring(num).."/lineOpen","配置没对应上天赋预制体")
            line:SetActive(b);
        end
    end
end
--升级了
function My:lvUpSuc( msg )
    My.selectInfo=msg
    local grp = msg.grp
    My.SklLst[grp]:upateInfo(My.selectInfo)
    My.SklLst[grp]:lvSuc();
    InnateSkillInfo:Update(My.selectInfo);
    self:reAllRed(  )
    self:SetOneLine(grp )
    self:PointChange()
end
--全部红点重置
function My:reAllRed(  )
    local tree = self.IntSkillLst[My.tree]
    for i=1,#My.SklLst do
        My.SklLst[i]:setLock(tree[i]) 
    end
    self:doTbmsg( )
end
--全部重置
function My:reAll(  )
    InnateTree:SetAllInfo(My.tb)
end

function My:reAllPoint(  ) 
    if My.tb==0 then
        return
    end
    local Selecttree = InnateMgr.Select[My.tb]
    if Selecttree==0 then
      UITip.Log("当前天赋页无须重置")
      return
    end
    local info = GlobalTemp["99"].Value2
    local itemId = info[1]
    local num = info[2]
    local itemId2 =info[3]
    local num2 =info[4]
    local bagNum2= PropMgr.TypeIdByNum(itemId2);
    local StoreDatainfo2 = ItemData[tostring(itemId2)]
    local Name2 = StoreDatainfo2.name
    if bagNum2>=num2 then
        str1=string.format("是否使用%s重置天赋",Name2);
        MsgBox.ShowYesNo(str1, self.YesCb,self, "重置", self.NoCb,self, "取消")
        return
    end
    self.reitemId=itemId;
    local bagNum = PropMgr.TypeIdByNum(itemId);
    local str1 = "";
    local StoreDatainfo = ItemData[tostring(itemId)]
    local name = StoreDatainfo.name
    self.renum= bagNum-num
    if self.renum>=0 then
        str1=string.format("是否使用%s重置天赋",name);
        MsgBox.ShowYesNo(str1, self.YesCb,self, "重置", self.NoCb,self, "取消")
    else
        self.ismybuy=true
        StoreMgr.TypeIdBuy(self.reitemId,-self.renum,true);
    end
end
--点击MsgBox的确定按钮
function My:YesCb()
    InnateMgr:toRePoint(My.tb);
    return 
end
--购买成功
function My:BuySucc( )
    if self.ismybuy then
        InnateMgr:toRePoint(My.tb);
    end
    self.ismybuy=false
end

--点击MsgBox的取消按钮
function My:NoCb()
    return 
end
function My:tipShow( )
    local str=InvestDesCfg["1300"].des;
    UIComTips:Show(str, Vector3(389,-220,0),nil,nil,nil,400);
end

function My:AddPoint(  )
    UIMgr.Open(UIGetWay.Name, self.OpenGetWayCb ,self)
end

function My:OpenGetWayCb(name)
    local ui = UIMgr.Get(name)
	ui:SetPos(Vector3(452,0,0))
	local getWay = self.petGetWay
	local len = #getWay
	for i = 1,len do
		ui:CreateCell(getWay[i], self.OnClickGetWayItem, self)
	end
end

function My:OnClickGetWayItem(name)
    if name == "境界" then
        JumpMgr:InitJump(UIRole.Name,3)
        UIRobbery:OpenRobbery(1)
    elseif name == "五行幻境" then
        JumpMgr:InitJump(UIRole.Name,3)
        UIRobbery:OpenRobbery(11)
	elseif name == "未开启" then
		UITip.Error("敬请期待")
	end
end
--选中
function My:chooseSkill( info )
    -- if info.grp==My.selectIndex then
    --     return
    -- end
    if My.selectIndex~=0 then
        My.SklLst[My.selectIndex]:Slct(false);
    end
    My.selectIndex=info.grp
    My.selectInfo=info
    My.SklLst[My.selectIndex]:Slct(true);
    InnateSkillInfo:Update(info);
end

function My:tbOnclick( go,index )
    local tb =index
    if go~=nil then
        tb=tonumber(go.name)
    end
    if My.tb==tb then
       return
    end
    if InnateMgr.tbUnLock(tb) then
        if My.tb~=nil and My.tb~=0 then
            self.tbLst[My.tb].selcet:SetActive(false)
        end
        My.tb=tb
        self.tbLst[My.tb].selcet:SetActive(true)
        InnateTree:SetAllInfo(My.tb)
    else
        local point = tInnateTb[tb].need
        UITip.Log(string.format( "总点数达到%s解锁",point))
    end
end

function My:Open(tb)
    if tb==nil or tb==0 then
        tb=1
    end
    if My.SklLst==nil or #My.SklLst~=15 then
        soonTool.ObjAddList(My.SklLst);
        local TF = TransTool.Find
        for i=1,15 do
            local pos = TF(self.skillBtnRoot ,tostring(i),self.Name);
            local obj = ObjPool.Get(InnateItem);
            local go = soonTool.Get("InnateItem")
            obj:Init(go.transform,pos,i);
            My.SklLst[i]=obj;
        end
    end
    self.IntSkillLst = InnateMgr.SkillList
    self:lnsr("Add")
    self.root.gameObject:SetActive(true)
    self:tbOnclick( nil,tb )
    self:reAllRed(  )
end

function My:Close()
    self:lnsr("Remove")
    self.ismybuy =false
    if LuaTool.IsNull(self.root)  then
		return
	end
self.root.gameObject:SetActive(false)
end

function My:Dispose()
    My.shoudSlct=1;
    My.selectIndex=0;
    if My.tb~=nil and My.tb~=0 then
        self.tbLst[My.tb].selcet:SetActive(false)
    end
    My.tb=0
    My.tree=0;
    My.selectInfo=nil;
    StoreMgr.eBuyResp:Remove(self.BuySucc,self);
    soonTool.ObjAddList(My.SklLst);
    InnateTree:Dispose()
    InnateSkillInfo:Dispose();
    My.selectInfo=nil;
end
function My:Clear( )
    self:Dispose()
    InnateSkillInfo:Clear()
    InnateTree:Clear()
    soonTool.ObjAddList(My.SklLst);
    soonTool.DesGo("InnateItem")
    TableTool.ClearUserData(self)
end
return My ; 