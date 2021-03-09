soonTool = {}

local My = soonTool
-- 对象字典 键:对象名称(Name字段) 值:对象列表
My.dic = {}
My.creatDic={}
--go为gameObject
--index必须填写
function My.setPerfab(go,index )
  if go == nil then return end
  local name = index;
  if index==nil then
    return
  end
  go:SetActive(false);
  My.creatDic[name]=go;
end

--添加
--index自定义标识唯一string
--prn不把父物体设置为空,高频率刷新
function My.Add(go,index,prn)
  if go == nil then return end
  if LuaTool.IsNull(go) then return end
  local name = index;
  if index==nil then
    return
  end
  go:SetActive(false);
  local list = My.dic[name]
  if list == nil then
    list = {}
    My.dic[name] = list
  end
  -- if prn~=true then
    -- go.transform.parent=nil
  -- end
  table.insert(list, go)
end
--列表添加
function My.AddList(list,index,prn)
  if list==nil then
    return;
  end
  if #list==0 then
    return;
  end
  for k,v in pairs(list) do
    My.Add(v,index,prn);
    list[k]=nil;
  end
end

--获取,父物体当前挂载点
function My.Get(name,Parent)
  local t = nil
  local trans = nil
  local list = My.dic[name]
  if list ~= nil and #list ~= 0 then
    t = table.remove(list,#list);
  elseif not LuaTool.IsNull(My.creatDic[name]) then
      t=Instantiate(My.creatDic[name]);
      if My.creatDic[name].transform.parent~=nil then
        if Parent==nil then
          t.transform.parent=My.creatDic[name].transform.parent;
        end
      end
  end
  if t==nil then
    return t;
  end
    trans=t.transform
    if Parent~=nil then
      trans.parent=Parent.transform;
    end
    if trans.parent~=nil then
      trans.localScale = Vector3.one;
      trans.localPosition = Vector3.zero
      trans.localRotation = Vector3.zero
    end
    t:SetActive(true);
  return t;
end

--选中默认在sv之内,传入子物体身上必需有widget的组件或者传入继承UIWidget组件
function My.ChooseInScrollview( tran,sv,wg)
  if not LuaTool.IsNull(tran) and not LuaTool.IsNull(sv)  then
    local weigt = wg
    if weigt==nil then
      weigt=ComTool.GetSelf(UIWidget,tran,"soon")
    end
    local panel= sv.panel
    if panel==nil  then
      panel=ComTool.GetSelf(UIPanel,sv.transform,"soon")
      if panel==nil then
        return
      end
    end
    local cornerslst= panel.worldCorners;
    local panelTrans = panel.cachedTransform;
    local itemtran= weigt.worldCorners;
    local svdown = panelTrans:InverseTransformPoint(cornerslst[0]);
    local itdown = panelTrans:InverseTransformPoint(itemtran[0]);
    local svup = panelTrans:InverseTransformPoint(cornerslst[2]);
    local itup = panelTrans:InverseTransformPoint(itemtran[2]);
    local localOffset = nil
    if itdown.y<svdown.y or itdown.x<svdown.x then    
      localOffset =itdown -svdown  
      if (sv.canMoveHorizontally) then
        localOffset.y = 0;
      end
      if (sv.canMoveVertically) then
        localOffset.x = 0;
      end
    elseif itup.y > svup.y or itup.x > svup.x  then
      localOffset = itup -svup
      if (sv.canMoveHorizontally) then
        localOffset.y = 0;
      end
      if (sv.canMoveVertically) then
        localOffset.x = 0;
      end
    end
    if localOffset~=nil then
      localOffset.z = 0;
      co = panel.clipOffset;
      co.x =co.x +localOffset.x
      co.y =co.y+ localOffset.y;
      panel.clipOffset = co;
      panelTrans.localPosition = panelTrans.localPosition - localOffset;
    end
  end
end
--滑动到中间
function My.ChooseInScrollviewCenter( tran,sv,wg)
  if not LuaTool.IsNull(tran) and not LuaTool.IsNull(sv)  then
    local weigt = wg
    if weigt==nil then
      weigt=ComTool.GetSelf(UIWidget,tran,"soon")
    end
    local panel= sv.panel
    if panel==nil  then
      panel=ComTool.GetSelf(UIPanel,sv.transform,"soon")
      if panel==nil then
        return
      end
    end
    local cornerslst= panel.worldCorners;
    local panelCenter = (cornerslst[2] + cornerslst[0]) * 0.5;
    local panelTrans = panel.cachedTransform;
    local itemtran= weigt.worldCorners;
    local cp = panelTrans:InverseTransformPoint(tran.position);
    local cc = panelTrans:InverseTransformPoint(panelCenter);
    local localOffset = cp - cc;
      localOffset.z = 0;
      co = panel.clipOffset;
      co.x =co.x +localOffset.x
      co.y =co.y+ localOffset.y;
      panel.clipOffset = co;
      panelTrans.localPosition = panelTrans.localPosition - localOffset;
  end
end
--释放资源
function My.DesAndUnload(name)
    local list = My.dic[name];
    if list==nil then
        return;
    end
    My.desLst( list,true)
end
--释放预制体,true时候unload且销毁一个
function My.DesGo(name,bool)
  local list = My.dic[name];
  if bool then
    My.desOne(My.creatDic[name],bool);
  end
  My.creatDic[name]=nil;
  if list==nil then
      return;
  end
    My.desLst(list)
end
--释放预制体,true时候unload且销毁所有储存预制体
function My.DesGounLoadAll(name,bool)
  local list = My.dic[name];
  if bool then
    My.desOne(My.creatDic[name],bool);
  end
  My.creatDic[name]=nil;
  if list==nil then
      return;
  end
    My.desLst(list,bool)
end
--预制体释放true时候unload
function My.desLst(list,bool)
  for k,v in pairs(list) do
    My.desOne(v,bool);
    list[k]=nil;
  end
  -- local len = #list;
  -- for i=len,1,-1 do
  --     t = table.remove(list,i);
  --     My.desOne(t,bool);
  -- end
end
-- 单个释放
function My.desOne(t,bool)
  if LuaTool.IsNull(t)  then
    return
  end
  if bool then
    AssetMgr:Unload(t.name, ".prefab", false)
  end
  GameObject.DestroyImmediate(t);
end

--释放
function My.Dispose()
  for k, v in pairs(My.dic) do
    while #v > 0 do
      table.remove(v)
    end
  end
  for k, v in pairs(My.creatDic) do
    while #v > 0 do
      table.remove(v)
    end
  end
end
--格子grid传入UIGrid
function My.AddCell(grid,list,id,num,sf,isEff)
  local cell = ObjPool.Get(UIItemCell)
  cell:InitLoadPool(grid.transform,sf)
  cell:UpData(id,num,isEff)
  table.insert(list, cell)
end
--清空格子列表
function My.desCell(list )
  if list==nil or #list==0 then
    return;
  end
  local len  = #list
  for i=len,1,-1 do
    local ds= list[i]
    ds:DestroyGo()
    ObjPool.Add(ds)
    list[i]=nil
 end
end
--标准结构加格子UIGrid
function My.AddItemCell(item,grid,list,sf )
  for i=1,#item do
    local info =item[i];
    My.AddCell(grid,list,info.id,info.num,sf);
  end
  grid:Reposition();
end
--k_v结构加格子UIGrid
function My.AddkvCell(item,grid,list,sf )
  for i=1,#item do
    local info =item[i];
    My.AddCell(grid,list,info.k,info.v,sf);
  end
  grid:Reposition();
end
--无结构加格子UIGrid
function My.AddNoneCell(item,grid,list,sf )
  for i=1,#item do
    local info =item[i];
    My.AddCell(grid,list,info,sf);
  end
  grid:Reposition();
end
--格子返回单个
function My.AddOneCell(transform,id,num,sf,isEff)
  local cell = ObjPool.Get(UIItemCell)
  cell:InitLoadPool(transform,sf)
  cell:UpData(id,num,isEff)
  return cell;
end
function My.desOneCell(ds)
  if LuaTool.IsNull(ds) then
    return
  end
    ds:DestroyGo()
    ObjPool.Add(ds)
    ds=nil
end
--清空列表
function My.ClearList( list )
  if list==nil then
    return
  end
  for k,v in pairs(list) do
    list[k]=nil;
  end
end
--列表往obj放对象
function My.ObjAddList( list )
  if list==nil then
    return;
  end
  for k,v in pairs(list) do
    ObjPool.Add(v);
    list[k]=nil;
  end
end

function My.GetVipInfo( lv )
    return VIPMgr.GetVIPInfo(lv)
  --  return BinTool.Find(VIPLv,lv,"lv") 
end

--算vip下次改变
--subscript下标string
--nowvip当前vip
--当nextTimes==0无更高的
function My.FindNextNum(subscript, nowvip )
  local Nowinfo = soonTool.GetVipInfo(nowvip)
  local NowNum=Nowinfo[subscript]
  local next = nowvip + 1
  local len = #VIPLv
  local nextTimes = 0
  for i=1,len do
      local nextInfo = soonTool.GetVipInfo(next)
      if nextInfo==nil then
        break;
      end
      if nextInfo[subscript]>NowNum then
          nextTimes=nextInfo[subscript]
          break
      end
      next=next+1
  end
  return nextTimes,next
end

return My;
