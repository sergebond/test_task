-module(test_task_env).
-author("sergeybondarchuk").
-include("test_task.hrl").

%% API
-compile(export_all).

get_port() ->
  case application:get_env(?APP_NAME, port) of
    {ok, Port} -> Port;
    _ -> throw({error, <<"Coldn't find  'port' parameter in configuration file">>})
  end.