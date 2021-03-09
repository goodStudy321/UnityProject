
InnateTree=Super:New{Name="InnateTree"}
local My=InnateTree
--当前页签
My.tb=0;
-- --选中的树
-- My.curtree=0;
--选中的下标
My.curIndex=0

My.curTreeLst={}
--子类合集
My.objLst={}

--选中事件
 My.eSelct=Event()

function My:Init( root)
    local tip = InnateTree.Name
    self.root=root
    local TF = TransTool.Find
	local TFC = TransTool.FindChild
	local UC = UITool.SetLsnrClick
    local CG = ComTool.Get
    UC(root, "UPTree", tip, self.UPTreeClick, self)
    UC(root, "DownTree", tip, self.DownTreeClick, self)
    self.sv=CG(UIScrollView,root,"sv",tip);
    self.grid = CG(UIGrid,root,"sv/Grid",tip);
    self.treeItem=TFC(self.grid.transform,"treeItem",tip);
    soonTool.setPerfab(self.treeItem,"InnateTreeItem")
end
--切换调用
function My:SetAllInfo(tb )
    self:clearMsg()
    My.tb=tb==0 and 1 or tb;
    self:findCurLst( My.tb )
    self:CreateBtn( My.tb )
end

function My:UPTreeClick(  )
    local index = My.curIndex -1
    if index==0 then
        index=#My.objLst
    end
    self:Selcet(index)
end
function My:DownTreeClick(  )
    local index = My.curIndex +1
    if index>#My.objLst then
        index=1
    end
    self:Selcet(index)
end

function My:Selcet(index )
    if index== My.curIndex then 
        return;
    end
    local obj =  My.objLst[index]
    if obj==nil then
        obj=My.objLst[1]
        iTrace.eError("soon","超出范围index="..index)
    end
    if My.curIndex~=0 then
        My.objLst[My.curIndex]:onSelcet(false)
    end
    My.curIndex=index
    obj:onSelcet(true)
    soonTool.ChooseInScrollview(obj.root,self.sv)
    My.eSelct(obj.tree)
end

function My:Getlist( )
    local tblst={}
    for i=1,#tInnateTb do
        local lst =tInnateTb[i].tree
        local trees = {}
        for k=1,#lst do
            trees[k]=lst[k]
        end
        tblst[i]=trees
     end
     return tblst
end

function My:findCurLst( tb )
    local lst =self:Getlist(  )
    My.curTreeLst=lst[tb]
    local Select = InnateMgr.Select
    for i=1,#Select do
        if i~=tb then
            local remove = Select[i]
            if remove~=0 then      
                for k=1,# My.curTreeLst do
                  if My.curTreeLst[k]==remove then
                    table.remove(My.curTreeLst, k)
                    break;
                  end
                end
            end
        end
    end
end

function My:CreateBtn( tb )
    local Selecttree = InnateMgr.Select[tb]
    local soonGet = soonTool.Get;
    local change = 0
    for i=1,#My.curTreeLst do
        local go =  soonGet("InnateTreeItem")
        local tree = My.curTreeLst[i]
        local obj = ObjPool.Get(InnateTreeItem)
        local name = i
        if Selecttree==tree then
          name=0;
          change=i
        end
        obj:Init(go,tree,name,i)
        My.objLst[i]=obj
    end
    if change~=0 and change~=1 then
      local t = table.remove( My.objLst,change )
      table.insert(  My.objLst, 1,t )
      for i=1, #My.objLst do
        My.objLst[i]:setIndex( i )
      end
    end
    self.grid:Reposition()
    self.sv:ResetPosition()	
    My.objLst[1]:OnClock(  )
end

function My:clearMsg()
    My.curIndex=0
    soonTool.ClearList(My.curTreeLst)
    soonTool.ObjAddList(My.objLst)
end

function My:Dispose(  )
    self:clearMsg()
end

function My:Clear(  )
    self:Dispose(  )
    soonTool.DesGo("InnateTreeItem")
    TableTool.ClearUserData(self)
end

return My;