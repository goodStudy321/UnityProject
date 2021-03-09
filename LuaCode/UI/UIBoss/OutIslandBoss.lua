OutIslandBoss =IslandBoss:New{Name = "OutIslandBoss"}

local My = OutIslandBoss;
My.type = 6;
function My:Open(go)
        IslandBoss.Open(self,go)
        My.type = 6;
end
function My:UIClose(  )
        UICross:CloseC();
end

