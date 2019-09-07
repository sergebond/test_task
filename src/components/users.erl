-module(users).
-author("sergeybondarchuk").

-record(user, {
  id,
  nickname,
  coins = 0,
  stars = 0,
  level = 0
}).

-define(TABLE, ?MODULE).

%% API
-export([
  create/1,
  init_db/0,
  get_/1,
  update_stars_count/2,
  next_level/1,
  erase/1
]).


init_db() ->
  ets:new(?TABLE, [set, public, named_table, {keypos, #user.id}]).

create(Nickname) ->
  Id = gen_id(Nickname),
  case ets:insert_new(?TABLE, #user{id = Id, nickname = Nickname}) of
    false ->
      {error, <<"Already exists">>};
    true ->
      {ok, Id}
  end.

get_(UserId) ->
  case ets:lookup(?TABLE, UserId) of
    [] ->
      {error, <<"Not found">>};
    [User] ->
      {ok, User}
  end.

update_stars_count(UserId, Delta) ->
  Res =  ets:update_counter(?TABLE, UserId, {#user.stars, Delta}),
  {ok, Res}.


next_level(UserId) ->
  Res =  ets:update_counter(?TABLE, UserId, {#user.level, 1}),
  {ok, Res}.


erase(UserId) ->
  true = ets:delete(UserId),
  ok.

%% PRIVATE______________________________________________________________________________________________________________

gen_id(Nickname) ->
  Hash = crypto:hash(sha, Nickname),
  list_to_binary(eutils:hexstring(Hash)).