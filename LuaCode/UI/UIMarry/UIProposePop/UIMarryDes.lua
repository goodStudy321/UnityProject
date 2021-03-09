--[[
 	authors 	:Liu
 	date    	:2018-12-13 10:00:00
 	descrition 	:结婚详情
--]]

UIMarryDes = Super:New{Name = "UIMarryDes"}

local My = UIMarryDes

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick

    self.name1 = CG(UILabel, root, "texBg1/lab")
    self.name2 = CG(UILabel, root, "texBg2/lab")
    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
    self.lab3 = CG(UILabel, root, "lab3")
    self.lab4 = CG(UILabel, root, "lab4")
    self.go = root.gameObject

    SetB(root, "close", des, self.OnClose, self)

    self:InitData()
    self:InitNameLab()
    self:InitLab()
end

--点击关闭
function My:OnClose()
    local it = UIProposePop
    if it.isBack then
        UIMarry:OpenTab(1)
        it:ClearState()
    else
        UIMarryInfo:OpenTab(1)
    end
end

--初始化文本
function My:InitLab()
    local data = self.data
    if data then
        local info = MarryInfo
        local date, days = self:GetMarryTime()
        local rank, lv = info:GetKnotLv()
        local str2 = string.format("[4A2515FF]结缘天数：[C64756FF]%s天", days)
        local str3 = string.format("[4A2515FF]亲密度：   [C64756FF]%s", info:GetFriendly())
        local str4 = string.format("[4A2515FF]同心结：   [C64756FF]%s阶%s级", rank, lv)
        self.lab1.text = date.."结为夫妻"
        self.lab2.text = str2
        self.lab3.text = str3
        self.lab4.text = str4
    end
end

--获取结婚时间
function My:GetMarryTime()
    local info = MarryInfo
    local times = info.data.marryTime
    local DateTime = System.DateTime
    local date = DateTime.Parse(tostring(DateTool.GetDate(times))):ToString("yyyy年MM月dd日")
    local now = math.floor(TimeTool.GetServerTimeNow()*0.001)
    local days = DateTool.GetDay(now - times) + 1
    return date, days
end

--更新宴会的剩余时间
function My:UpRTime()
	local endTime = self:GetEndTime()
	if endTime > 0 then
		local sTime = math.floor(TimeTool.GetServerTimeNow()*0.001)
		local leftTime = endTime - sTime
		self:UpTimer(leftTime)
	end
end

--初始化名字
function My:InitNameLab()
    local data = self.data
    if data then
        local str1 = ""
        local str2 = ""
          if User.MapData.Sex == 0 then
            str1 = data.name
            str2 = User.MapData.Name
          else
            str1 = User.MapData.Name
            str2 = data.name
          end
          self.name1.text = str1
          self.name2.text = str2
    end
end

--初始化仙侣数据
function My:InitData()
    local data = MarryInfo.data.coupleInfo
    self.data = data
end

--清理缓存
function My:Clear()
    
end
    
--释放资源
function My:Dispose()
    self:Clear()
end
    
return My