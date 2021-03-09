--[[
	AU:Loong
	TM:2017.5.12
	BG:入口
--]]

require("UnityEngine.MeshRenderer")
require("UnityEngine.MeshCollider")

require("cs/cs_define")
Screen.fullScreen = true
require("Main/lua_define")

require("debug/debug_ctrl")

require("Main/Super")
require("Lib/Event")
require("Lib/mathex")
require("Lib/DelGbj")

require("Data/EnumType")
require("Conf/Conf")
require("baseclass")
require("Main/App")
require("Tool/ShaderTool")
require("Tool/ModPool")
require("Tool/ObjPool")
require("Str/StrBuffer")
require("Tool/iTool")
require("Tool/TransTool")
require("Tool/ComTool")
require("Tool/UITool")
require("Tool/UIMisc")
require("Tool/TexTool")
require("Tool/LayerTool")
require("Tool/EventTool")
require("Tool/ListTool")
require("Tool/TableTool")
require("Tool/StrTool")
require("Tool/iTrace")
require("Tool/BinTool")
require("Tool/ItemTool")
require("Tool/AssetTool")
require("Tool/GMGetItem")
require("Scene/SceneTool")
require("Preload/PreloadMgr")
require("Proto/ProtoMgr")
require("Tool/PropTool")
require("Data/Prop/PropTb")
require("Data/Prop/EquipTb")
require("Data/Prop/KV")
require("Flow/FlowChartUtil")
require("Data/Boss/soonTool")
require("Data/Notice/NoticeTb")
require("System/TypeToName")
require("Data/Server/ServerMgr")
require("Data/CloudBuy/soonQlist")

require("UI/LuaUIEvent")
require("Adv/AdvMgr")
require("Adv/AdvFlagMgr")
require("Timer/TimerMgr")
require("Tween/TweenMgr")
require("Data/TransApp/TransAppMgr")
require("Tool/XDelayDestroy")
require("Util/MemUtil")
require("Util/ParticleUtil")
require("Main/ModuleMgr")



Main = {Name = "Main"}

local My = Main

local once = true

--系统模块列表
--模块尽量使用面向对象的写法
My.mods = {}

--包含Update方法的模块
My.upMods = {}

--入口
function My.Entry()
	if not once then return end
	once = false
	UpdateBeat:Add(My.Update)
	LateUpdateBeat:Add(My.LateUpdate)
	FixedUpdateBeat:Add(My.FixedUpdate)
end

--初始化 所有配置表加载完成后执行
function My.Init()

	--// 设置2根骨骼混合
	UnityEngine.QualitySettings.skinWeights = UnityEngine.SkinWeights.TwoBones;

	MemUtil.Snap()
	MemUtil.Snap("Lua Init before")
	App.Init()
	UITip.Init()
	TimerMgr:Init()
	TweenMgr:Init()
	ProtoMgr.Init()
	PropTool.Init()
	AssetTool.Init()
	SceneTool:Init()
	LuaUIEvent.Init()
	ModuleMgr:Init()
	My.Misc()
	ItemTool.Init()
	PreloadMgr.Init()
	GMGetItem.Init()
	My.AddEvent()
	MemUtil.Snap("Lua Init After")
end

function My.AddEvent()
	Add = EventMgr.Add
	local EH = EventHandler
	Add("DataClear", EH(My.Clear))
	AccMgr.eLogoutSuc:Add(My.Clear)
end

--杂乱的
function My.Misc()
	Music:PlayByID(106, 1)
	coroutine.start(My.CloseCamMSAA)
end

function My:CloseCamMSAA()
	coroutine.wait(0.001)
	local trdCam = ComTool.Get(Camera, Camera.main.transform, "3DUICam",Camera.main.name)
	if trdCam then trdCam.allowMSAA = false end
end
--更新
function My.Update()
	TimerMgr:Update()
	TweenMgr:Update()
	ModuleMgr:Update()
	GMGetItem.Update()
end

--比Update晚更新
function My.LateUpdate()
	ModuleMgr:LateUpdate()
end

--物理.固定更新
function My.FixedUpdate()

end

--清除缓存
function My.Clear(isReconnect)
	ModuleMgr:Clear(isReconnect)
	collectgarbage("collect")
end


function My.Dispose()
	UpdateBeat:Remove(My.Update)
	LateUpdateBeat:Remove(My.LateUpdate)
	FixedUpdateBeat:Remove(My.FixedUpdate)
end
