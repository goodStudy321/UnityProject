UIThrUni = ArenaBase:New{Name = "UIThrUni"}
local My = UIThrUni;

function My:Open(go)
    TopThrDemon:Open(go);
end

function  My:Close()
    TopThrDemon:Close();
end