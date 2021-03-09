--[[
 	author 	    :Loong
 	date    	:2018-02-05 19:22:12
 	descrition 	:引导条件工厂
--]]

require("Guide/GuideCond")

GuideCondFty = {Name = "GuideCondFty"}

local My = GuideCondFty

--k:配置中ty的字符串 v:GuideCond的子类型
My.dic = {}

--sucFunc(function):成功方法
function My.Init(sucFunc)
  for k, v in pairs(My.dic) do
    v:Init()
    v.success:Add(sucFunc)
  end
end

--添加条件
--cfg:条件类型
--path:模块路径
function My.Add(ty, path)
  local cond = require(path)
  if cond then
    local k = tostring(ty)
    My.dic[k] = cond
  else
    iTrace.Error("Loong", "引导条件未返回模块:", path)
  end
end

function My.SetCfg(cfg)
  local k = tostring(cfg.ty)
  local cond = My.dic[k]
  if cond then
    cond:SetCfg(cfg)
  end
end

function My.Clear()
  for k, v in pairs(My.dic) do
    v:Clear()
  end
end

local Add = My.Add
Add(0, "Guide/GuideLinkCond")
Add(1, "Guide/GuideMssnCond")
Add(2, "Guide/GuideLvCond")
Add(3, "Guide/GuideSysOpenCond")
Add(4, "Guide/GuideFirstTowerOutCond")
Add(5, "Guide/GuideEquipCopyCond")
Add(6, "Guide/GuideHpCond")
Add(7, "Guide/GuideBossCopyFirstHit")
Add(8, "Guide/GuideFirstOpenUI")
Add(9, "Guide/GuideDailyTaskCond")


--创建引导条件
--cfg:引导配置条目
function My.Create(cfg)
  local ty = tostring(cfg.ty)
  local cond = My.dic[ty]
  local it = nil
  if cond then
    it = ObjPool.Get(cond)
  else
    iTrace.Error("Loong", "引导ID:", cfg.id, " 的类型:", cfg.ty, " 未定义")
  end
  return it
end

return My
