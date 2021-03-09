UIFamilyWar = UIBase:New{Name = "UIFamilyWar"}

local M = UIFamilyWar

function M:InitCustom()
    self.nameList = {}
    self.rankList = {}
    self.Day = {Monday = "一", Tuesday = "二", Wednesday = "三", Thursday = "四", Friday = "五", Saturday = "六", Sunday = "日"}
    self:InitUserData()
    self:SetLsnr("Add")
    self:ReqFamWar()
end

function M:InitUserData()
    local root = self.root
    local SC = UITool.SetLsnrClick
    local G = ComTool.Get

    self.des = G(UILabel, root, "Des")
    self.nextMatch = G(UILabel, root, "NextMatch")
    self.time = G(UILabel, root, "Time")

    local grid = TransTool.Find(root, "Grid")
    for i=1,8 do      
        table.insert(self.nameList, G(UILabel, grid, tostring(i)))
        table.insert(self.rankList, G(UILabel, grid, "Label_"..i))
    end

    SC(root, "BtnClose", self.Name, self.Close, self)
    SC(root, "BtnJoin", self.Name, self.OnJoin, self)
    SC(root, "BtnKing", self.Name, self.OnKing, self)
    SC(root, "BtnHelp", self.Name, self.OnHelp, self)
    self.BtnKingdrop = TransTool.FindChild(root,"BtnKing/drop")
    self.BtnKingdrop:SetActive(FamilyMgr:RedTempDropCheck( ));
end

function M:SetLsnr(key)
    local mgr = FamilyWarMgr
    mgr.eUpdateFamWar[key](mgr.eUpdateFamWar, self.UpdateFamWar, self)
end

function M:ReqFamWar()
    FamilyWarMgr:ReqFamilyWarQua()
end

function M:UpdateFamWar(msg)
    local list = self.nameList
    local rankList = self.rankList
    local len = #list
    local data = msg.list
    table.sort(data, function(a,b) return a.id < b.id end)
    for i=1,len do
        list[i].text = data[i] and data[i].str or ""
    end

    if msg.round == 2 then
        local str = list[2].text
        list[2].text = list[3].text
        list[3].text = str

        str = list[6].text
        list[6].text = list[7].text
        list[7].text = str

        rankList[2].text = "第三名"
        rankList[3].text = "第二名"
        rankList[6].text = "第七名"
        rankList[7].text = "第六名"
    end

    self.nextMatch.text = string.format("[f4ddbd]您下一轮需要对战的道庭：[-][f39800]%s[-]", msg.opponent)
   
    local temp = GlobalTemp["36"].Value2
    local dataTime = DateTool.GetDate(msg.open_time)
    local week = tostring(dataTime.DayOfWeek)
    local t1 = dataTime:ToString("HH:mm")
    local atime = temp[1]+temp[2]
    local t2 = DateTool.GetDate(msg.open_time + atime):ToString("HH:mm")
    local t3 = DateTool.GetDate(msg.open_time + atime+ temp[3]):ToString("HH:mm")
    local t4 = DateTool.GetDate(msg.open_time + 2*atime+ temp[3]):ToString("HH:mm")

    local Day = {Monday = 1, Tuesday = 2, Wednesday = 3, Thursday = 4, Friday = 5, Saturday = 6, Sunday = 7}
    local DateTime = System.DateTime
    local today = DateTime.Today
    local beg = TimeTool.Beg
    local key = tostring(today.DayOfWeek)
    local _end = today:AddDays(8-Day[key])
    local weekEnd = (_end-beg).TotalSeconds
    local str = msg.open_time > weekEnd and "下" or "本"

    self.time.text = string.format("[99886b]道庭战：[00ff00]%s周%s[-]      第一轮时间：[00ff00]%s-%s[-]      第二轮时间：[00ff00]%s-%s[-][-]", str, self.Day[week], t1, t2, t3, t4)

    self.des.text = string.format("[99886b]取道庭战力前八名，每周更新一次，截止时间：[00ff00]%s周%s20:00[-]\n神级赛区前三名将获得主宰神殿的掌控权[-]", str, self.Day[week])   
end

--玩法介绍
function M:OnHelp()
    UIComTips:Show(string.format("[f4ddbd]%s[-]", InvestDesCfg["11"].des), Vector3(-108,-110,0))
end

--主宰神殿
function M:OnKing()
    UITemple.OpenCheck()
end

--加入战场
function M:OnJoin()
    FamilyWarMgr:ReqEnter()
end

--特殊的开启条件
function M:GetSpecial()
	return CustomInfo:IsJoinFamily()
end

--打开分页
function M:OpenTabByIdx(t1,t2,t3,t4)

end

function M:Clear()
    TableTool.ClearDic(self.nameList)
    self.nameList = nil
    TableTool.ClearDic(self.rankList)
    self.rankList = nil
    TableTool.ClearDic(self.Day)
    self.Day = nil
end

--自定义释放
function M:DisposeCustom()
    self:SetLsnr("Remove")
end

return M