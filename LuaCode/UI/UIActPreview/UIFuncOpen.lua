--[[
    功能开启界面
]]

require("UI/UIActPreview/UIFuncPre")
require("UI/UIActPreview/UIModPre")
UIFuncOpen = UIBase:New{Name = "UIFuncOpen"}
local M = UIFuncOpen

local togList = {}
local cDic = {}

-- 初始化界面
function M:InitCustom()
    self:InitData()
end

function M:InitData()
    local root = self.root
    local T = TransTool.FindChild
    local C = ComTool.Get
    local US = UITool.SetLsnrClick
    local gird = T(root,"grid").transform
    for i=1,2 do
        local tg = C(UIToggle,root,"grid/tog"..i,self.Name,false)
        togList[i] = tg
        US(root,"grid/tog"..i,self.Name,self.OnClick,self)
    end
    US(root,"closeBtn",self.Name,self.Close,self)

    self.funcPre = T(root, "FuncPre")
    self.modPre = T(root,"ModPre")
    self:OPage(c,UIFuncPre,self.funcPre,1)
    self:OPage(c,UIModPre,self.modPre,2)
end

function M:OpenTag(tp)
    self.tp = tp
    UIMgr.Open(self.Name)
end

-- 一级菜单分类
function M:OnClick(go)
    local tp = tonumber(string.sub( go.name, 4))
    self:SwitchTg(tp)
end

-- 切换分页
function M:SwitchTg(tp)
    if self.curTp == tp then return end
    togList[tp].value=true
    self.curTp = tp
    if self.curC then self.curC:Close() end
    local c = cDic[tostring(tp)]
    if c then
        self.curC = c
    else
        if tp == 1 then
            self:OPage(c,UIFuncPre,self.funcPre,1)
        elseif tp == 2 then
            self:OPage(c,UIModPre,self.modPre,2)
        end
    end
    self.curC:Open()
end


function M:OPage(c,name,nameObj,num)
    if not c then
        c = ObjPool.Get(name)
        c:Init(nameObj)
        cDic[tostring(num)] = c
    end
    self.curC = c
end


function M:SetDefTp(tp)
    if tp and togList[tp] and togList[tp].gameObject.activeSelf then
        self:SwitchTg(tp)
    else
        for i=1,#togList do
            if togList[i].gameObject.activeSelf then
                self:SwitchTg(i)
                break
            end
        end
    end
end

-- 打开界面
function M:OpenCustom()
    self:SetDefTp(self.tp)
end

-- 关闭界面
function M:CloseCustom()
    
end

-- 刷新数据
function M:UpData()
    -- body
end

-- 清理数据
function M:DisposeCustom()
    self.curTp = nil
    if self.curC and self.curC.Close then
        self.curC:Close()
        self.curC = nil
    end
    TableTool.ClearDicToPool(cDic)
    self.tp = nil
    TableTool.ClearDic(togList)
end

return M