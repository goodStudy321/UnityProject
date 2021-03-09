--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-07-14 16:37:08
-- 养成界面属性,根据丹药使用数量进行属性的叠加,需要传入以下字段
-- quaDic:使用字典
-- quaCfg:丹药配置,若有百分比提升,只会对所有固定值属性加成
--=========================================================================

UIAdvProp = UIProps:New{Name = "UIAdvProp"}

local My, base = UIAdvProp, UIProps

function My:Ctor()
  base.Ctor(self)
  --k:Lua属性名,属性值
  self.qPropDic = {}

  --k:lua字段名,百分比
  self.percent = 0
end

function My:Init()
  base.Init(self)
  self:AddLsnr()
end

--设置丹药

function My:SetQual()
  local quaDic = self.quaDic
  local quaCfg = self.quaCfg
  if quaDic == nil then return end
  if quaCfg == nil then return end
  local qPropDic = self.qPropDic
  local idK, pK, pCfg = nil, nil, nil
  local BF, val, used = BinTool.Find, 0, 0
  self.percent = 0
  for k, v in pairs(qPropDic) do
    qPropDic[k] = 0
  end
  for i, v in ipairs(quaCfg) do
    idK = tostring(v.id)
    used = quaDic[idK] or 0
    for i, v in ipairs(v.props) do
      pCfg = BF(PropName, v.k)
      if pCfg and pCfg.nLua then
        pk = pCfg.nLua
        if pCfg.show == 0 then
          val = qPropDic[pk] or 0
          val = val + used * v.v
          qPropDic[pk] = val
        else
          val = self.percent
          val = val + used * v.v * 0.0001
          self.percent = val
        end
      end
    end
  end
end

function My:UpdateProp(cCfg, nCfg, add)
  local names = self.names
  if names == nil then return end
  self:SetQual()
  if add == nil then add = true end
  local dic, qPropDic = self.dic, self.qPropDic
  local cur, next, curStr, nextStr, qp = nil
  local GetValByNLua = PropTool.GetValByNLua
  for i, v in ipairs(names) do
    local it = dic[v]
    if it then
      local at = true
      if i % 2 == 0 then
        at = false
      end
      cur = cCfg and cCfg[v] or 0
      next = nCfg and nCfg[v] or 0
      if add then
        next = next - cur
      end
      qp = qPropDic[v] or 0
      cur = cur + qp

      cur = cur * (1 + self.percent)
      cur = math.floor(cur)
      curStr = GetValByNLua(v, cur)
      nextStr = GetValByNLua(v, next)
      it:SetCur(curStr)
      it:SetNext(nextStr)
      it:SetBgShow(at)
    end
  end
end

function My:AddLsnr()
  PropMgr.eUpdate:Add(self.Refresh, self)
end

function My:RmvLsnr()
  PropMgr.eUpdate:Remove(self.Refresh, self)
end

--更新显示
function My:UpShow(state)
  self.root.gameObject:SetActive(state)
end

function My:Dispose()
  self:RmvLsnr()
  base.Dispose(self)
  self.quaCfg = nil
  self.quaDic = nil
  TableTool.ClearDic(self.qPropDic)
end


return My
