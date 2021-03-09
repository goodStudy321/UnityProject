--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-09-08 15:23:52
-- UI工具
--==============================================================================

UITool = {Name = "UITool"}
local My = UITool
local EdCb = EventDelegate.Callback
local UV = UIEventListener.VoidDelegate


--设置UI游戏对象灰色(不包含子对象和标签)
--go(gameObject)
function My.SetGray(go, canClick)
  local wdg = go:GetComponent(typeof(UIWidget))
  local box = go:GetComponent(typeof(BoxCollider))
  if box then
     box.enabled = canClick or false 
  end
  if wdg == nil then return end
  local color = wdg.color
  color.r = 0
  wdg.color = color
end

--设置UI游戏对象灰色(包含子对象和标签)
--go(gameObject)
function My.SetAllGray(go, canClick)
  local wdg = go:GetComponentsInChildren(typeof(UIWidget), true)
  local box = go:GetComponentsInChildren(typeof(BoxCollider), true)
  if box then
    local len = box.Length - 1
    for i = 0, len do
      box[i].enabled = canClick or false
    end
  end
  if wdg == nil then return end
  local len = wdg.Length - 1
  for i = 0, len do
    local color = wdg[i].color
    color.r = 0
    wdg[i].color = color
  end
end

--设置UI游戏对象(不包含子对象)
--go(gameObject)
function My.SetNormal(go)
  local wdg = go:GetComponent(typeof(UIWidget))
  local box = go:GetComponent(typeof(BoxCollider))
  if box then box.enabled = true end
  if wdg == nil then return end
  local color = wdg.color
  color.r = 1
  wdg.color = color
end

--设置UI游戏对象(包含子对象)
--go(gameObject)
function My.SetAllNormal(go)
  local wdg = go:GetComponentsInChildren(typeof(UIWidget), true);
  local box = go:GetComponentsInChildren(typeof(BoxCollider), true);
  if box then
    local len = box.Length - 1
    for i = 0, len do
      box[i].enabled = true
    end
  end
  if wdg == nil then return end
  local len = wdg.Length - 1
  for i = 0, len do
    local color = wdg[i].color
    color.r = 1
    wdg[i].color = color
  end
end

--对target下的所有UIPanel进行排序
--target(Transform or GameObject)
--depth(number) 层级
--factor(number) 系数
function My.Sort(target, depth, factor)
  ---[[
  if target == nil then return end
  depth = depth or 1
  factor = factor or 10
  local tp = typeof(UIPanel)
  local panels = target:GetComponentsInChildren(tp, true)
  if panels == nil then return end
  local t1={}
    local len = panels.Length - 1
  for i = 0, len do
    t1[#t1+1] = panels[i]
  end

  table.sort(t1,My.SortFunc)

  local begDepth = depth * factor
  for i , k in ipairs(t1) do
    k.depth = begDepth + i
  end
  --]]
end

function My.SortFunc(a, b)
  return a.depth < b.depth
end

--获取最大层级的UIpanel
--target(Transform or GameObject)
function My.GetMaxDepth(target)
  local tp = typeof(UIPanel)
  local panels = target:GetComponentsInChildren(tp, true)
  if (panels == nil) then return nil end
  local maxPanel = nil
  local depth = -1
  local len = panels.Length - 1
  for i = 0, len do
    local pl = panels[i];
    if pl.depth > depth then
      depth = pl.depth
      maxPanel = pl
    elseif maxPanel == nil then
      maxPanel = pl
    end
  end
  return maxPanel
end

--创建遮挡
--ty:类型
--parent(Transform):父变换
--name(string):遮挡名称
--depth(number):深度
function My.CreateMask(ty, parent, name, depth)
  if (ty == nil) then return nil end
  name = name or "mask"
  local go = GameObject.New(name);
  go.layer = 5
  go.transform.parent = parent
  local boxTy = typeof(BoxCollider)
  local box = go:AddComponent(boxTy)
  local rty = typeof(ty)
  if rty == nil then return end
  local com = go:AddComponent(rty)
  if (com ~= nil) then
    com.depth = depth;
    com.autoResizeBoxCollider = true
    com.transform.localScale = Vector3.one
    com.transform.localPosition = Vector3.zero
    com:SetAnchor(parent.gameObject)
    My.SetBoxSize(com, box)
  end
  return com;
end

--计算挂件碰撞大小
function My.SetBoxSize(widght, box)
  if widght == nil then return end
  if box == nil then
    local boxTy = typeof(BoxCollider)
    box = widght.gameObject:GetComponent(boxTy)
    if box == nil then return end
  end
  local dr = widght.localSize
  local size = Vector3.New(dr.x, dr.y, 0)
  box.size = size
end

--设置贴图
--root(Transform or GameObject) 根结点
--path(stirng):路径
--tex:贴图
--tip:提示
function My.SetTex(root, path, tex, tip)
  local uiTex = ComTool.Get(UITexture, root, path, tip, false)
  if uiTex == nil then return end
  uiTex.mainTexture = tex
end

--检查方法有效性
function My.CheckFunc(func, com, tip)
  com = com or ""
  tip = tip or ""
  if type(func) ~= "function" then
    iTrace.Error("Loong", com, " must set function ", tip, ", but is ", type(func))
    return false
  end
  return true
end

--设置滑动(ScrollView)事件
--root(Transform or GameObject) 根结点
--path(stirng):路径
--tip(string):提示
--musicId(number):播放音效Id
function My.SetScrollViewMusic(root, path, tip, musicId)
  local scroll = ComTool.Get(UIScrollView, root, path, tip, true)
  scroll.onMomentumMove = function()
    Audio:PlayByID(musicId, 1)
  end
end

--设置按钮(UIButton)事件
--root(Transform or GameObject) 根结点
--path(stirng):路径
--tip(string):提示
--func(function):注册方法
--self(table):对象
function My.SetBtnClick(root, path, tip, func, self, isScale)
  if not My.CheckFunc(func, "UIButton", tip) then return end
  local btn = ComTool.Get(UIButton, root, path, tip, true)
  local cb = ((type(self) == "table") and EdCb(func, self) or EdCb(func))
  My.AddBtnScale(btn.gameObject, isScale)
  EventDelegate.Set(btn.onClick, cb)
end


--设置按钮(UIButton)事件
--target(Transform or GameObject)
--func(function):注册方法
--self(table):对象
function My.SetBtnSelf(target, func, self, tip, isScale)
  if not My.CheckFunc(func, "UIButton", tip) then return end
  local btn = ComTool.Add(target, UIButton)
  local cb = ((type(self) == "table") and EdCb(func, self) or EdCb(func))
  My.AddBtnScale(target, isScale)
  EventDelegate.Set(btn.onClick, cb)
end

--设置(UIEventListener)点击事件
function My.SetLsnrClick(root, path, tip, func, self, isScale)
  if not My.CheckFunc(func, "UIEventListener", tip) then return end
  local lsnr = ComTool.Get(UIEventListener, root, path, tip, true)
  local cb = ((type(self) == "table") and UV(func, self) or UV(func))
  My.AddBtnScale(lsnr.gameObject, isScale)
  lsnr.onClick = cb
end

--设置(UIEventListener)点击事件
function My.SetLsnrSelf(target, func, self, tip, isScale)
  if not My.CheckFunc(func, "UIEventListener", tip) then return end
  local lsnr = ComTool.Add(target, UIEventListener)
  local cb = ((type(self) == "table") and UV(func, self) or UV(func))
  My.AddBtnScale(target, isScale)
  lsnr.onClick = cb
end

--isScale == false 不挂载
function My.AddBtnScale(target, isScale)
  if isScale == nil then isScale = true end
  if isScale == false then return end
  local scale = ComTool.Add(target, UIButtonScale)
  if scale then
    scale.hover = Vector3.one
    scale.pressed = Vector3.one * 1.1
  end
end

--通过UI组件的相对屏幕位置设置3D模型的相对位置
--uiTran(Transform):UI锚点的变换组件
--modCam(Camera):模型相机
--modTran(Transform):模型变换组件
--setY(boolean):默认false,true:设置Y轴
function My.SetModPos(uiTran, modCam, modTran, setY)
  if (uiTran == nil) then return end
  if (modCam == nil)then return end
  if (modTran == nil) then return end
  if (setY == nil) then setY = false end
  local sPos = UIMgr.HCam:WorldToScreenPoint(uiTran)
  local tPos = modCam:ScreenToWorldPoint(sPos)
  local modPos = modTran.position
  tPos.z = modPos.z
  if setY == false then
    tPos.y = modPos.y
  end
  uiTran.position = tPos
end


--根据是否刘海屏设置指定Widget的锚点
--root(Transform):父变换
--path(string):需要修改锚点的路径
--des(string):提示
--containLeft(boolean):true可以设置左侧的锚点
function My.SetLiuHaiAnchor(root, path, des, containLeft, reset)
  if not reset then reset = false end
  if DeviceEx.isLiuHai == true then
    local trwd = nil
    if StrTool.IsNullOrEmpty(path) == false then
      trwd = ComTool.Get(UIWidget, root, path, des)
    else
      trwd = root.gameObject:GetComponent("UIWidget")
    end
    if trwd == nil then return end
    local value = DeviceEx.liuHaiWd
    if reset == true then
      value = value * -1
    end
    local rc = trwd.rightAnchor
    rc.absolute = rc.absolute + value
    if containLeft == true then
      local lc = trwd.leftAnchor
      lc.absolute = lc.absolute + value
    end
    trwd:UpdateAnchors()
  end
end

--根据算法刘海屏锚点绝对值
--widget(UIWidget/UISprite/UITexture etc)
--containLeft(bool):true可以设置左侧的锚点
--reset(bool):true重置
--oriLeft(number):左侧锚点初始值
--oriRight(number):右侧锚点初始值
--neg(number):1:左侧移动,-1右侧移动
function My.SetLiuHaiAbsolute(widget, containLeft, reset, oriLeft, oriRight, neg)
  if DeviceEx.isLiuHai ~=true then return end
  if LuaTool.IsNull(widget) then return end
  local lc = widget.leftAnchor
  local rc = widget.rightAnchor
  oriLeft = oriLeft or lc.absolute
  oriRight = oriRight or rc.absolute
  neg = neg or 1
  local wd = ((reset == true) and 0 or DeviceEx.liuHaiWd)
  wd = wd * neg
  rc.absolute = oriRight + wd
  if containLeft then
    lc.absolute = oriLeft + wd
  end
  widget:UpdateAnchors()
end

function My.IsResetOrient(orient)
  do return (orient == ScreenOrient.Right) end
end


--卸载图片
--uiTex(UITexture)
function My.UnloadTex(uiTex)
  if uiTex == nil then return end
  local tex = uiTex.mainTexture
  if tex then Destroy(tex) end
end
