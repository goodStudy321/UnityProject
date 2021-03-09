--[[
 	authors 	:Liu
 	date    	:2018-12-5 10:33:00
 	descrition 	:结婚系统模块1
--]]

UIMarryMod1 = Super:New{Name = "UIMarryMod1"}

local My = UIMarryMod1

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.moduel = Find(root, "moduel", des)
    self.selfModel = Find(root, "moduel/right/model", des)
    self.otherModel = Find(root, "moduel/left/model", des)
    self.name1 = CG(UILabel, root, "topGo/nameBg2/lab")
    self.name2 = CG(UILabel, root, "topGo/nameBg1/lab")

    self.btn3 = FindC(root, "moduel/btn3", des)
    self.titleBg = FindC(root, "moduel/titleBg", des)
    self.titleLab = CG(UILabel, root, "moduel/titleBg/lab")
    self.tex = CG(UITexture, root, "moduel/titleBg/tex")
    self.progBg = FindC(root, "moduel/progressBg", des)
    self.progBg:SetActive(false)
    self.go = root.gameObject

    SetB(root, "moduel/btn0", des, self.OnBtn0, self)
    SetB(root, "moduel/btn1", des, self.OnBtn1, self)
    SetB(root, "moduel/btn2", des, self.OnBtn2, self)
    SetB(root, "moduel/btn3", des, self.OnBtn3, self)

    self:InitData()
    self:CreateModel1()
    self:InitMenu()
    self:InitTitle()

    self:UpLab1()
    self:UpLab2("暂无仙侣")
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    MarryMgr.eDivorce[func](MarryMgr.eDivorce, self.RespDivorce, self)
end

--响应离婚
function My:RespDivorce()
    self:UnloadModel2()
    self:UpLab2("暂无仙侣")
end

--初始化称号
function My:InitTitle()
    if self.data == nil then return end
    local it = UIMarry.title:GetTitleProg()
    if it == nil then return end
    local val = it.progVal
    local str = string.format("[4A2515FF]当前称号获取进度: [F4DDBDFF]%s", val)
    self.titleLab.text = str.."[F4DDBDFF]%"
    --加载
    local key = tostring(it.cfg.titleId)
    local tCfg = TitleCfg[key]
    if tCfg == nil then return end
    --self.texName1 = tCfg.prefab1..".png"
    self.texName1 = string.sub(tCfg.prefab1,1,-5)..".png"
    AssetMgr:Load(self.texName1, ObjHandler(self.SetIcon, self))
end

--设置称号
function My:SetIcon(tex)
    if self.tex then
        self.tex.mainTexture = tex
    end
end

--点击白头偕老
function My:OnBtn0()
    if MarryInfo:IsMarry() then
        UIProposePop:OpenTab(7, true)
    else
        UITip.Log("您未有仙侣")
    end
end

--点击仙侣称号
function My:OnBtn1()
    UIMarry:SetMenuState(2)
end

--点击前往结婚
function My:OnBtn2()
    Hangup:ClearAutoInfo()
    if not self:IsExist() then return end
    if not self:IsJump() then
        UITip.Log("特殊场景不能跳转")
        return
    end
    local key = tostring(MarryInfo.npcId)
    local cfg = NPCTemp[key]
    if cfg == nil then return end
    local pPos = FindHelper.instance:GetOwnerPos()
    local pos = Vector3.New(cfg.pos.x*0.01, cfg.pos.y*0.01, cfg.pos.z*0.01)
    if VIPMgr.vipLv > 0 then
        local dis = Vector3.Distance(pPos, pos)
        if dis < 6 then
            User:StartNavPath(pos, cfg.sceen, -1, 0)
        else
            User:FlyShoes(pos, cfg.sceen, -1, 0)
        end
    else
        User:StartNavPath(pos, cfg.sceen, -1, 0)
    end
    UIMarry:Close()
    EventMgr.Add("NavPathComplete", EventHandler(MarryMgr.NavPathEnd, MarryMgr))
end

--是否能跳转
function My:IsJump()
    local key = tostring(User.SceneId)
    local cfg = SceneTemp[key]
    if cfg == nil then return end
    if cfg.maptype == 1 and (cfg.mapchildtype == nil) and User.SceneId ~= MarryInfo.copyId then
        return true
    end
    return false
end

--判断场景资源是否存在
function My:IsExist()
    local nextSceneInfo = SceneTemp[tostring(MarryInfo.copyId)];
	if nextSceneInfo == nil then
		iTrace.eError("LY", "Can not get scene info : "..id);
		return false
	end

	local nextSceneResName = StrTool.Concat(nextSceneInfo.res, ".unity");
	if Loong.Game.AssetMgr.Instance:Exist(nextSceneResName) == false then
		--UITip.Log("场景资源尚未加载完成!");
		UIMgr.Open(UIDownload.Name)
		iTrace.eError("LY", "Scene res is not exist : "..nextSceneResName);
		return false
    end
    return true
end

--点击玩法说明按钮
function My:OnBtn3()
    UIMarry:SetDesState(true)
end

--设置名称物体
function My:UpNameGo(state)
    self.name1.transform.parent.gameObject:SetActive(state)
    self.name2.transform.parent.gameObject:SetActive(state)
end

--初始化自身模型
function My:CreateModel1()
    self.model1 = ObjPool.Get(RoleSkin)
	self.model1.eLoadModelCB:Add(self.SetPos1, self)
    self.model1:CreateSelf(self.selfModel)
    self.selfModel.gameObject:AddComponent(typeof(UIRotateMod))
end

--创建仙侣模型
function My:CreateModel2(info)
    self:UnloadModel2()
    self.model2 = ObjPool.Get(RoleSkin)
    self.model2.eLoadModelCB:Add(self.SetPos2, self)
    self.model2:Create(self.otherModel, (info.category * 10 + info.sex) * 1000 + info.lv, info.skins, info.sex)
    self.otherModel.gameObject:AddComponent(typeof(UIRotateMod))
    self:UpLab2(info.name)
end

--设置自身模型位置
function My:SetPos1(go)
    self:UpPos(go, 169)
end

--设置伴侣模型位置
function My:SetPos2(go)
    self:UpPos(go, -105)
end

--更新模型位置
function My:UpPos(go, x)
    local pos = Vector3.New(x, -268, 222)
    local rota = Vector3.New(0, 180, 0)
	local scale = Vector3.one * 375
	if User.instance.MapData.Sex == 1 then --男
		pos = Vector3.New(x, -273, 222)
		rota = Vector3.New(0, 180, 0)
	end
	go.transform.localPosition = pos
	go.transform.localScale = scale
	go.transform.localEulerAngles = rota
end

--更新自身文本
function My:UpLab1()
    self.name1.text = User.MapData.Name
end

--更新仙侣文本
function My:UpLab2(str)
    self.name2.text = str
end

--初始化界面
function My:InitMenu()
    if self.data then
        self:SetMenuState(true)
    else
        self:SetMenuState(false)
    end
end

--设置界面状态
function My:SetMenuState(state)
    self.titleBg:SetActive(state)
    self.btn3:SetActive(not state)
end

--初始化数据
function My:InitData()
    self.data = MarryInfo.data.coupleInfo
end

--卸载自身模型
function My:UnloadModel1()
    if self.model1 then
        self.model1.eLoadModelCB:Remove(self.SetPos1, self)
        ObjPool.Add(self.model1)
        self.model1 = nil
    end
end

--卸载仙侣模型
function My:UnloadModel2()
    if self.model2 then
        self.model2.eLoadModelCB:Remove(self.SetPos2, self)
        ObjPool.Add(self.model2)
        self.model2 = nil
    end
end

--清理缓存
function My:Clear()
    if self.texName1 then
        AssetMgr:Unload(self.texName1,false)
        self.texName1 = nil
    end
end

--释放资源
function My:Dispose()
    self:Clear()
    self:UnloadModel1()
    self:UnloadModel2()
    self:SetLnsr("Remove")
end

return My