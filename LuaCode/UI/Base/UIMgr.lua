--[[
	AU:Loong
	TM:2017.05.09
	BG:UI管理器
--]]
local Event = require("Lib/Event")
require("UI/Base/UIFty")
require("UI/Base/UIBase")
require("UI/Base/UITabMgr")
require("Tool/LuaTool")


local GameObject = UnityEngine.GameObject

UIMgr = { Name = "UIMgr" }

local My = UIMgr

--UI字典
My.Dic = {}

--UI相机
My.Cam = nil

--最高层级UI相机
My.HCam = nil

--根节点
My.Root = nil

--是否强制限制不允许关闭和打开其他面板
My.CanNotClose=false;

--记录以打开字典
--k:名称,v:UI面板
My.recordDic = {}

--打开事件字典
--k:UI名称 v:Event
My.eOpen = {}


--开关UI使用效果
My.UseOnOffEffect = true

--/// LY add begin ///
My.lastCamEnable = false;
--/// LY add end ///

function My.Init()
	My.pRemove = Event:New()
	My.pRemove:Add(My.RealRemove)
	My.uiRoot = ComTool.GetSelf(UIRoot, My.Root, My.Name)

	My.HCam.depth=90
end

--添加打开回调事件
--func(function):方法
--obj:lua(table) or C#(class)
function My.eOpenAdd(name, func, obj)
	local ty = type(func)
	if ty ~= "function" then return end
	local eOpen = My.eOpen
	local e = eOpen[name]
	if e == nil then
		e = ObjPool.Get(Event)
		eOpen[name] = e
	end
	e:Add(func, obj)
end

--触发事件
--name(string):UI名称
function My.eOpenTrig(name)
	local eOpen = My.eOpen
	local e = eOpen[name]
	if(e == nil) then return end
	e(name)
	eOpen[name] = nil
	ObjPool.Add(e)
end

--打开以存在的面板
function My.OpenExist(name)
	local ui = My.Dic[name]
	if ui.Loading then return end
	ui:Open()
end

--创建面板
function My.Create(name)
	local go = GbjPool:Get(name)
	local ui = UIFty.Create(name)
	My.Dic[name] = ui
	if LuaTool.IsNull(go) then
		ui.Loading = true
		AssetMgr:Load(name, ".prefab", ObjHandler(My.LoadSet))
	else
		My.Set(go)
	end
end

--加载完成后设置面板游戏对象
function My.LoadSet(obj)
	if LuaTool.IsNull(obj) then
		iTrace.Error("Loong", "load ui prefab is null")
	else
		local go = Instantiate(obj)
		ShaderTool.eResetGo(go)
		My.Set(go)
	end
end

--设置面板游戏对象
function My.Set(go)
	if LuaTool.IsNull(go) then
		iTrace.Error("Loong", "loaded ui prefab is null")
	else
		local name = string.gsub(go.name, "%(Clone%)", "")
		local ui = My.Dic[name]
		if ui == nil then
			Destroy(go)
		elseif ui.setDestory then
			Destroy(go)
		else
			go.name = name
			ui.gbj = go
			local trans = go.transform
			trans.parent = My.Root
			trans.localScale = Vector3.one
			trans.localPosition = Vector3.zero
			go:SetActive(false)
			ui:Init()
			ui:Open()
		end
	end
end

--打开面板
--name(string):面板名称
--func(function):回调方法,参数:UI名称
--obj:回调对象 lua(table) or C#(class)
function My.Open(name, func, obj)
	local ty = type(name)
	if(ty ~= "string") then
		iTrace.Error("Loong", "name must is string, but:", ty)
	else
		if name == UINPCDialog.Name or name == UIOperationTip.Name or name == UIShowPendant.Name or name == UIEndPanel.Name then		
			JumpMgr:Clear()	
		end
		My.eOpenAdd(name, func, obj)
		if My.Dic[name] then
			My.OpenExist(name)
		else
			My.Create(name)
		end
	end
end

--关闭面板 Name:面板名称
function My.Close(name)
	if My.CanNotClose and name==UIRevive.Name then return end
	if(name == nil) then return end
	local ui = My.Dic[name]
	if ui == nil then return end
	ui:Close()
end

--设置是否强制不允许开关允许小窗口
function My.SetCanClose( bool )
	My.CanNotClose=bool;
end


--更新所有面板
function My.Update()
	for k, ui in pairs(My.Dic) do
		if ui.active > 0 then
			ui:Update()
		end
	end

	if My.Cam ~= nil then
		local curCamEnable = My.Cam.enabled;
		if curCamEnable ~= My.lastCamEnable then
			if curCamEnable == true then
				EventMgr.Trigger("UICameraOpen")
			else
				EventMgr.Trigger("UICameraClose")
			end
		end
		My.lastCamEnable = curCamEnable;
	end
end

function My.LateUpdate()
	for k, ui in pairs(My.Dic) do
		if ui.active > 0 then
			ui:LateUpdate()
		end
	end
end

--关闭所有面板
function My.CloseAll()
	TableTool.ClearDic(My.recordDic)
	for k, v in pairs(My.Dic) do
		if v.active == 1 and v.Name ~= "UILoading" and v.Name ~= UIMaskFade.Name then
			v:Close()
		end
	end
end

--获取面板
function My.Get(name)
	return My.Dic[name]
end

--添加面板
function My.Add(go)
	if LuaTool.IsNull(go) then
		iTrace.Error("Loong", "UI游戏对象为空")
		return
	end
	local name = go.Name
	local ui = UIFty.Create(name)
	My.Dic[name] = ui
	ui.gbj = go
	My.Set(go)
end

--移除面板
function My.Remove(name)
	My.pRemove(name)
end


function My.RealRemove(name)
	if (name == nil) then return end
	local ui = My.Dic[name]
	if ui == nil then return end
	if ui.Persist then return end
	ui:Dispose()
	My.Dic[name] = nil
end

function My.Swap(sName)
	local key = nil
	for k, v in pairs(My.Dic) do
		if v.active == 1 and v:CanRecords() and k ~= sName then
			if v.cfg and v.cfg.tOn == 1 then
				key = v.Name
				break
			end
		end
	end
	if not StrTool.IsNullOrEmpty(key) then
		local recordDic = My.recordDic
		recordDic[sName] = recordDic[key]
		recordDic[key] = nil
		local ui = My.Dic[key]
		if ui and not ui:ConDisplay() then
			ui:Close()
		end
	end
end

--记录已经打开的面板并关闭 sName:不需记录的面板
function My.RecordOpens(sName, record)
	if record == nil then record = false end
	local recordDic = My.recordDic
	local dic = recordDic[sName]
	if not dic then
		recordDic[sName] = {}
		dic = recordDic[sName]
	end
	for k, v in pairs(My.Dic) do
		if v.active == 1 and v:CanRecords() and k ~= sName then
			if v.cfg and v.cfg.tOn == 1 then
				if recordDic[v.Name] then
					recordDic[sName] = recordDic[v.Name]
					recordDic[v.Name] = nil
				end				
			else
				if not v:CloseClean() then
					if record then
						dic[k] = v
					end
				end
			end
		end
		if not v:ConDisplay() then
			v:Close()
		end
	end
end

--重新打开已经关闭的面板
function My.OpenRecords(sName)
	local rc = My.recordDic
	local dic = rc[sName]
	if not dic then return end
	for k, v in pairs(dic) do		
		dic[k] = nil
		v:Open()
	end
	dic = nil
end

function My.IsOpenUI()
	for k,v in pairs(My.Dic) do
		if v.active == 1 then
			local cfg = v.cfg
			if cfg then
				if cfg.tOn == 1 then
					return true
				end
			end
		end
	end
	return false
end

--返回UI的状态
--UI存在时,返回active,反之返回-1
function My.GetActive(name)
	local ui = My.Get(name)
	if ui == nil then return (-1) end
	return ui.active
end

--重新打开固定的面板
function My.ReOpens()
	local Open = My.Open
	Open("UIMainMenu")
	--Open("UIMainMenuLeft")
	--Open("UISkill")
	--Open("UIBuff")
	Open("UIActPreview")
end

--清理
function My:Clear(isReconnect)
	for k, v in pairs(My.Dic) do
		v:Clear(isReconnect)
	end
end

--释放
function My.Dispose()
	TableTool.ClearDic(My.recordDic)
	local dic = My.Dic
	for k, v in pairs(dic) do
		if not v.Persist then
			v:Dispose()
			dic[k] = nil
		end
	end
end

return My
