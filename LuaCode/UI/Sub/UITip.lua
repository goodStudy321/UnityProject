--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-04-26 11:25:07
-- 通用Tips
--==============================================================================


UITip = {Name = "UITip"}

local UTI = require("UI/Sub/UITipItem")
local My = UITip

--可用条目列表(UITipItem)
My.items = {}

function My.Init()
  if My.Loading then return end
  My.Loading = true
  local cb = GbjHandler(My.LoadCb)
  Loong.Game.AssetMgr.LoadPrefab(My.Name, cb)
end

function My.LoadCb(go)
  local des = My.Name
  local root = go.transform
  My.root = root
  My.none = TransTool.Find(root, "None", des)
  My.model = TransTool.FindChild(root, "item", des)
  My.uiGrid = ComTool.Get(UIGrid, root, "Grid", "")
  My.grid = My.uiGrid.transform
  My.panel=My.root:GetComponent(typeof(UIPanel))
  TransTool.AddChild(UIMgr.HCam.transform, root)
  AssetMgr:SetPersist(My.Name, ".prefab",true)
end

--如果有MsgBox设置的比MsgBox高
function My.SetDepth()
  local ui = UIMgr.Get(MsgBox.Name)
  if ui then
    local uiDepth = ui.root:GetComponent(typeof(UIPanel)).depth
    My.panel.depth=uiDepth+1
  end
end

--发射消息
--msg(string):消息内容
--color(string):颜色编码
function My.Launch(msg, color,time)
  if My.model == nil then return end
  My.SetDepth()
  local item = nil
  local items = My.items
  if #items > 0 then
    item = table.remove(items)
  else
    item = ObjPool.Get(UTI)
    local go = Instantiate(My.model)
    item:Init(go)
  end
  if color then
    local sb = ObjPool.Get(StrBuffer)
    sb:Apd(color):Apd(msg):Apd("[-]")
    msg = sb:ToStr()
    ObjPool.Add(sb)
  end
  item:Launch(msg,time)
  My.uiGrid:Reposition()
end

--编辑器内发射消息
function My.eLaunch(msg, color)
  if App.isEditor then
    msg = "编辑器:" .. msg
    My.Launch(msg, color)
  end
end

--添加消息条目
function My.Add(it)
  if it == nil then return end
  local tran = it.root
  tran.parent = My.none
  tran.localPosition = Vector3.zero
  it:SetActive(false)
  My.items[#My.items + 1] = it
end

--普通输出
function My.Log(msg,time)
  My.Launch(msg,nil,time)
end

--警告输出
function My.Warning(msg)
  My.Launch(msg, "[EE9572]")
end

--错误输出
function My.Error(msg)
  My.Launch(msg, "[EE0000]")
end

--编辑器内普通输出
function My.eLog(msg)
  My.eLaunch(msg)
end

--编辑器内警告输出
function My.eWarning(msg)
  My.eLaunch(msg, "[EE9572]")
end

--编辑器内错误输出
function My.eError(msg)
  My.eLaunch(msg, "[EE0000]")
end

return My
