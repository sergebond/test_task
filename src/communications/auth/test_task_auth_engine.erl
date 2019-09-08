-module(test_task_auth_engine).

-include_lib("evalidate/include/evalidate.hrl").


-export([
  request/3
]).

request([<<"register">>], Data0, _Headers) ->
  Rules = [
    #rule{key = <<"nickname">>, validators = [{type, binary}, {size, {3, 256}}]}
  ],
  Data = evalidate:validate_and_convert(Rules, Data0),
  NickName = eutils:get_value(<<"nickname">>, Data),
  case users:create(NickName) of
    {ok, UserId} ->
      {ok, [{<<"user_id">>, UserId}]};
    {error, Error} ->
      {error, Error}
  end;


request([<<"auth">>], Data0, _Headers) ->
  Rules = [
    #rule{key = <<"user_id">>, validators = [{type, binary}, {size, {256, 256}}], on_validate_error = <<"Invalid user id">>}
  ],
  Data = evalidate:validate_and_convert(Rules, Data0),
  UserId = eutils:get_value(<<"user_id">>, Data),
  case users:get_(UserId) of
    {ok, _User} ->
      {ok, Token} = tokens:create(UserId),
      {ok, [{<<"token">>, Token}]};
    {error, Error} ->
      {error, Error}
  end;

request(_, _, _) ->
  {error, 404, <<"Not found">>}.