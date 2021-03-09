--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-09-21 19:05:16
-- 属性列表模块,具有标题;当前值;下阶值
-- 需要传入:
-- names:属性字段名列表;
-- GetCfg方法:返回当前阶配置&下一阶配置;
-- srcObj:方法所在源
--==============================================================================

local UPI = require("UI/Cmn/UIPropsItem")
UIProps = Super:New{Name = "UIProps"}

local My = UIProps


function My:Ctor()
  --字典 k:熟悉名,v:UIPropsItem
  self.dic = {}
end

function My:Init()
  local des = self.Name
  local root = self.root
  self.gbj = root.gameObject

  local CG = ComTool.Get
  local UL = UILabel
  local itWdg = CG(UIWidget, root, "item", des)
  self.itHt = itWdg.height
  self.item = itWdg.gameObject
  self.item:SetActive(false)

  local tblWdg = ComTool.GetSelf(UIWidget, root, des)
  self.tblHt = tblWdg.height
  --UI表
  self.uiTbl = CG(UITable, root, "Table", des)
  -- --标题当前标签
  -- self.cStLbl = CG(UL, root, "step/cur", des)
  -- --标题下阶标签
  -- self.nStLbl = CG(UL, root, "step/next", des)
  -- self.cStLbl.text = ""
  -- self.nStLbl.text = ""
  self:Open()
end

--清除字典
function My:ClearDic()
  local dic, root = self.dic, self.root
  for k, v in pairs(dic) do
    dic[k] = nil
    v.root.parent = root
    v.go.name = "none"
    v.go:SetActive(false)
    ObjPool.Add(v)
  end
end

--设置字典
function My:SetDic()
  local names = self.names
  local PG = PropTool.GetName
  local dic, root = self.dic, self.root
  local Inst = GameObject.Instantiate
  local item = self.item
  local uiTbl = self.uiTbl
  local p = uiTbl.transform
  local TA = TransTool.AddChild
  local it, go, c = nil, nil, nil
  for i, v in ipairs(names) do
    it = ObjPool.Get(UPI)
    local c = root:Find("none")
    if c then
      go = c.gameObject
    else
      go = Inst(item)
      c = go.transform
      go.name = "none"
    end
    go:SetActive(true)
    it.root = c
    TA(p, c)
    it:Init()
    local pn = PG(v)
    it:SetName(pn)
    dic[v] = it
  end
  local count = #names
  local remain = self.tblHt - self.itHt * (count)
  local y = math.ceil(remain / count / 2)
  local padding = uiTbl.padding
  padding.y = y
  uiTbl.padding = padding
  uiTbl:Reposition()
end

--设置属性名称列表
function My:SetNames(names)
  if names == nil then return end
  if names == self.names then return end
  self.names = names
  self:ClearDic()
  self:SetDic()
end


--更新属性
--显示当前属性和下级/阶属性
--add:true时 下级属性显示增加值
function My:Refresh(add)
  if type(self.GetCfg) ~= "function" then return end
  --if type(self.GetTitle) ~= "function" then return end
  if add == nil then add = true end
  local cCfg, nCfg = self.GetCfg(self.srcObj)
  -- self.cStLbl.text = self.GetTitle(cCfg)
  -- self.nStLbl.text = self.GetTitle(nCfg)
  self:UpdateProp(cCfg, nCfg, add)
end


--更新属性
--cCfg(当前配置)
--nCfg(下阶配置)
--显示递增属性
function My:UpdateProp(cCfg, nCfg, add)
  local names = self.names
  if names == nil then return end
  if add == nil then add = true end
  local dic = self.dic
  local cur, next, curStr, nextStr = nil
  local GetValByNLua = PropTool.GetValByNLua
  for i, v in ipairs(names) do
    local it = dic[v]
    if it then
      cur = cCfg and cCfg[v] or 0
      next = nCfg and nCfg[v] or 0
      if add then
        next = next - cur
      end
      curStr = GetValByNLua(v, cur)
      nextStr = GetValByNLua(v, next)
      it:SetCur(curStr)
      it:SetNext(nextStr)
    end
  end
end


--打开
function My:Open()
  self.gbj:SetActive(true)
  self.active = true
end

--关闭
function My:Close()
  self.gbj:SetActive(false)
  self.active = false
end

function My:Dispose()
  self.names = nil
  self.srcObj = nil
  self.GetCfg = nil
  TableTool.ClearDicToPool(self.dic)
end

return My
