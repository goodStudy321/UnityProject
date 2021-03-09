%% coding: latin-1
-module(cfg_server).
-include("config.hrl").
-export([find/1]).
?CFG_H

%%
?C(pre_starts, [
log,
{time_tool, start_server, [world, server_sup, [0, 1000]]}
])

?C(starts, [

])

?CFG_E.
