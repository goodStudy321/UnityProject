--[[
 	author 	    :Loong
 	date    	:2018-02-05 19:23:15
 	descrition 	:引导条件基础类型
--]]

GuideCond = Super:New{Name = "GuideCond"}

local My = GuideCond


function My:Ctor()
  --成功触发事件
  --k:引导触发参数的字符串,v:引导cfg
  self.dic = {}
  self.success = Event()
end

function My:Init()

end

function My:Trigger(k, cfg)
  if cfg == nil then return end
  self.dic[k] = nil
  self.success(self, cfg)
end

function My:TriggerArg(arg)
  local k = tostring(arg)
  local cfg = self.dic[k]
  self:Trigger(k, cfg)
end

--设置配置
function My:SetCfg(cfg)
  local k = tostring(cfg.tArg)
  local tmp = self.dic[k]
  if tmp ~= nil then
    iTrace.Error("Loong", "引导ID:", cfg.id, "与", tmp.id, "的触发条件相同")
  end
  self.dic[k] = cfg
end

function My:TriggerByCfg(cfg)
   local k = tostring(cfg.tArg)
   self:Trigger(k, cfg)
end

function My:Clear()
  TableTool.ClearDic(self.dic)
end

function My:Dispose()
  self:Clear()
  self.success:Dispose()
end
