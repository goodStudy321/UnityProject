{application, server_app,
    [{description, "server"},
        {id, "server_app"},
        {vsn, "0.1"},
        {modules, [server_app]},
        {registered, [server_app]},
        {applications, [kernel, stdlib, sasl]},
        {mod, {server_app, []}},
        {env, []}
    ]}.
