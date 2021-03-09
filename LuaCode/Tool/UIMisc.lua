--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-01-04 12:14:59
-- UI混杂工具
--=========================================================================
require("Tool/ColorCode")
UIMisc = {Name="UIMisc"}
local strList = {"零","一","二","三","四","五","六","七","八","九","十"}


local My = UIMisc
local numStr=ObjPool.Get(StrBuffer)

--st(number):等级
--return(string):返回等级数字
function My.GetStep(st)
  if st > 9 then
    return "shi"
  else
    return tostring(st)
  end
end

--通过条目索引设置背景精灵
--it:条目
--at(boolean):true:选中
function My.SetListItemSp(it, at)
  if it.hlSp == nil then return end
  local idx = it.idx or 0
  local res = idx%2
  local bgSp = (res == 0 and "ty_a19" or "ty_a19")
  local sp = at and "ty_a12" or bgSp
  it.hlSp.spriteName = sp
end

--获取等阶字符
function My.GetStepStr(st)
  if type(st) ~= "number" then return "err" end
  return My.NumToStr(st,"阶")
end

--x要转换成中文数字的，add要添加的后缀
function My.NumToStr(x,add)
  numStr:Dispose()
  local ss = tostring(x)
  local count = string.len(ss)
  for i=1,count do
    local s = tonumber(string.sub( ss, i,i))
    if count==1 then
      numStr:Apd(My.ToNum(s))
    elseif count==2 then 
      if i==1 then --首
        if s==1 then
          numStr:Apd("十")
        else
          numStr:Apd(My.ToNum(s)):Apd("十")
        end
      elseif i==count then --尾
        if s~=0 then numStr:Apd(My.ToNum(s)) end
      else
        numStr:Apd(My.ToNum(s))
      end
    end
  end
  if add then numStr:Apd(add) end
  return numStr:ToStr()
end

function My.ToNum(s)
  return strList[s+1]
end

--数字转换
function My.ToString(num,ignore)
  if not num then return end
  local text,is01 = nil,nil
  if ignore~=false then 
    text,is01=My.IgNore01(num)
  end
  if is01~=true and type(num)=="number" then 
    if(num>=10^8)then 
      local y,yy=math.modf(num/10^8)
      text=yy<0.1 and y or string.format("%.1f",num/10^8)				
      text=text.."亿"
    elseif(num>=10^4)then
      local y,yy=math.modf(num/10^4)
      text=yy<0.1 and y or string.format("%.1f",num/10^4)				
      text=text.."万"
    end
  end
  if StrTool.IsNullOrEmpty(text) and is01~=true then 
    if type(num)=="number" then 
      text=tostring(num) 
    else 
      text=num 
    end
  end
  return text
end

function My.IgNore01(text)
  local str = tostring(text)
  if str=="1" or str=="0" then return "",true end
  return text,false
end

--设置子界面的父/根界面,并调用初始化
--p:父界面,c:子界面
--rn:子界面根结点路径
--add:默认false,true:添加到子界面列表中
function My.SetSub(p, c, rn, add)
  if p == nil then return end
  if c == nil then return end
  c.cntr = p
  c.rCntr = p.rCntr or p
  if c.Init then
    local root = TransTool.Find(p.root, rn, p.Name)
    c:Init(root)
  end
  add = add or false
  if not add then return end
  local cPages = p.cPages
  if cPages == nil then
    cPages = {}
    p.cPages = cPages
  end
  cPages[#cPages + 1] = c
end

--递归设置子界面的数据字段
function My.SetDB(self, db)
  if db == nil then return end
  local cPages = self.cPages
  if cPages == nil then return end
  for i, v in ipairs(cPages) do
    v.db = db
    My.SetDB(v, db)
  end
end

--递归清除所有子界面的数据字段
function My.ClearSub(self)
  local cPages = self.cPages
  if cPages == nil then return end
  if #cPages < 1 then return end
  for i, v in ipairs(cPages) do
    My.ClearSub(v)
  end
  ListTool.Clear(cPages)
end

--设置UI激活
--at(boolean):true:调用Open,false:调用Close
function My.SetActive(self, at)
  at = at or false
  if at then
    self:Open()
  else
    self:Close()
  end
end

--设置选择当前条目,取消上个选择条目
--self:容器
--it:条目
function My.SetSelect(self, it)
  if it == nil then return end
  local cur = self.cur
  if it == cur then return end
  if cur then cur:SetSelect(false) end
  it:SetSelect(true)
  self.cur = it
end

--获取品质 图集在Atlas_cell里面
function My.GetQuaPath(qua)
  return "cell_"..qua
end

function My.GetBgQuaPath(qua)
  return "cell_a0"..qua
end

local colorList = {"[FFFFFF]","[008ffc]","[b03df2]","[f39800]","[f21919]","[ff66fc]"}
local colorLabList = {"白色","蓝色","紫色","橙色","红色","粉色"}
local equipTypeList = {"装备","材料","消耗品","神兽装备","战灵装备"}
local partList= {"武器","护腕","头盔","衣服","裤子","鞋子","护符","项链","戒指","手镯","精灵","仙女"}
local workList = {"沉鱼宫","圣道宗"}
local rbWork1 = {"英招圣女","天英神女","飞云天仙","天华真仙","九天玄仙","太皇天后"}
local rbWork2 = {"太一真人","伏魔元帅","蛮荒战神","鸿蒙君主","擎天大帝","元始天尊"}
--lab颜色与品质一致
function My.LabColor(qua)
  ----白--蓝--紫--橙--红--粉
  local col = colorList[qua] or "[FF0000]"
  return col
end

function My.GetColorLb(qua)
  local col = colorLabList[qua] or ""
  return col
end


function My.GetType(type)
  local name = equipTypeList[type] or ""
  return name
end


--穿戴部位
function My.WearParts(wear)
  local str = partList[wear] or ""
  return str
end

--职业
function My.GetWork(w)
  local x = workList[w] or "通用"
  return x
end

function My.GetRBPN(sex, rbLev)
  if sex == 1 then
    return My.GetSex1(rbLev)
  elseif sex == 2 then
    return My.GetSex2(rbLev)
  end
end

--转生等级
function My.GetSex1(w)
  local x = rbWork1[w] or "通用"
  return x
end

function My.GetSex2(w)
  local x = rbWork2[w] or "通用"
  return x
end

--获取道具图标
function My.GetIcon(type_id)
  if(type(type_id) == "number")then type_id = tostring(type_id)end
  local item = ItemData[type_id]
  if(item == nil)then
    iTrace.sLog("xiaoyu", "道具表为空 id: "..type_id)
    return
  end
  local icon = nil
  local x, y = string.find(item.icon, ".png")
  if x then
    icon = string.sub(item.icon, 1, x - 1)
  end
  return icon
end

--判断点击的方向
--左右中-1 1 0  下上中-1 1 0
function My.GetInputDir()
  local x,y = nil
  local pos = UnityEngine.Input.mousePosition
  local w = Screen.width / 2
  local h = Screen.height / 2
  x=pos.x>w and 1 or -1
  y=pos.y>h and 1 or -1
  return x,y
end

--通过道具id获得道具表（有服务端生成的职业道具）
function My.FindCreate(type_id)
  type_id=tostring(type_id)
	local item = nil
	local tid = tonumber(type_id)
	if tid>70000 and tid<90000 then  --服务端生成的特殊道具
		local c = ItemCreate[type_id]
		if(c==nil)then item=ItemData[type_id] return item end
    local cate = User.instance.MapData.Category
    type_id=cate==1 and tostring(c.w1) or tostring(c.w2)
		item=ItemData[type_id]
	else
		item=ItemData[type_id]
  end
  if not item then iTrace.eError("xiaoyu","道具表为空 id: "..type_id) return  end
	return item
end


function My.GetLv(lv)
  local limitLv = GlobalTemp["90"].Value3
   return lv <=limitLv and lv or string.format("化神%s",lv-limitLv) 
end

function My.CheckErr(errCode)
  if errCode ~= 0 then
  local err = ErrorCodeMgr.GetError(errCode)
      UITip.Log(err)
    return false
  end
  return true
end

function My.LongToNum(num)
  return tonumber(tostring(num))
end

function My.urlEncode(s)  
  s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)  
  return string.gsub(s, " ", "+")  
end  

function My.urlDecode(s)  
  s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)  
  return s  
end 
