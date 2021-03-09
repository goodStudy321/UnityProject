Tg2Panel=EquipPanelBase:New{Name="Tg2Panel"}
local My = Tg2Panel

function My:SetEvent(fn)
    EquipMgr.eConciseOpen[fn](EquipMgr.eConciseOpen,self.OnConciseOpen,self)
end

function My:OnConciseOpen(tb,part)
    self:ShowPartTip(part)
end

--文字内容
function My:ShowPartTip(part)
    EquipPanel.str:Dispose()
    local cell = EquipPanel.cellDic[part]
    local tb=EquipMgr.hasEquipDic[part]
    local item = UIMisc.FindCreate(tb.type_id)
    local open = EquipOpenLv[part].lv
    local lv = User.instance.MapData.Level
    local color = lv<open and "[f21919]" or "[f4ddbd]"
    EquipPanel.str:Apd(UIMisc.LabColor(item.quality)):Apd(item.name):Apd("[-]\n"):Apd(color):Apd("开启等级  "):Apd(open):Apd("级")
    cell:UpName(EquipPanel.str:ToStr())
end

--红点
function My:ShowPartRed(part)
    local tb=EquipMgr.hasEquipDic[part]
    local cell = EquipPanel.cellDic[part]
    local redDic=EquipMgr.xilianPartRed
    local red=redDic[tostring(part)]
    cell:OnRed(red)
end

--排序
function My:Sort(partList)
    table.sort(partList, My.SortOpenLv)
end

function My.SortOpenLv(a,b)
    local data1=EquipOpenLv[a]
    local data2=EquipOpenLv[b]
    return data1.lv<data2.lv
end