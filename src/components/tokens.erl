-module(tokens).
-author("sergeybondarchuk").

-include_lib("stdlib/include/ms_transform.hrl").
-define(TOKEN_EXP_SEC, 15 * 60 ).

-define(TABLE, ?MODULE).

-define(SERVER, ?MODULE).

-define(CLEANING_INTERVAL, 2000).

-define(TOKEN_SALT, "token_salt").

-record(token, {
  token,
  user_id,
  expires = eutils:get_unixtime() + ?TOKEN_EXP_SEC
}).

%% API
-export([
  init_db/0,
  create/1,
  get_user_by_token/1
]).

-export([start_link/0]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

init_db() ->
  ?MODULE = ets:new(?MODULE, [set, named_table, public, {keypos, #token.token}]).

create(UserId) ->
  Token = gen_token(UserId),
  ets:insert(?TABLE, #token{user_id = UserId, token = Token}),
  ok.

get_user_by_token(Token) ->
  Now = eutils:get_unixtime(),
  case ets:lookup(?TABLE, Token) of
    [#token{user_id = Uid, expires = Exp}] when Exp < Now ->
      {ok, Uid};
    _ ->
      {error, <<"invalid token">>}
  end.

%% TOKENS CLEANER PROCESS_______________________________________________________________________________________________

start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
  erlang:send_after(?CLEANING_INTERVAL, self(), clean),
  {ok, []}.

handle_call(_Request, _From, State) ->
  {reply, ok, State}.

handle_cast(_Request, State) ->
  {noreply, State}.

handle_info(clean, State) ->
  erlang:send_after(?CLEANING_INTERVAL, self(), clean),
  ok = clean_exp_records(),
  {noreply, State};

handle_info(_Info, State) ->
  lager:error("Wrong info ~p", [_Info]),
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.


%% PRIVATE _____________________________________________________________________________________________________________
clean_exp_records() ->
  Now = eutils:get_unixtime(),
  ets:select_delete(?TABLE, ets:fun2ms(fun(#token{expires = Exp}) when Exp < Now -> true end)),
  ok.

gen_token(Uid) ->
  Time = integer_to_binary(get_time_in_millisec()),
  Hash = crypto:hash(sha256, << Uid/binary, ?TOKEN_SALT, Time/binary >>),
  list_to_binary(eutils:hexstring(Hash)).

get_time_in_millisec() ->
  {Mega, Sec, Micro} = os:timestamp(),
  (Mega*1000000 + Sec)*1000 + round(Micro/1000).