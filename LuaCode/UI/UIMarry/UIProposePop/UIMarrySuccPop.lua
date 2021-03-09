--[[
 	authors 	:Liu
 	date    	:2018-12-11 11:15:00
 	descrition 	:提亲成功弹窗
--]]

UIMarrySuccPop = Super:New{Name = "UIMarrySuccPop"}

local My = UIMarrySuccPop

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.lab = CG(UILabel, root, "bg/labBg/lab")
    self.btnLab = CG(UILabel, root, "bg/btn/lab")
    self.name1 = CG(UILabel, root, "bg/texBg1/lab")
    self.name2 = CG(UILabel, root, "bg/texBg2/lab")
    self.btn = FindC(root, "bg/btn", des)
    self.go = root.gameObject

    SetB(root, "bg/btn", des, self.OnClick, self)
    SetB(root, "bg/close", des, self.OnClose, self)

    self:InitData()
    self:InitLab()
    self:InitNameLab()
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

--点击确定/预约婚礼
function My:OnClick()
    local it = UIProposePop
    -- local count = MarryInfo.data.count
    if self.btnLab.text == "确定" then
        self:OnClose()
        it:ResetState()
    else
        UIMarryInfo:OpenTab(3)
        it:ClearState()
    end
end

--点击关闭
function My:OnClose()
    local it = UIProposePop
    it:Close()
    it:ResetState()
end

--初始化文本
function My:InitLab()
    local count = MarryInfo.data.count
    if count < 1 then
        self.lab.text = "提亲【金玉良缘】或【神仙眷侣】即可举办浪漫婚宴，大秀恩爱哦！"
        self.btnLab.text = "确定"
    else
        self.lab.text = "大喜之事怎么能草草了事,赶紧举办一场轰轰烈烈的婚礼把！"
        self.btnLab.text = "立刻预约"
    end
end

--初始化仙侣数据
function My:InitData()
    local data = MarryInfo.data.coupleInfo
    self.data = data
end

--清理缓存
function My:Clear()
    self.data = nil
end

--释放资源
function My:Dispose()
	self:Clear()
end

return My