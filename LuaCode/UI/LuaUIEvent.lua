--[[
 	author 	    :Loong
 	date    	:2018-02-05 21:42:57
 	descrition 	:LuaUI事件
--]]

LuaUIEvent = {Name = "LuaUIEvent"}

local My = LuaUIEvent

--UICamera中的全局点击事件
My.euionclick = Event()

function My.Init()
  EventTool.Add(UICamera, "onClick", My.OnClick)
end

function My.OnClick(go)
  My.euionclick(go)
  local check = My.Check(go);
  if check == true then
    return;
  end
  Audio:PlayByID(100)
end

function My.Check(go)
  if go == nil then
    return false;
  end
  local name = go.name;
  for i = 1,4 do
    local uiName = string.format("Skill_%s",i);
    if name == uiName then
      return true;
    end
  end
  if name == "SkillAttack" then
    return true;
  end
  return false;
end

return My
