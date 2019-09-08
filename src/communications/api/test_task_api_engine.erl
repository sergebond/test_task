-module(test_task_api_engine).
-author("sergeybondarchuk").
-include_lib("evalidate/include/evalidate.hrl").

%% API
-export([

  request/3,
  get/3,
  update/3,
  buy/3,
  erase/3
]).

request(_Path, Data0, _Headers) ->
  Rules = [
    #rule{key = <<"token">>, validators = [{type, binary}, {size, {10, 512}}], on_validate_error = <<"Bad token">>},
    #rule{key = <<"type">>, validators = [{allowed, [<<"get">>, <<"update">>, <<"buy">>, <<"erase">>]}], converter = to_atom, on_validate_error = <<"Bad command type">>},
    #rule{key = <<"obj">>, validators = [{type, binary}, {size, {3, 15}}], on_validate_error = <<"bad obj">>}
  ],
  Data  = evalidate:validate_and_convert(Rules, Data0),
  Token = eutils:get_value(<<"token">>, Data),
  Type = eutils:get_value(<<"type">>, Data),
  Obj = eutils:get_value(<<"obj">>, Data),

  case tokens:get_user_by_token(Token) of
    {ok, Uid} ->
      ?MODULE:Type(Obj, Uid, Data);
    {error, _Reason} ->
      {error, 403, <<"Not authorized">>}
  end.

get(<<"profile">>, UserId, _Data) ->
  case users:get_(UserId) of
    {ok, User} ->
      {ok, users:render(User)};
    {error, Error} ->
      {error, Error}
  end;
get(_, _,_) ->
  {error, <<"Bad type">>}.


update(<<"level">>, UserId, _Data) ->
  case users:next_level(UserId) of
    {ok, Level} ->
      {ok, [
        {<<"user_id">>, UserId},
        {<<"next_level">>, Level}]};
    {error, Reason} ->
      {error, Reason}
  end;
update(_, _,_) ->
  {error, <<"Bad type">>}.


buy(<<"stars">>, UserId, Data0) ->
  Rules = [
    #rule{key = <<"count">>, validators = [?V_BINARY_INTEGER], converter = to_int}
  ],
  Data  = evalidate:validate_and_convert(Rules, Data0),
  Count = eutils:get_value(<<"count">>, Data),
  case users:update_stars_count(UserId, Count) of
    {ok, StarsCount} ->
      {ok, [{<<"user_id">>, UserId}, {<<"stars_count">>, StarsCount}]}
  end;
buy(_, _,_) ->
  {error, <<"Bad type">>}.


erase(<<"profile">>, UserId, _Data) ->
  case users:erase(UserId) of
    ok ->
      {ok, [{<<"user_id">>, UserId}]};
    {error, Reason} ->
      {error, Reason}
  end;
erase(_, _,_) ->
  {error, <<"Bad type">>}.