--// 地图系统管理器

QualityTool = Super:New{Name = "QualityMgr"}
QualityTool.recLv=0
QualityTool.maxCfgLv=0
local iLog = iTrace.eLog;
local iError = iTrace.Error;
local eWarming = iTrace.eWarning;
local ET = EventMgr.Trigger;

local mgrPre = {};

--// 初始化
function QualityTool:Init()
	QualityTool.recLv,QualityTool.maxCfgLv=QualityTool:GetQualityCfg()
	if mgrPre.init ~= nil and mgrPre.init == true then
 		return;
	end
	
 	mgrPre.init = false;
	
 	mgrPre.init = true;
end

function QualityTool:Clear()
	mgrPre.init = false;
end

function QualityTool:Dispose()
	mgrPre.init = false;
end

--// 获取硬件质量信息
function QualityTool:GetQualityCfg()
	local modelName = Device.Instance.Model;
	local recLv = -1;
	local maxCfgLv = 3;
	for k, v in pairs(MobileInfo) do
		if v.motype == modelName then
			recLv = v.quility;
			maxCfgLv = v.quility;
			break;
		end
	end
	if recLv < 0 then
		if App.platform == Platform.iOS or App.platform == Platform.PC then
			recLv = 3;
		else
			recLv = 1;
		end
	end
	if recLv>maxCfgLv then
		recLv=maxCfgLv
	end
	return recLv, maxCfgLv;
end
--就是数值直接+1
function QualityTool:GetSetUseQuality(  )
	return QualityTool.recLv+1,QualityTool.maxCfgLv+1;
end

return QualityTool