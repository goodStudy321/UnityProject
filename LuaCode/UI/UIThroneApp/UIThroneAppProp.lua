UIThroneAppProp = UIProps:New{Name = "UIThroneAppProp"}

local My, base = UIThroneAppProp, UIProps

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

function My:UpdateProp(cCfg, nCfg, add)
  local names = self.names
  if names == nil then return end
  if add == nil then add = true end
  local dic, qPropDic = self.dic, self.qPropDic
  local cur, next, curStr, nextStr, qp = nil
  local GetValByNLua = PropTool.GetValByNLua
  for i, v in ipairs(names) do
    local it = dic[v]
    if it then
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
    end
  end
end

function My:AddLsnr()
  PropMgr.eUpdate:Add(self.Refresh, self)
end

function My:RmvLsnr()
  PropMgr.eUpdate:Remove(self.Refresh, self)
end

function My:Dispose()
  self:RmvLsnr()
  base.Dispose(self)
  self.quaCfg = nil
  self.quaDic = nil
  TableTool.ClearDic(self.qPropDic)
end


return My
