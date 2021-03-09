--[[
幸运鉴宝
]]
require("UI/ItemModel/DisplayModel")
require("UI/Cmn/UIItemsTable")
UILuckFull = UIBase:New{Name="UILuckFull"}
local My = UILuckFull

--初始化
function My:InitCustom()
    local CG = ComTool.Get
    local TF, TFC = TransTool.Find, TransTool.FindChild
    local U = UITool.SetBtnClick
    local trans, des = self.root, self.Name

    self.uiTbl=CG(UITable,trans,"Panel/items",des) --道具
    self.timeLab=CG(UILabel,trans,"timeLab",des)  --计时器
    self.xiyouTran=TF(trans,"sprite")       --超级奖励
    local conGoldLbl = CG(UILabel,trans,"goldTex/lab",des)  --消耗元宝数量
    conGoldLbl.text = LuckFullMgr:GetOneConGold()

    self.modName =CG(UILabel,trans,"bg9/Label",des) --模型名字
    self.slider=CG(UISlider,trans,"slider",des) --幸运值滑动条
    self.rateLbl =CG(UILabel,trans,"slider/labelLuck",des) --幸运值文字进度
    local addLuckLbl=CG(UILabel,trans,"bgs/lb7",des) -- +10幸运值
    addLuckLbl.text = "+" .. LuckFullMgr:GetAddLuck()

    self.onceIcon=CG(UITexture,trans,"goldTex",des)  --消耗货币图标
    self.autoLabel =CG(UILabel,trans,"btn2/lbl",des) --自动鉴定



    U(trans,"close",self.Name,self.Close,self)       --关闭窗口
    U(trans,"btn1",self.Name,self.OnOnceBtn,self)    --鉴宝一次
    U(trans,"btn2",self.Name,self.OnTenBtn,self)     --自动鉴宝
    U(trans,"bgs/bg5",self.Name,self.OnClickTipBtn,self)  --活动说明
    self:SetEvent("Add")
    self.model = ObjPool.Get(UIDrawModel)
    self.model:Init(trans.gameObject)


    --倒计时
    self.timer = ObjPool.Get(DateTimer)
    self.timer.invlCb:Add(self.UpdateTimer, self)
    self.timer.complete:Add(self.Close, self)

    self.items = ObjPool.Get(UIItemsTable)
    self.items:Init(self.uiTbl)

    LuckFullMgr:ReqInfo();
    self:InitActivInfo();
    self:SetXyCell()
    self:ShowModel()
    self:InitData()

    
    --true:自动鉴定中
    self.isAuto = false
end

--打开面板获取活动信息
function My:InitActivInfo()
    local info = NewActivMgr:GetActivInfo(LuckFullMgr.sysID);
    if not info then return end
    LuckFullMgr:SaveActivInfo(info);
end

--设置稀有格子
function My:SetXyCell()
    self:ClearXyCell()
    local id = LuckFullMgr.id
    local cfg = BinTool.Find(LuckFullData, id)
    local award = cfg.award
    local xyCell = ObjPool.Get(UIItemCell)
    local pos = self.xiyouTran.position
    xyCell:InitLoadPool(self.xiyouTran, nil, nil, nil, nil)
    xyCell:UpData(award.id, award.cnt, award.bd)
    self.xyCell = xyCell
end

--清理稀有格子
function My:ClearXyCell()
    if self.xyCell then
        self.xyCell:DestroyGo()
        ObjPool.Add(self.xyCell)
    end
    self.xyCell = nil
end

--BEG 倒计时
--开始倒计时
function My:StartTimer()
    local endTm = LuckFullMgr:GetEndTime()
    if endTm > 0 then 
        local sec =  endTm - DateTool.GetServerTimeSecondNow()
        self.timer.seconds = sec
        self.timer:Start() 
    end
end

function My:EndTimer()
    if self.timer then
        self.timer:AutoToPool()
    end
    self.timer = nil
end

function My:UpdateTimer()
    self.timeLab.text = self.timer.remain
end

function My:OpenCustom()
    self:StartTimer()
    self:UpdateTimer()
end

function My:SetAutoLbl(type)
    self.autoLabel.text = (type==1 and "停止鉴宝" or "自动鉴宝")
end

function My:CloseCustom()
    self:StopAuto()
end

--设置事件
function My:SetEvent(fn)
    local mgr = LuckFullMgr
    mgr.eInfo[fn](mgr.eInfo, self.RespInfo, self)
    mgr.eBeg[fn](mgr.eBeg, self.RespBeg, self)
    mgr.eStop[fn](mgr.eStop, self.RespStop, self)
end

--响应信息
function My:RespInfo(msg, idChanged)
    if msg.err_code > 0 then return end
    self:SetIDChanged(idChanged)
end

--响应开始
function My:RespBeg(msg, idChanged)
    if msg.err_code > 0 then 
        self.isAuto = false
        self:SetAutoLbl(0)
    else
        self:SetIDChanged(idChanged)
        self.isAuto = (msg.type == 1)
        self:SetAutoLbl(msg.type)
    end
end

function My:SetIDChanged(idChanged)
    if idChanged then
        self:ClearXyCell()
        self:SetXyCell()
        --self:ClearModel()
        self:ShowModel()
    end
    self:SetLuck()
end

--响应停止
function My:RespStop()
    self:SetAutoLbl(0)
    self.isAuto = false
end

--设置奖励列表
function My:SetCells()
    if self.cells == nil then self.cells = {} end
    if self.itCfgs == nil then self.itCfgs = {} end

    local cell , itCfgs= self.cells, self.itCfgs
    ListTool.Clear(itCfgs)
    for i, v in ipairs(LuckFullData) do
        if v.isTrue < 1 then
            if v.configNum == LuckFullMgr.actInfo.configNum then
                itCfgs[#itCfgs + 1] = v.award
            end
        end
    end

    self.items:Refresh(itCfgs, "id" ,"cnt", "bd")
end

--设置幸运值
function My:SetLuck()
    local luck = LuckFullMgr.luck
    local max = LuckFullMgr:GetLuckMax()
    self.slider.value = (luck / (1.0 * max))
    self.rateLbl.text = luck .. "/" .. max
end

--初始化数据
function My:InitData()
    self:SetLuck()
    self:SetCells()
    self:SetGoldIcon()  
end


--设置货币图标
function My:SetGoldIcon()
    local goldTy =  LuckFullMgr:GetConGoldTy()
    local item1 = UIMisc.FindCreate(goldTy)
    local path1 = item1.icon
    AssetMgr:Load(path1,ObjHandler(self.LoadIcon1,self))
end

--消耗货币对应图标
function My:LoadIcon1(obj)
    self.onceIcon.mainTexture=obj
end

--点击鉴宝一次
function My:OnOnceBtn()
    self:ReqBeg(0)
end

--点击自动鉴定
function My:OnTenBtn()
    if self.isAuto then
        LuckFullMgr:ReqStop()
    else
        self:ReqBeg(1)
    end
end

function My:StopAuto()
    if self.isAuto then
        LuckFullMgr:ReqStop()
    end
    self.isAuto = false
end

--请求鉴宝
function My:ReqBeg(tp)
    local ty, con = LuckFullMgr:GetConGoldTy(), LuckFullMgr:GetOneConGold()
    local IsEnough = RoleAssets.IsEnoughAsset(ty, con)
    if IsEnough then
        LuckFullMgr:ReqBeg(tp)
    else
        StoreMgr.JumpRechange()
    end
end

--点击活动说明
function My:OnClickTipBtn()
    local str = InvestDesCfg["2011"].des
    local pos = Vector3.New(-617,-170,0)
    UIComTips:Show(str, pos, nil, nil, nil, nil, UIWidget.Pivot.TopLeft)
end    


--展示模型
function My:ShowModel()

    local id = LuckFullMgr.id
    local cfg = BinTool.Find(LuckFullData, id)
    local itID = cfg.award.id
    local itCfg = ItemData[tostring( itID)]
    local modelPos = cfg.modelPos;
    local TF = TransTool.FindChild;
    self.modName.text = itCfg.name
    self.model:UpData(itID)
    if modelPos.x ~= nil then
        if self.model.lastTp == 1 then
            local itemPath = self.model.tgList[self.model.lastTp].path;
            local path = StrTool.Concat("bg/DisplayModel/Model/",itemPath);
            if self.root.transform:Find(path) then
                local obj = TF(self.root, path,"");
                obj.transform.localPosition = Vector3.New(modelPos.x,modelPos.y,modelPos.z);
            else
                self.model.tgList[self.model.lastTp].roleSkin.pos.x = modelPos.x;
                self.model.tgList[self.model.lastTp].roleSkin.pos.y = modelPos.y;
                self.model.tgList[self.model.lastTp].roleSkin.pos.z = modelPos.z;
            end
        elseif self.model.lastTp == 2 or self.model.lastTp == 3 or self.model.lastTp == 4 then
            self.model.tgList[self.model.lastTp].go.transform.localPosition = Vector3.New(modelPos.x,modelPos.y,modelPos.z);
        end
    end
end


function My:ClearModel()
    if self.model then
        self.model:Dispose()
    end
    self.model = nil
end

function My:DisposeCustom()
    self:StopAuto()
    self:EndTimer()
    self:SetEvent("Remove")
    ObjPool.Add(self.items)
    self.items = nil
    self:ClearXyCell()
    self:ClearModel()
end

return My