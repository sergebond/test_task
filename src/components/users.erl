-module(users).
-author("sergeybondarchuk").

-record(user, {
  id,
  nickname,
  coins = 100,
  stars = 0,
  level = 0
}).

-define(TABLE, ?MODULE).
-define(DEFAULT_STAR_COST, 1).

%% API
-export([
  create/1,
  init_db/0,
  get_/1,
  buy_stars/2,
  next_level/1,
  erase/1,
  render/1
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

buy_stars(UserId, Delta) ->
  StarCost = get_star_cost(),
  Sum = StarCost * Delta,
  [Coins, Stars] =  ets:update_counter(?TABLE, UserId, [ {#user.coins, - Sum}, {#user.stars, Delta}]),
  {ok, Coins, Stars}.


next_level(UserId) ->
  Res =  ets:update_counter(?TABLE, UserId, {#user.level, 1}),
  {ok, Res}.


erase(UserId) ->
  true = ets:delete(?TABLE, UserId),
  ok.

render(Rec) ->
  lists:zip(record_info(fields, user), tl(tuple_to_list(Rec))).

%% PRIVATE______________________________________________________________________________________________________________

gen_id(Nickname) ->
  Hash = crypto:hash(sha, Nickname),
  list_to_binary(eutils:hexstring(Hash)).


get_star_cost() -> ?DEFAULT_STAR_COST.