-module(test_task_app).

-behaviour(application).

-define(API_LISTENER, test_task_listener).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
  init_database(),
  start_http(),
  test_task_sup:start_link().

stop(_State) ->
  ok.

start_http() ->

  ApiPort = test_task_env:get_port(),
  Dispatch =
    cowboy_router:compile(
      [
        {'_', [
          {<<"/api/1/json">>, test_task_http_api, []},
          {<<"/[...]">>, test_task_http_auth, []}

        ]}
      ]),

  {ok, _} = R =
    cowboy:start_http(
      ?API_LISTENER,
      100,
      [{port, ApiPort}],
      [{env, [{dispatch, Dispatch}]}]
    ),
  lager:info("test_task handlers started on port ~p", [ApiPort]),
  R.

init_database() ->
  tokens:init_db(),
  users:init_db(),
  lager:info("Db inited").