--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-09-09 11:16:36
-- 图片工具
--==============================================================================

TexTool = {}

local My = TexTool

--创建图片
--width(number):宽
--height(number):高
--color:颜色
function My.Create(width, height, color)
  if type(width) ~= "number" then return nil end
  if type(height) ~= "number" then return nil end
  if color == nil then return end
  local tex = UnityEngine.Texture2D.New(width, height)
  local wLen = width - 1
  local hLen = height - 1
  for i = 0, wLen do
    for j = 0, hLen do
      tex:SetPixel(i, j, color)
    end
  end
  tex:Apply()
  return tex
end

function My.GetBlack()
  local tex = My.Create(8, 8, Color.black)
  tex.name = "LuaTexTool.black"
  return tex
end

function My.GetTransparent()
  local color = Color.New(0, 0, 0, 0.5)
  local tex = My.Create(8, 8, color)
  tex.name = "LuaTexTool.Transparent"
  return tex
end

--黑色图片
My.Black = My.GetBlack()

--半透明黑色图片
My.Transparent = My.GetTransparent()
