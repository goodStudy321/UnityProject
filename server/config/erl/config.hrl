-ifndef(CONFIG_HRL).
-define(CONFIG_HRL, config_hrl).

-define(CFG_H, find(K) -> case K of ).

-define(C(K,V),  K -> V; ).

-define(CFG_E,  _Other -> undefined 
end ).

-endif.
