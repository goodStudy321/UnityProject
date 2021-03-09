--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-09-23 15:07:19
-- 资源工具
--=========================================================================


AssetTool = {Name="AssetTool"}

local My = AssetTool

--全局资源开始加载事件
My.eStart = Event()
--全局资源结束加载事件
My.eComplete = Event()

function My.Init()
  EventTool.Add(AssetMgr, "start", My.Start)
  EventTool.Add(AssetMgr, "complete", My.Complete)
end

function My.Start()
  My.eStart()
end


function My.Complete()
  My.eComplete()
end

--从模型配置加载模型
--id(number)配置ID
--func(function)完成回调
--obj(table)对象
function My.LoadMod(id, func, obj)
  if type(id) ~= "number" then return end
  if type(func) ~= "function" then return end
  local modID = tostring(id)
  local info = RoleBaseTemp[modID]
  if info == nil then
    iTrace.Error("Loong", "无ID为:", modID, "的模型配置")
    return
  end
  local modPath = info.path
  if #modPath == 0 then
    iTrace.Error("Loong", "ID为:", modID, "的模型未配置路径")
    return
  end
  local cb = nil
  if obj then
    cb = GbjHandler(func, obj)
  else
    cb = GbjHandler(func)
  end
  Loong.Game.AssetMgr.LoadPrefab(modPath, cb)
end

--根据性别获取模型ID
function My.GetSexModID(cfg)
  local sex = User.MapData.Sex
  local id = (sex == 0) and cfg.wuMod or cfg.muMod
  id = id or cfg.uMod
  do return id end
end

--根据性别获取场景模型ID
function My.GetSexScModID(cfg)
  local sex = User.MapData.Sex
  local id = (sex == 0) and cfg.wMod or cfg.mMod
  id = id or cfg.mod
  do return id end
end

--通过配置中的ID获取模型名称
function My.GetSexModName(cfg)
  local id = My.GetSexModID(cfg)
  local modID = tostring(id)
  local modCfg = RoleBaseTemp[modID]
  local name = modCfg and modCfg.path
  return name
end

--通过配置中的ID获取场景模型名称
function My.GetSexScModName(cfg)
  local id = My.GetSexScModID(cfg)
  local modID = tostring(id)
  local modCfg = RoleBaseTemp[modID]
  local name = modCfg and modCfg.path
  return name
end

--通过配置加载不同性别的模型
--cfg:包含字段wuMod:女性模型路径,muMod:男性模型路径
function My.LoadSexMod(cfg, func, obj)
  local sex = User.MapData.Sex
  local id = (sex == 0) and cfg.wuMod or cfg.muMod
  id = id or cfg.uMod
  My.LoadMod(id, func, obj)
end

--从道具配置表加载Icon
function My.LoadItIcon(id, func, obj)
  if type(id) ~= "number" then return end
  if type(func) ~= "function" then return end
  local itID = tostring(id)
  local info = ItemData[itID]
  if info == nil then
    iTrace.Error("Loong", "无ID为:", itID, "的道具配置")
    return
  end
  local name = info.icon
  if #name == 0 then
    iTrace.Error("Loong", "ID为:", itID, "的道具未配置图标")
    return
  end
  local oh = nil
  if obj then
    oh = ObjHandler(func, obj)
  else
    oh = ObjHandler(func)
  end
  AssetMgr:Load(name, oh)
end

--卸载子变换名称的资源包
--p:(Transform),父变换
function My.Unload(p)
  if p == nil then return end
  local c = nil
  local cnt = p.childCount - 1
  for i = 0, cnt do
    c = p:GetChild(i)
    AssetMgr:Unload(c.name, ".prefab", false)
  end
end

--释放指定配置对应字段内的资源
--cfg(table):配置
--name(string):字段名称
function My.UnloadByCfg(cfg, name)
  if (cfg==nil) then return end
  if (name==nil) then return end
  local assetName = nil
  for k,v in pairs(cfg) do
    assetName = v[name]
    if assetName then
      AssetMgr:Unload(assetName,false)
    end
  end 
end

function My.UnloadTex(data, sfx)
  if not data then return end
  sfx = sfx or ".png" 
  if type(data) == "table" then
    local len = #data
    for i=1,len do
      AssetMgr:Unload(data[i], sfx, false)
      data[i] = nil
    end
  elseif type(data) == "string" then
    AssetMgr:Unload(data, sfx, false)
  end
end

--判断指定资源是否存在
--assName：资源名称
function My.IsExistAss(assName)
  local isExist = false
  local prefabName = assName
  local prefabAss = StrTool.Concat(prefabName, ".prefab");
  if Loong.Game.AssetMgr.Instance:Exist(prefabAss) == false then
    isExist = false
  else
    isExist = true
  end
  return isExist
end
