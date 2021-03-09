%% Settings (defaults in include/emysql.hrl):
%% default_timeout (TIMEOUT = 8000)
%% lock_timeout (LOCK_TIMEOUT = 5000)

{application, emysql, [
    {description, "Emysql - Erlang MySQL driver"},
    {vsn, "0.4.2"},
    {modules, [emysql_app, emysql_auth, emysql_conn, emysql_conn_mgr, emysql_conv, emysql, emysql_statements,
        emysql_sup, emysql_tcp, emysql_util, emysql_worker]},
    {mod, {emysql_app, ["Sun Apr 16 03:23:00 PDT 2017"]}},
    {registered, [emysql_conn_mgr, emysql_sup]},
    {applications, [kernel, stdlib, crypto]},
    {env, [
        {default_timeout, 5000},
        {conn_test_period, 28000}]}
]}.
