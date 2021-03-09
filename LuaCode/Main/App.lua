--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-09-29 22:15:21
--=========================================================================

App = {Name = "App"}

local UApp = UnityEngine.Application

local My = App

--平台
Platform = {Name = "Platform", Android = 1, iOS = 2, PC = 0}


function My.Init()

  My.Ver = CSApp.Ver
  My.VerCode = CSApp.VerCode
  My.AssetVer = CSApp.AssetVer
  --服务器选项枚举,定义在EnumType中
  My.SvrOp = CSApp.SvrOp
  --true:测试,false正式
  My.IsDebug = CSApp.IsDebug
  --true:正式环境下调试
  My.IsReleaseDebug = CSApp.IsReleaseDebug
  --编辑器属性
  My.isEditor = UApp.isEditor
  --0:编辑器,1:Android,2:IOS,3:其它
  My.platform = CSApp.platform
  --流文件夹
  My.Streaming = CSApp.WwwStreaming .. "/"
  --持久化数据路径
  My.PersistPath = UApp.persistentDataPath .. "/"
  --true:首次安装
  My.FirstInstall = CSApp.FirstInstall

  My.IsSubAssets = CSApp.IsSubAssets
  My.SetBSUrl()
end

--格式化版本号
function My.FmtVer()
  local str = My.Ver .. "_" .. My.VerCode .. "_" .. My.AssetVer
  do return str end
end

function My.IsAndroid()
  do return App.platform == Platform.Android end
end

function My.IsIOS()
  do return App.platform == Platform.iOS end
end

--设置后台的URL
function My.SetBSUrl()
  local cfg = DomainCfg[1]
  if App.isEditor then
    My.BSUrl = cfg.inter
  elseif App.IsReleaseDebug then
    My.BSUrl = cfg.exter
  elseif App.IsDebug == true then
    My.BSUrl = cfg.exterTest
  else
    My.BSUrl = cfg.exter
  end
end


function My.Quit()
  if My.isEditor then
    iTrace.LogWarning("Loong", "editor not support quit")
  elseif My.platform == Platform.iOS then
    while true do
      local go = GameObject.New("crash")
      local ut = go:AddComponent(typeof(UITexture))
      local tex = Texture2D.New(1024, 1024)
      ut.mainTexture = tex
    end
  else
    UApp.Quit()
  end
end

return My
