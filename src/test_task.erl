-module(test_task).
-author("sergeybondarchuk").

-include("test_task.hrl").

%% API
-export([start/0]).

start() ->
  application:ensure_all_started(?APP_NAME).

