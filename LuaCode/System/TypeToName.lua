--region TypeToName.lua
--Date
--此文件由[HS]创建生成

function GetBasePropertyName(propertyType)
    if propertyType == 0 then
    	return "shengming"	
    elseif propertyType == 1 then
        return "gongji"
    elseif propertyType == 2 then
        return "fangyu"
    elseif propertyType == 3 then
        return "mingzhong"
    elseif propertyType == 4 then
        return "shanbi"
    elseif propertyType == 5 then
        return "baoji"
    end
    return ""
end

function GetProName(t)
	if t == ProType.HP then
		return "生命"
	elseif t == ProType.Atk then
		return "攻击"
	elseif t == ProType.Def then
		return "防御"
	elseif t == ProType.Arp then
		return "破甲"
	elseif t == ProType.Hit then
		return "命中"
	elseif t == ProType.Miss then
		return "闪避"
	elseif t == ProType.Crit then
        return "暴击"    
    elseif t == ProType.Crit_Anti then                           
        return "韧性"
    elseif t == ProType.Hurt_Rate then                                                    
        return "加伤"
    elseif t == ProType.Hurt_Derate then                                                    
        return "免伤"
    elseif t == ProType.Cirt_Doubel then                                                    
        return "暴击几率"
    elseif t == ProType.Crit_Multi then                                                      
        return "暴伤"
    elseif t == ProType.Miss_Double then                                                     
        return "躲闪几率"
    elseif t == ProType.Crit_Multi_anti then                                                       
        return "暴免"
    elseif t == ProType.Role_Def then                                                  
        return "人物护甲"
    elseif t == ProType.Skill_Add then                                                     
        return "技能伤害增加"
    elseif t == ProType.Skill_Reduce then                                                      
        return "技能伤害减少"
    elseif t == ProType.ATTR_MOVE_SPEED then                                                      
        return "移动速度"
    elseif t == ProType.Kill_Monster_Exp_Add_Buff then                                                      
        return "经验加成"
    elseif t == ProType.Metal_Atk then
        return "金攻"
    elseif t == ProType.Wood_Atk then
        return "木攻"
    elseif t == ProType.Water_Atk then
        return "水攻"
    elseif t == ProType.Fire_Atk then
        return "火攻"
    elseif t == ProType.Soil_Atk then
        return "土攻"
	end
	return ""
end

function GetSkillTypeName(skillType)
    if skillType == 1 then return "主动" 
    elseif skillType == 2 then return "被动"
    end
    return "普通"
end

function GetSkillTargetTypeName(skillTargetType)
    if skillTargetType == 1 then return "友方"
    elseif skillTargetType == 2 then return "自己"
    elseif skillTargetType == 4 then return "敌方"
    end
    return "全体"
end

function GetCurrencyTypeName(t)
    if t == CostType.Copper then
        return "银两"
    elseif t == CostType.Glod then
        return "非绑定元宝"
    elseif t == CostType.AnyGlod then
        return "绑元"
    end
    return "货币"
end

function GetDiffTypeName(t)
    if t == 1 then
        return "简单"
    elseif t == 2 then
        return "普通"
    elseif t == 3 then
        return "困难"
    elseif t == 4 then
        return "噩梦"
    elseif t == 5 then
        return "地狱"
    elseif t == 6 then
        return "炼狱"
    elseif t == 7 then
        return "深渊"
    end
    return "无难度"
end


function GetFightStatusTitle(type)
	if type == FightStatus.PeaceMode then
		return "和平"
	elseif type == FightStatus.ForceMode or type == FightStatus.CampMode then
		return "强制"
	elseif type == FightStatus.AllMode then
        return "全体"
    elseif type == FightStatus.CrsSvrMode then
        return "跨服"
    elseif type == FightStatus.BossExclusive then
        return "专属"
	end
	return nil
end


--lab颜色与品质一致
function GetItemQualityName(qua)
    local name = nil
    if (qua == 1)then --白
        name = "白色装备"
    elseif(qua == 2)then --蓝
        name = "蓝色装备"
    elseif(qua == 3)then --紫
        name = "紫色装备"
    elseif(qua == 4)then --橙
        name = "橙色装备"
    elseif(qua == 5)then --红
        name = "红色装备"
    elseif(qua == 6)then --粉
        name = "粉色装备"
    else
        name = "全部装备"
    end
    return name
  end
--endregion


--获取等阶字符
function GetItemStepName(st)
    if type(st) ~= "number" then return "err" end
    if st == 1 then
      return "一阶"
    elseif st == 2 then
      return "二阶以下"
    elseif st == 3 then
      return "三阶以下"
    elseif st == 4 then
      return "四阶以下"
    elseif st == 5 then
      return "五阶以下"
    elseif st == 6 then
      return "六阶以下"
    elseif st == 7 then
      return "七阶以下"
    elseif st == 8 then
      return "八阶以下"
    elseif st == 9 then
      return "九阶以下"
    elseif st == 10 then
      return "十阶以下"
    elseif st == 11 then
      return "十一阶以下"
    elseif st == 12 then
      return "十二阶以下"
    elseif st == 13 then
      return "十三阶以下"
    elseif st == 14 then
      return "十四阶以下"
    elseif st == 15 then
      return "十五阶以下"
    else
      return "任意品阶"
    end
end
