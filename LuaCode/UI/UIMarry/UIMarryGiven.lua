UIMarryGiven = Super:New{Name = "UIMarryGiven"}

local My = UIMarryGiven

function My:Init(root)
    self.go = root.gameObject
    local des = self.Name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local US = UITool.SetLsnrSelf
    local TFC = TransTool.FindChild
    self.curIndex = 1
    self.selectMaxCount = 6
    self.togsTab = {}
    self.togsRedTab = {}
    self.cellList = {}
    self.selectList = {}
    self.isShowSelect = false
    local togGrid = CG(UIGrid,root,"btnsGrid",des)
    local togCount = togGrid.transform.childCount
    for i = 0,togCount - 1 do
        local index = i + 1
        local tog = CG(UIToggle,togGrid.transform,"tg"..index,des)
        local red = TFC(tog.transform,"red",des)
        self.togsTab[index] = tog
        self.togsRedTab[index] = red
    end
    togGrid:Reposition()

    self.timeLab = CG(UILabel,root,"timeLab",des)
    self.titleLab = CG(UILabel,root,"titleLab",des)
    self.desLab = CG(UILabel,root,"desLab",des)
    self.sendBtn = TFC(root,"btn",des)

    local sendGbj = TF(root,"send",des)
    self.sendDesLab = CG(UILabel,sendGbj,"desLab",des)
    self.input = CG(UIInput, sendGbj, "input",des)
    self.sendNum = CG(UILabel,sendGbj,"num",des)
    self.sendSureBtn = TFC(sendGbj,"btn",des)
    self.sendGbj = sendGbj.gameObject
    self.input.characterLimit = 24

    self.itemGrid = CG(UIGrid,root,"scView/grid",des)
    self.itemPrefab = TFC(root,"scView/grid/Cell",des)
    self.itemPrefab:SetActive(false)

    local sendTipGbj = TF(root,"sendTip",des)
    local tipSureBtn = TFC(sendTipGbj,"btn",des)
    self.sendTipTitleLab = CG(UILabel,sendTipGbj,"titleLab",des)
    self.sendTipDesLab = CG(UILabel,sendTipGbj,"desLab",des)
    local tipCloseBtn = TFC(sendTipGbj,"close",des)
    self.sendTipGbj = sendTipGbj.gameObject


    US(self.togsTab[1].gameObject,self.EquipToggle, self, nil, false)
    US(self.togsTab[2].gameObject,self.SMSToggle, self, nil, false)
    US(self.sendBtn,self.ClickSend, self, nil, false)
    US(self.sendSureBtn,self.ClickSureSend, self, nil, false)
    US(tipSureBtn,self.ClickCloseTip, self, nil, false)
    US(tipCloseBtn,self.ClickCloseTip, self, nil, false)

    -- EventDelegate.Add(self.togsTab[2].onChange, EventDelegate.Callback(self.SMSToggle, self))
    -- EventDelegate.Add(self.togsTab[1].onChange, EventDelegate.Callback(self.EquipToggle, self))
    -- local ED = EventDelegate
    -- ED.Add(self.input.onChange, ED.Callback(self.CheckInput, self))
    self:Open()

    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    MarryMgr.eGivenTime[func](MarryMgr.eGivenTime, self.UpdateTimeLab, self)
    MarryMgr.eGivenSucc[func](MarryMgr.eGivenSucc, self.SendSucc, self)
end

function My:Open()
    self.togsTab[1].value = true
    self.togsTab[2].value = false
    self.desLab.text = InvestDesCfg["2024"].des
    -- self.input.defaultText = "但愿人长久，千里共婵娟！"
    self:SetInputVal()
    self:EquipToggle()
    self:ShowDif()
    local isMarry = MarryInfo:IsMarry()
    if isMarry then
        local isShowTime = MarryMgr:IsCanGiven()
        self.timeLab.gameObject:SetActive(not isShowTime)
    else
        self.timeLab.gameObject:SetActive(false)
    end
end

function My:SetInputVal()
    self.input.value = "但愿人长久，千里共婵娟！"
end

function My:UpdateTimeLab(isEnd)
    local time = MarryMgr.CountDownNum
    local str = string.format("%s后可赠送",time)
    self.timeLab.text = str
    if isEnd then
        self.timeLab.gameObject:SetActive(false)
    end
end

function My:ClickCloseTip()
    self.sendTipGbj:SetActive(false)
end

function My:SendSucc()
    self.sendTipGbj:SetActive(true)
    local index = self.curIndex
    self:UpdateItem(index)
end

function My:UpdateSendNum()
    local len = self:GetSelectLen()
    local str = string.format("%s/%s",len,self.selectMaxCount)
    self.sendNum.text = str
end

function My:EquipToggle()
	self:UpdateItem(1)
end

function My:SMSToggle()
    self:UpdateItem(2)
end

function My:ClickSend()
    local isMarry = MarryInfo:IsMarry()
    if not isMarry then
        UITip.Log("您尚未拥有仙侣")
        return
    end

    local isCanSend = MarryMgr:IsCanGiven()
    if isCanSend == false then
        local str = string.format("请在%s后赠送",MarryMgr.CountDownNum)
        UITip.Log(str)
        return
    end
    self:SetInputVal()
    self.isShowSelect = true
    self:ShowDif()
end

function My:ClickSureSend()
    local list = self.selectList
    local len = #list
    if len == 0 then
        UITip.Log("请选择赠送道具")
        return
    end
    local tempName = self.input.value;
    if tempName == "" then
        self:SetInputVal()
    end
    tempName = self.input.value
	local checkRetName, isIllegal = MaskWord.SMaskWord(tempName);
	if isIllegal == true then
		self.input.value = checkRetName;
		MsgBox.ShowYes("存在非法字符 ！！！");
		return;
	end
    MarryMgr:ReqGiven(list,tempName)
end

function My:ShowDif()
    local isShow = self.isShowSelect
    self.sendGbj:SetActive(isShow)
    self.sendBtn:SetActive(not isShow)
    local tab = self.cellList
    local len  = #tab
    for i = 1,len do
        local it = tab[i]
        it:SetBoxColState(isShow)
        it:SetHighlight(false)
    end
    self:ClearSelectData()
    self:UpdateSendNum()
end

function My:UpdateItem(index)
    index = index or 1
    local tab = nil
    if index == 1 then
        tab = MarryMgr:GetGivenEquipData()
    elseif index == 2 then
        tab = MarryMgr:GetGivenSMSData()
    end
    self.curIndex = index
    self.isShowSelect = false
    local len = #tab
    local list = self.cellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(tab[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.itemPrefab)
            TransTool.AddChild(self.itemGrid.transform,go.transform)
            local item = ObjPool.Get(UIMarryGivenIt)
            item.cntr = self
            item:Init(go)
            item.eClick:Add(self.OnClick,self)
            item:SetActive(true)
            item:UpdateData(tab[i])
            table.insert(list, item)
        end
    end
    -- self.sView:ResetPosition()
    self.itemGrid:Reposition()
    self:ShowDif()
end

function My:OnClick(isSelect, data)
    if isSelect then
        local isMax = self:IsMaxSelect()
        if isMax then
            UITip.Log("已达最多选中数量")
            return
        end
        TableTool.Add(self.selectList, data, "id")
    else
        TableTool.Remove(self.selectList, data, "id")
    end
    self:UpdateSendNum()
end

function My:GetSelectLen()
    local len = #self.selectList
    return len
end

function My:IsMaxSelect()
    local isMax = false
    local len = self:GetSelectLen()
    if len >= self.selectMaxCount then
        isMax = true
    end
    return isMax
end

function My:ClearSelectData()
    TableTool.ClearDic(self.selectList)
end

--清理缓存
function My:Clear()
    self.curIndex = 1
    self.isShowSelect = false
    self:ClearSelectData()
end

--释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearListToPool(self.cellList)
    self:SetLnsr("Remove")
end

return My