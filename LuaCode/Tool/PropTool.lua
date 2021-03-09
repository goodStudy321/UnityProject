--[[
 	author 	    :Loong
 	date    	:2018-01-18 10:15:40
 	descrition 	:属性工具
--]]

local attNAME = {"hp", "atk", "def", "arm","hit","dodge","crit",
                "tena","critdam","resil","ampdam","damred","critpro",
                "dodgepro","critdef","addskilldam","reduceskilldam",
                "hpadd","atkadd","defadd","armadd","hitadd",
                "dodgeadd","critadd","tenaadd","exp","speed","rolearmor"}
PropTool = {}

local My = PropTool

--k:nLua,v:PropName条目
My.dic = {}

function My.Init()
  local cfg = PropName
  if cfg == nil then return end
  local dic = My.dic
  for k, v in pairs(cfg) do
    local nLua = v.nLua
    if nLua then
      dic[nLua] = v
    end
  end
end

--通过lua字段名获取属性字段配置
function My.Get(nLua)
  local it = My.dic[nLua]
  return it
end

--通过lua字段名获取属性字段名称
function My.GetName(nLua)
  local it = My.dic[nLua]
  local name = it and it.name or ("无:" .. nLua)
  return name
end

--通过ID获取属性字段名称
function My.GetNameById(id)
  local it = BinTool.Find(PropName, id)
  local res = it and it.name or ("无:" .. tostring(id))
  return res
end

--通过配置条目,设置对应的属性字段列表
--names(table):属性字段列表
--cfgIt(table):具有属性配置的条目
function My.SetNames(cfgIt, names)
  if type(cfgIt) ~= "table" then return end
  if names == nil then
    names = {}
  else
    ListTool.Clear(names)
  end
  for k, v in pairs(PropName) do
    local nLua = v.nLua
    if nLua then
      if cfgIt[nLua] then
        names[#names + 1] = nLua
      end
    end
  end
  return names
end

--获取属性值的字符串
--cfg:属性字段配置条目
--val:值
function My.GetVal(cfg, val)
  if cfg == nil then return "no" end
  local show = cfg.show or 0
  local str = nil
  if show == 1 then
    val = val * 0.01
    str = string.format("%.2f%%", val)
    local old = string.sub( str,#str-1,#str-1)
    if old=="0" then 
      str = string.format("%.1f%%", val) 
      old = string.sub( str,#str-1,#str-1)
      if old=="0" then 
        str = string.format("%s", val) 
        str=str.."%"
      end
    end
  else
    str = tostring(val)
  end
  return str
end

--通过lua字段获取属性值的字符串
--return格式化后的字符串
--nlua:lua字段名
--val:属性值
function My.GetValByNLua(nLua, val)
  local it = My.dic[nLua]
  return My.GetVal(it, val)
end

--通过属性ID获取属性值的字符串
--return格式化后的字符串
--nlua:lua字段名
--val:属性值
function My.GetValByID(id, val)
  local it = BinTool.Find(PropName, id)
  return My.GetVal(it, val)
end

--计算战斗力
--cfg:包含属性配置的条目
--names:属性名称列表(默认获取基础属性)
function My.GetFight(cfg, names)
  if cfg == nil then return 0 end
  if not names then names=attNAME
  elseif type(names) ~= "table" then return 0 end
  local GetFight = My.PropFight
  local dic = My.dic
  local total = 0
  for i, v in ipairs(names) do
    local it = dic[v]
    if it == nil then return total end
    local id = it.id
    local val = cfg[v] or 0
    local ft = GetFight(id, val)
    total = total + ft
  end
  return total
end

--将{hp=9000, atk=0, def=200, arm=0} 转化为{{k,v}} val为0 ，不转换
function My.SwitchAttr(cfg)
  local list = {}
  for i=1,#attNAME do
    local val = cfg[attNAME[i]]
    if val and val > 0 then
      local kv = {}
      kv.k = i
      kv.v = val
      table.insert(list, kv)
    end
  end
  return list
end

--当前属性和下阶属性显示
function My.CompareAttr(curCfg,nextCfg)
  local list = {}
  for i = 1,#attNAME do
    local curVal = curCfg[attNAME[i]]
    local nextVal = nextCfg[attNAME[i]]
    if curVal and curVal > 0 then
      local kv = {}
      kv.k = i
      kv.curVal = curVal
      kv.nextVal = nextVal
      table.insert(list,kv)
    end
  end
  return list
end

--通过属性列表计算战斗力
function My.GetFightByList(props)
  if type(props) ~= "table" then return 0 end
  local GetFight = My.PropFight
  local total = 0
  local ft = 0
  for i, v in ipairs(props) do
    ft = GetFight(v.k, v.v)
    total = total + ft
  end
  return math.floor(total)
end

--通过属性列表计算战斗力
function My.GetFightByList2(props)
  if type(props) ~= "table" then return 0 end
  local GetFight = My.PropFight
  local total = 0
  local ft = 0
  for i, v in ipairs(props) do
    ft = GetFight(v.id, v.val)
    total = total + ft
  end
  return total
end

--id:属性id  val:属性值
function My.PropFight(id, val)
  if(val == 0)then return 0 end
  local pro = BinTool.Find(PropName, id)
  if(pro == nil)then iTrace.Error("xiaoyu", "属性为空 id:".. id)return 0 end
  local fight = pro.fight
  if(pro.fight==nil)then return 0 end
  local total = 0
  total = fight * val
  return total
end



-------------------------------------
--==============================--
--desc:装备评分=（装备基础属性总战力）*（10000+装备极品属性评分之和）/10000
--装备基础属性总战力=基础战力+卓越属性
--time:2018-08-10 04:23:08
--@tb:
--@return  1.属性总战力
--         2.装备极品属性评分之和
--         3.卓越星级属性列表颜色 key:属性id value:品质
--==============================--
local colorDic={} --value:k属性id v属性值 b品质
local att1,att3=0
function My.EquipTbFight(tb)
    --清理数据
    TableTool.ClearDicToPool(colorDic)

    local id = tostring(tb.type_id)
    local item = ItemData[id]
    local equip = EquipBaseTemp[id]

    local part=equip.wearParts
    local qua=item.quality
    local star=equip.startLv
    
    --基础属性
    att1=My.GetFight(equip)
    
    --极品属性之和
    att3=0

    --卓越属性颜色
    local dic = tb.eDic
    if not dic then return 0,0,nil end
    for i,v in ipairs(EquipStarTbl) do
        local parts=v.part
        for i1,v1 in ipairs(parts) do
            if v1==part then
                if qua==v.qua and star==v.star then
                    local atts = v.att
                    attList=atts
                    for i2,v2 in ipairs(atts) do
                        local star = EquipStar[tostring(v2)]
                        for k,v3 in pairs(dic) do
                            local key = tostring(i).."_"..k
                            if not colorDic[key] then
                              local prop = PropName[tonumber(k)]
                              local nLua = prop.nLua
                              local va=star[nLua]
                              if va and va[2]==v3 then
                                att3=att3+va[3]
                                local kv = ObjPool.Get(KV)
                                kv:Init(k,v3,star.qua)
                                colorDic[key]=kv
                              end
                            end
                        end
                    end
                end
            end
        end
    end

    return att1,att3,colorDic
end

function My.Fight(obj)
  local a1,a2,list 
  if type(obj)=="table" then 
    a1,a2,list=My.EquipTbFight(obj) 
  else
    a1,a2,list=My.EquipFight(obj)
  end 
  local fight=math.floor(a1*(10000+a2)/10000)
  return fight
end


local index = 0
My.attArgs = {"defadd","hpadd","damred","atkadd","armadd","ampdam","critpro","lv_atk","lv_arm","lv_hp","lv_def","money_drop","item_drop","critdef","dodgepro"}
function My.EquipFight(id)
    --清理数据
    TableTool.ClearDicToPool(colorDic)

    local id = tostring(id)
    local item = ItemData[id]
    local equip = EquipBaseTemp[id]

    local part=equip.wearParts
    local qua=item.quality
    local star=equip.startLv

    --基础属性
    att1=My.GetFight(equip)

    --极品属性之和
    att3=0

     --卓越属性颜色
    for i,v in ipairs(EquipStarTbl) do
        local parts=v.part
        for i1,v1 in ipairs(parts) do
            if v1==part then
                if qua==v.qua and star==v.star then
                    local atts = v.att
                    index=0
                    for i2,v2 in ipairs(atts) do
                        local att=EquipStar[tostring(v2)]
                        if not att then iTrace.eError("xiaoyu","装备星级属性表为空 id: ".. v2)return end
                        My.RandomAtt(att)
                    end
                end
            end
        end
    end
    return att1,att3,colorDic
end

function My.RandomAtt(att)
    index=index+1
    local nLua = My.attArgs[index]
    local val = att[nLua]
    if val then
        local pro = My.Get(nLua)
        local id = tostring(pro.id)
        att3=att3+val[3]
        local kv = ObjPool.Get(KV)
        kv:Init(id,val[2],att.qua)
        colorDic[#colorDic+1]=kv
        return
    else
        My.RandomAtt(att)
    end
end

--id:属性id  val:属性值  count:数量
function My.PropAllFight(id, val, count)
  if(val == 0)then return 0 else val = val * count end
  return My.PropFight(id, val)
end

--通过装备id获取部位
function My.FindPart(type_id)
	local equip = EquipBaseTemp[type_id]
	if(equip==nil)then iTrace.Error("xiaoyu","装备表为空 id:".. type_id)return nil end
	return tostring(equip.wearParts)
end

--获取经验
function My.GetExp(ratio)
  local data=LvCfg[tostring(User.instance.MapData.Level)]
  if data==nil then iTrace.eError("xiaoyu","活动经验表为空 id: ".. User.instance.MapData.Level) return end	
  return ratio*data.exp
end

--等级限制获取经验
function My.LvGetExp(ratio,lv)
  local data=LvCfg[tostring(lv)]
  if data==nil then iTrace.eError("xiaoyu","活动经验表为空 id: "..tostring(lv)) return end	
  return ratio*data.exp
end

--获取装备所有属性
function My.GetEqAttrs(type_id)
  local typeId = tostring(type_id);
  local info = EquipBaseTemp[typeId];
  local attrs = {};
  for i = 1,#attNAME do
    local attr = attNAME[i];
    local val = info[attr];
    if val ~= nil and val > 0 then
      attrs[i] = val;
    end
  end
  return attrs;
end

--属性累加器
function My.AttrAddUp(tbl,subTbl)
  if type(tbl) ~= "table" then
    return;
  end
  if type(subTbl) ~= "table" then
    return;
  end
  for k,v in pairs(subTbl) do
    if v > 0 then
      local val = tbl[k];
      if val == nil then
        val = 0;
      end
      val = val + v;
      tbl[k] = val;
    end
  end
end

--获取属性显示
function My.GetAttrsShow(tbl)
  if type(tbl) ~= "table" then
    return "";
  end
  local des = "";
  for k,v in pairs(tbl) do
    if des ~= "" then
      des = string.format("%s%s",des,"\n");
    end
    local propName = PropName[k];
    if propName ~= nil then
      local name = propName.name;
      name = string.format("%s%s%s","[f4ddbd]",name,"[-]");
      des = string.format("%s%s%s%d%s",des,name," +[00ff00]",v,"[-]");
    end
  end
  return des;
end