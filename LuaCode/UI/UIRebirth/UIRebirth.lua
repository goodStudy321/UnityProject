require("UI/UIRebirth/UIRebirthFPage")

UIRebirth = UIBase:New{Name="UIRebirth"}
local My = UIRebirth;
--打开转生等级
My.openRbLv = nil;
--套装解锁
My.UnlockItemG = {};
My.UnlockItemN = {};
My.UnlockItems = {};
local GO = UnityEngine.GameObject;
local AssetMgr = Loong.Game.AssetMgr;

function My:InitCustom()
    local root = self.root;
    local name = "转生系统界面";
    local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;

    self.RbTabs = {};
    local path = "";
    for i = 1,5 do
        path = "Rebirth" .. i;
        self.RbTabs[i] = TF(root,path,name);
        UC(root,path,name,self.TabClk,self);
    end
    self.BfFourTR = TF(root,"BeforFTRoot",name);
    self.FourTR = TF(root,"FourTRoot",name);
    self.EffRoot = TF(root,"EffRoot",name);
    self.FPage = ObjPool.Get(UIRebirthFPage)
    self.FPage:Init(self.FourTR)

    self.lvBg=CG(UISprite,root,"BeforFTRoot/RoleInfo",name,false)
    self.RoleLev = CG(UILabel,root,"BeforFTRoot/RoleInfo/Level",name,false);
    self.ProName = CG(UILabel,root,"BeforFTRoot/RoleInfo/ProName",name,false);
    --前三转
    --阶段
    self.RbDone = TF(root,"BeforFTRoot/RbDone",name);
    self.StageLbl = CG(UILabel,root,"BeforFTRoot/Stage",name,false);
    self.TaskDesc = CG(UILabel,root,"BeforFTRoot/Stage/TaskDes",name,false);
    self.TaskDetail = CG(UILabel,root,"BeforFTRoot/Stage/TaskDetail",name,false);
    path = "BeforFTRoot/Unlock";
    for i=1,2 do
        self.UnlockItemG[i] = TF(root,string.format("%s%s",path,i),name);
        self.UnlockItemN[i] = CG(UILabel,root,string.format("%sL%s",path,i),name,false);
    end
    --属性提升
    self.AttProsTitle = {};
    self.AttProsValue = {};
    path = "BeforFTRoot/AttPro/";
    self.AttProG = TF(root,path,name);
    for i = 1,4 do
        local tPath = path .. "attrTitle" .. i;
        local vPath = path .. "attrValue" .. i;
        self.AttProsTitle[i] = CG(UILabel,root,tPath,name,false);
        self.AttProsValue[i] = CG(UILabel,root,vPath,name,false);
        self.AttProsTitle[i].gameObject:SetActive(false);
        self.AttProsValue[i].gameObject:SetActive(false);
    end

    local path = "BeforFTRoot/OneTurn";
    local mPath = path .. "/ManLevSkill";
    local wPath = path .. "/WomLevSkill";
    self.OneTurn = TF(root,path,name);
    self.OTMLevSkill = TF(root,mPath,name);
    self.OTWLevSkill = TF(root,wPath,name);
    path = "BeforFTRoot/TwoTurn";
    mPath = path .. "/ManLevSkill";
    wPath = path .. "/WomLevSkill";
    self.TwoTurn = TF(root,path,name);
    self.TwTMLevSkill = TF(root,mPath,name);
    self.TwTWLevSkill = TF(root,wPath,name);
    mPath = path .. "/ManOpenSkills";
    wPath = path .. "/WomOpenSkills";
    self.TwTMOpenSkills = TF(root,mPath,name);
    self.TwTWOpenSkills = TF(root,wPath,name);
    path = "BeforFTRoot/ThrTurn";
    mPath = path .. "/ManOpenSkills";
    wPath = path .. "/WomOpenSkills";
    self.ThrTurn = TF(root,path,name);
    self.ThrTMOpenSkills = TF(root,mPath,name);
    self.ThrTWOpenSkills = TF(root,wPath,name);
    self.StageAttsTitle = {};
    self.StageAttsValue = {};
    path = "BeforFTRoot/StageAtt";
    self.StageAttG = TF(root,path,name);
    for i = 1,4 do
        local tPath = path .. "/attrTitle" .. i;
        local vPath = path .. "/attrValue" .. i;
        self.StageAttsTitle[i] = CG(UILabel,root,tPath,name,false);
        self.StageAttsValue[i] = CG(UILabel,root,vPath,name,false);
        self.StageAttsTitle[i].gameObject:SetActive(false);
        self.StageAttsValue[i].gameObject:SetActive(false);
    end
    self.BtnTable = CG(UITable,root,"BeforFTRoot/BtnTable",name,false);
    self.AttrTab = TF(root,"BeforFTRoot/BtnTable/AttrTab",name);
    self.AttrTabS = TF(root,"BeforFTRoot/BtnTable/AttrTab/Select",name);
    self.StageTab = TF(root,"BeforFTRoot/BtnTable/StageTab",name);
    self.StageTabS = TF(root,"BeforFTRoot/BtnTable/StageTab/Select",name);
    UC(root,"BeforFTRoot/BtnTable/AttrTab",name,self.AttrTabC,self);
    UC(root,"BeforFTRoot/BtnTable/StageTab",name,self.StageTabC,self);
    UC(root,"BeforFTRoot/DoBtn",name,self.DoTask,self);
    UC(root,"CloseBtn",name,self.CloseC,self);
    self.ModRoot = TF(root,"BeforFTRoot/ModRoot",name);
    self.DoBtnG = TF(root,"BeforFTRoot/DoBtn",name);
    self.DoBtnLbl = CG(UILabel,root,"BeforFTRoot/DoBtn/Label",name,false);
    self.RoleIcon = CG(UITexture,root,"BeforFTRoot/ModBg",name,false);


    self.QuickCollider = CG(BoxCollider,root,"BeforFTRoot/GetWay/QuickBtn",name,false);
    self.QuickSprite = CG(UISprite,root,"BeforFTRoot/GetWay/QuickBtn",name,false);
    self.QuickBtn = CG(UIButton,root,"BeforFTRoot/GetWay/QuickBtn",name,false);
    self.GetWay = TF(root,"BeforFTRoot/GetWay",name)
    UC(root,"BeforFTRoot/GetWay/QuickBtn",name,self.QuickBuyClick,self)

    self:AddLsnr();
    self:SetData();
end

function My:CloseCustom()
    self:RemoveLsnr();
    self:ClearIcon();

    if self.FPage then
        self.FPage:Close()
    end
    self:ClearItems();
    self:DestroyEff();
    My.openRbLv = nil;
end

function My:AddLsnr()
    MissionMgr.eUpdateMission:Add(self.UpdateTask,self);
    RebirthMsg.eRefresh:Add(self.RefreshData,self);
    PropMgr.eGetAdd:Add(self.OnAdd,self)
    PropMgr.eAdd["Add"](PropMgr.eAdd,self.RespAdd,self)
end

function My:RemoveLsnr()
    MissionMgr.eUpdateMission:Remove(self.UpdateTask,self);
    RebirthMsg.eRefresh:Remove(self.RefreshData,self);
    PropMgr.eGetAdd:Remove(self.OnAdd,self)
    PropMgr.eAdd["Remove"](PropMgr.eAdd,self.RespAdd,self)
end

--清除角色图片
function My:ClearIcon()
    if not LuaTool.IsNull(self.RoleIcon) then
        AssetMgr.Instance:Unload(self.IconName,".png",false);
        self.RoleIcon = nil;
        self.IconName = nil;
    end
end

--获取奖励显示
function My:OnAdd(action,dic)
	if action==10003 then
		self.dic=dic
		UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	end
end

function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.dic)
	end
end


--响应背包增加道具
function My:RespAdd(tb)
    local addId = tb.type_id
    if addId == self.id then
        self.QuickCollider.enabled = false
        self.QuickBtn.enabled = false
        self.QuickSprite.color = Color.New(0,0,0,1)
    end
end


--设置角色信息
function My:SetRoleInfo()
    local rbLev = RebirthMsg.RbLev + 1;
    --local lv = UserMgr:GetChangeLv()
    self.RoleLev.text = tostring(UserMgr:GetLv(true));
    local path="ty_19" 
    local isgod = UserMgr:IsGod()
    if isgod==true then path="ty_19A" end
    self.lvBg.spriteName=path
    local name = UIMisc.GetRBPN(User.MapData.Category,rbLev);
    if name == nil then
        return;
    end
    self.ProName.text = name;
end

--设置解锁装备
function My:SetUnlockItem(rbLev)
    local info = Rebirth[rbLev];
    if info == nil then
        return;
    end
    local items = info.unlockItems;
    local len = #items;
    if len > 2 then
        len = 2;
    end
    self:ClearItems();
    local it = nil;
    local itemG = nil;
    local itemN = nil;
    for i = 1, 2 do
        itemG = self.UnlockItemG[i];
        itemN = self.UnlockItemN[i];
        if i <= len then
            itemG:SetActive(true);
            itemN.gameObject:SetActive(true);
            it = ObjPool.Get(UIItemCell);
            self.UnlockItems[i] = it;
            local parent = itemG.transform;
            it:InitLoadPool(parent,0.8,self);
            it:UpData(items[i]);
            local desc = self:GetUnlockDesc(rbLev,i);
            desc = string.gsub(desc, "xx", it.item.name);
            itemN.text = desc;
        else
            itemG:SetActive(false);
            itemN.gameObject:SetActive(false);
        end
    end
end

--获取解锁装备描述
function My:GetUnlockDesc(rbLev,index)
    local info = Rebirth[rbLev];
    if info == nil then
        return "";
    end
    local descs = info.unlockDescs;
    local len = #descs;
    if len < index then
        return "";
    end
    return descs[index];
end

--加载格子完成
function My:LoadCD(go)
end

--销毁套装解锁图片
function My:ClearItems()
    if self.UnlockItems == nil then
        return;
    end
    local length = #self.UnlockItems;
    if length == 0 then
        return;
    end
    local dc = nil;
    for i = 1, length do
        dc = self.UnlockItems[i];
        dc:DestroyGo();
        ObjPool.Add(dc);
        self.UnlockItems[i] = nil;
    end
end

--属性提升点击
function My:AttrTabC()
    self:SetAttTabSlt(1);
end

--阶段属性提升
function My:StageTabC()
    self:SetAttTabSlt(2);
end

--设置属性标签
function My:SetAttTab(rbLev)
    if rbLev == 1 or rbLev == 2 then
        self.AttrTab:SetActive(true);
        self.StageTab:SetActive(false);
        self:SetAttTabSlt(1);
        self.BtnTable:Reposition();
    elseif rbLev == 3 then
        self.AttrTab:SetActive(true);
        self.StageTab:SetActive(true);
        self:SetAttTabSlt(1);
        self.BtnTable:Reposition();
    else

    end
end

--设置属性标签选择
function My:SetAttTabSlt(type)
    if type == 1 then
        self.AttrTabS:SetActive(true);
        self.AttProG:SetActive(true);
        self.StageTabS:SetActive(false);
        self.StageAttG:SetActive(false);
    else
        self.AttrTabS:SetActive(false);
        self.AttProG:SetActive(false);
        self.StageTabS:SetActive(true);
        self.StageAttG:SetActive(true);
    end
end

--刷新数据
function My:RefreshData()
    local rbLev = RebirthMsg.RbLev + 1;
    if self.CurTabIndex ~= rbLev then
        self:PlayRbEff();
    end
    local info = Rebirth[rbLev];
    if info == nil then
        return;
    end
    local level = User.MapData.Level;
    if level < info.limLev then
        if rbLev > 1 then
            self:SetRebInfo(rbLev-1);
        end
        return;
    end
    self:SetRebInfo(rbLev);
end

--检查转生任务是否能完成
function My:ChkRbReady()
    local rbLev = RebirthMsg.RbLev + 1;
    local prog = RebirthMsg.Progress;
    if self.CurTabIndex ~= rbLev then
        return false;
    end
    local info = Rebirth[rbLev];
    if info == nil then
        return true;
    end
    local len = #info.targets;
    if len == prog then
        return true;
    end
    return false;
end

--播放转生特效
function My:PlayRbEff()
    self:DestroyEff();
    self.effectName = "FX_UI_Reborn";
    AssetMgr.LoadPrefab(self.effectName,GbjHandler(self.LoadEDCb,self));
end

--加载特效完成回调
function My:LoadEDCb(go)
    self.RbEff = go;
    TransTool.AddChild(self.EffRoot.transform,go.transform);
    go:SetActive(true);
end

--销毁特效
function My:DestroyEff()
    if self.effectName ~= nil then
        AssetMgr.Instance:Unload(self.effectName,".prefab",false);
        self.effectName = nil;
    end
    if self.RbEff ~= nil then
        local go = self.RbEff;
        GO.Destroy(go);
        self.RbEff = nil;
    end
end

--更新任务数据
function My:UpdateTask(tskId)
    self:SetTaskDetail(tskId);
end

--设置数据
function My:SetData()
    if self.FPage then
        self.FPage:Open()
    end
    local rbLev = nil;
    local maxOpenLv = RebirthMsg.RbLev + 1;
    if My.openRbLv == nil then
        rbLev = maxOpenLv;
    else
        if My.openRbLv > maxOpenLv then
            rbLev = maxOpenLv;
        else
            rbLev = My.openRbLv;
        end
    end
    local level = User.MapData.Level;
    local info = Rebirth[rbLev];
    if info == nil then
        return;
    end
    local level = User.MapData.Level;
    if level < info.limLev then
        if rbLev > 1 then
            My.openRbLv = rbLev - 1;
            self:SetData();
            --self:SetRebInfo(rbLev-1);
        end
        return;
    end
    self:SetRebInfo(rbLev);
end

--打开转生
function My.OpenRbLvTab(openRbLv)
    My.openRbLv = openRbLv;
    UIMgr.Open(UIRebirth.Name);
end

--转生打开分页入（口邮件转生链接入口）
function My:OpenTabByIdx(t1, t2, t3, t4)
    My.openRbLv = t1;
    self:SetData();
end

--显示对象
function My:ShowGo(rbLev)
    if rbLev < 4 then
        self.BfFourTR:SetActive(true);
        self.FourTR:SetActive(false);
    else
        self.BfFourTR:SetActive(false);
        self.FourTR:SetActive(true);
    end
end

--打开转生
function My:SetRebInfo(rbLev)
    self:SetAttTab(rbLev);
    self:SetUnlockItem(rbLev);
    self.CurTabIndex = rbLev;
    self:SetSltChkMark(rbLev);
    self:ShowGo(rbLev);
    self:SetRoleInfo();
    if rbLev < 4 then
        self:SetStage(rbLev);
        self:SetIcon();
        self:SetAttPro(rbLev);
        self:SetSkills(rbLev);
    else
        self:SetFourTurn();
    end
end

--设置选中标签
function My:SetSltChkMark(rbLev)
    for i = 1,4 do
        local TF = TransTool.FindChild;
        local go = self.RbTabs[i];
        local checkMark = TF(go.transform,"Checkmark",name);
        if i == rbLev then
            checkMark:SetActive(true);
        else
            checkMark:SetActive(false);
        end
    end
end

--页签点击
function My:TabClk(go)
    if go == nil then
        return;
    end
    local rbLev = nil;
    for i = 1,5 do
        if self.RbTabs[i].name == go.name then
            rbLev = i;
        end
    end
    local info = Rebirth[rbLev];
    if info == nil then
        return;
    end
    local level = User.MapData.Level;
    if level < info.limLev then
        local str = string.format("%s开启", UserMgr:GetChangeLv(info.limLev, true, true))
        UITip.Log(str);
        return;
    end
    local curRbLev = RebirthMsg.RbLev;
    local num = rbLev - curRbLev;
    if num > 1 then
        local str = string.format("%s转未完成", curRbLev + 1);
        UITip.Log(str);
        return;
    end
    self:SetRebInfo(rbLev);
end

--是否当前转生等级
function My:IsCurTurn(rbLev)
    local maxRbLev = RebirthMsg.RbLev + 1;
    if rbLev == maxRbLev then
        return true;
    else
        return false;
    end
end

--设置模型
function My:SetIcon()
    if not LuaTool.IsNull(self.IconName) then
        self:SetIconPos();
        return;
    end
    local sex = User.MapData.Sex;
    if sex == 0 then
        self.IconName = "rebirthW";
    else
        self.IconName = "rebirthM";
    end
    local name = self.IconName .. ".png";
    AssetMgr.Instance:Load(name,ObjHandler(self.LoadDone,self));
end

--加载完成
function My:LoadDone(tex)
    if self.active ~= 1 then
        self:ClearIcon();
        return;
    end
    self.RoleIcon.mainTexture = tex;
    self:SetIconPos();
end

--设置图片位置(只设置女性图片)
function My:SetIconPos()
    local icon = self.RoleIcon;
    if LuaTool.IsNull(icon) then
        return;
    end
    local sex = User.MapData.Sex;
    local trans = icon.transform;
    if sex == 0 then
        trans.localPosition = Vector3.New(-512,0,0);
        trans.localEulerAngles = Vector3.New(0,-180,0);
    end
end

--设置阶段
function My:SetStage(rbLev)
    local done = self:ChkRbReady();
    if done == true then
        self:SetRbthReady();
        return;
    end
    local stage = RebirthMsg.Progress + 1;
    self:SetStageText(rbLev,stage);
    self:SetCurTask(rbLev,stage);
end

--设置阶段文本
function My:SetStageText(rbLev,stage)
    local curTurn = self:IsCurTurn(rbLev);
    self:SetRbthDone(curTurn);
    if curTurn == false then
        return;
    end

    if stage == 1 then
        self.StageLbl.text = "第一阶段";
    elseif stage == 2 then
        self.StageLbl.text = "第二阶段";
    elseif stage == 3 then
        self.StageLbl.text = "第三阶段";
    elseif stage == 4 then
        self.StageLbl.text = "第四阶段";
    elseif stage == 5 then
        self.StageLbl.text = "第五阶段";
    else
        self.StageLbl.text = "任务已经超了五个阶段";
    end
end

--设置转生准备好
function My:SetRbthReady()
    self.StageLbl.gameObject:SetActive(false);
    self.DoBtnG:SetActive(true);
    self.RbDone:SetActive(true);
    self:SetDoBtnLbl("确认转生");
end

--设置转生完成
function My:SetRbthDone(curTurn)
    self.StageLbl.gameObject:SetActive(curTurn);
    self.DoBtnG:SetActive(curTurn);
    self.RbDone:SetActive(not curTurn);
    self:SetDoBtnLbl("前往任务");
    return false;
end

--设置按钮内容
function My:SetDoBtnLbl(text)
    if self.DoBtnLbl then
        self.DoBtnLbl.text = text;
    end
end

--设置当前任务
function My:SetCurTask(rbLev,stage)
    local curTurn = self:IsCurTurn(rbLev);
    if rbDone == false then
        return;
    end
    local info = Rebirth[rbLev];
    if info == nil then
        return;
    end
    local len = #info.targets;
    if stage <= len then
        local target = info.targets[stage];
        if target == nil then
            return;
        end
        --1 任务类型
        if target.k == 1 then 
            local tskId = tostring(target.v);
            local task = MissionTemp[tskId];
            if task == nil then
                return;
            end
            local text = "";
            local len = #task.talk;
            for i = 1,len do
                text = string.format("%s%s",text,task.talk[i].s);
            end
            self.TaskDesc.text = text;
            self:SetTaskDetail(target.v);
            self:SetQuickBuy(task,rbLev,stage)
        end
    end
end

--设置一键购买
function My:SetQuickBuy(task,rbLev,stage)
    if rbLev ~= 3 then
        self.GetWay.gameObject:SetActive(false)
        return
    end
    if rbLev == 3 and (stage == 1 or stage == 4) then
        self.GetWay.gameObject:SetActive(false)
        return
    end
    -- if rbLev ~= 3 or (stage < 2 and stage > 3) then
    --     self.GetWay.gameObject:SetActive(false)
    --     return
    -- end
    local targetList = task.tarList[1].list
    local needCount = targetList[3]
    local goodsId = targetList[4]
    if targetList == nil or needCount == nil or goodsId == nil then
        iTrace.eError("GS","任务参数目标不存在，转生等级：",rbLev,"任务阶段：",stage)
        return
    end
    self.id = goodsId
    local havePropNum = PropMgr.TypeIdByNum(goodsId)
    local num = needCount - havePropNum
    if num > 0 then
        self.num = num
        self.QuickCollider.enabled = true
        self.QuickBtn.enabled = true
        self.QuickSprite.color = Color.New(1,1,1,1)
    else
        self.num = 0
        self.QuickCollider.enabled = false
        self.QuickBtn.enabled = false
        self.QuickSprite.color = Color.New(0,0,0,1)
    end
    self.GetWay.gameObject:SetActive(true)
end

function My:QuickBuyClick(go)
    if self.num <= 0 then
        return
    end
    StoreMgr.TypeIdBuy(self.id,self.num)
end


--设置详细任务
function My:SetTaskDetail(tskId)
    self.curTarkId = tskId;
    local mission =MissionMgr:GetMissionForID(tskId);
    if mission == nil then
        return;
    end
    local detail = mission:GetTargetDes("bfad77");
    self.TaskDetail.text = detail;
    if mission.Status == MStatus.ALLOW_SUBMIT then
        self:SetDoBtnLbl("提交任务");
    end
end

--当前任务是否完成
function My:CommitTask()
    local tskId = self.curTarkId;
    if tskId == nil then
        return false;
    end
    local mission =MissionMgr:GetMissionForID(tskId);
    if mission == nil then
        return false;
    end
    if mission.Status == MStatus.ALLOW_SUBMIT then
        MissionNetwork:ReqCompleteMission(tskId)
        return true;
    end
end

--设置属性提升
function My:SetAttPro(rbLev)
    local info = Rebirth[rbLev];
    if info == nil then
        return;
    end
    local len = #info.getAttrs;
    for i = 1,4 do
        local title = self.AttProsTitle[i];
        local value = self.AttProsValue[i];
        if i <= len then
            local attr = info.getAttrs[i];
            local propName = self:GetPropName(attr.k);
            if propName ~= nil then
                title.gameObject:SetActive(true);
                value.gameObject:SetActive(true);
                title.text = propName;
                value.text = string.format("+%s",attr.v);
            end
        else
            title.gameObject:SetActive(false);
            value.gameObject:SetActive(false);
        end
    end
end

--获取属性名
function My:GetPropName(id)
    local info = PropName[id];
    if info == nil then
        return nil;
    else
        return info.name;
    end
end

--设置技能
function My:SetSkills(rbLev)
    self:ResetSksRoot();
    self:SetOneTSkills(rbLev);
    self:SetTwoTSkills(rbLev);
    self:SetThrSkills(rbLev);
end

--重置技能根节点
function My:ResetSksRoot()
    self.OneTurn:SetActive(false);
    self.TwoTurn:SetActive(false);
    self.ThrTurn:SetActive(false);
end

--设置一转技能
function My:SetOneTSkills(rbLev)
    if rbLev ~= 1 then
        return;
    end
    self.OneTurn:SetActive(true);
    local mstate,wstate = self:GetSexState();
    self.OTMLevSkill:SetActive(mstate);
    self.OTWLevSkill:SetActive(wstate);
end

--设置二转技能
function My:SetTwoTSkills(rbLev)
    if rbLev ~= 2 then
        return;
    end
    local mstate,wstate = self:GetSexState();
    self.TwoTurn:SetActive(true);
    self.TwTMLevSkill:SetActive(mstate);
    self.TwTWLevSkill:SetActive(wstate);
    self.TwTMOpenSkills:SetActive(mstate);
    self.TwTWOpenSkills:SetActive(wstate);
end

--设置三转技能
function My:SetThrSkills(rbLev)
    if rbLev ~= 3 then
        return;
    end
    self.ThrTurn:SetActive(true);
    local mstate,wstate = self:GetSexState();
    self.ThrTMOpenSkills:SetActive(mstate);
    self.ThrTWOpenSkills:SetActive(wstate);
    self:SetStageAtt(rbLev);
end

--设置阶段属性
function My:SetStageAtt(rbLev)
    local info = Rebirth[rbLev];
    if info == nil then
        return;
    end

    local stage = RebirthMsg. Progress + 1;
    local stageInfo = info.stageAttrs[stage];
    if stageInfo == nil then
        return;
    end
    local len = #stageInfo.attrs;
    for i = 1,4 do
        local title = self.StageAttsTitle[i];
        local value = self.StageAttsValue[i];
        if i <= len then
            local attr = stageInfo.attrs[i];
            local propName = self:GetPropName(attr.k);
            if propName ~= nil then
                title.gameObject:SetActive(true);
                value.gameObject:SetActive(true);
                title.text = propName;
                value.text = string.format("+%s",attr.v);
            end
        else
            title.gameObject:SetActive(false);
            value.gameObject:SetActive(false);
        end
    end
end

--获取性别状态
function My:GetSexState()
    local category = User.MapData.Category;
    local wstate = false;
    local mstate = false;
    if category == 1 then
        mstate = false;
        wstate = true;
    elseif category == 2 then
        mstate = true;
        wstate = false;
    end
    return mstate,wstate;
end

--接受试炼
function My:DoTask(go)
    local tskCanCmmt = self:CommitTask();
    if tskCanCmmt == true then
        return;
    end

    local done = self:ChkRbReady();
    if done == true then
        RebirthMsg:SendRbDone();
        return;
    end
    
    local stage = RebirthMsg.Progress + 1;
    local rbLev = RebirthMsg.RbLev + 1;
    local curTurn = self:IsCurTurn(rbLev);
    if curTurn == false then
        return;
    end
    local info = Rebirth[rbLev];
    if info == nil then
        return;
    end
    if User.MapData.Level < info.limLev then
        UITip.Log("角色等级不足!");
        return;
    end
    local len = #info.targets;
    if stage <= len then
        local target = info.targets[stage];
        if target == nil then
            return;
        end
        --1 任务类型
        if target.k == 1 then
            Hangup:SetAutoHangup(true);
            MissionMgr:AutoExecuteActionOfID(target.v);
            self:Close();
        end
    end
end

--设置四转
function My:SetFourTurn()
    
end

function My:CloseC(go)
    self:Close();
end

return My;