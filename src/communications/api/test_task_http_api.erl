-module(test_task_http_api).
-author("sergeybondarchuk").

-behaviour(cowboy_http_handler).

-export([init/3, handle/2, terminate/3]).


% init HTTP connection
init( _Transport, Req, State ) ->
  { ok, Req, State }.

handle( Req, State ) ->
  { Method, Req2 } = cowboy_req:method(Req),
  handle( Method, Req2, State ).
%%  end.

%% use POST method - check body
handle( <<"POST">>, Req, State ) ->
  case cowboy_req:has_body( Req ) of %% check body
    false ->
      { ok, Req2 } = cowboy_req:reply( 400, [], <<"Missisng body">>, Req ),
      { ok, Req2, State };
    true ->
      { ok, Data0, Req2 } = cowboy_req:body_qs( Req ),
      case eutils:from_json(Data0, error) of
        error ->
          cowboy_req:reply( 400, [], <<"Bad body format">>, Req );
        Data ->
          handle_data(Req2, State, Data)
      end
  end;

% undefined method
handle( _, Req, State ) ->
  { ok, Req2 } = cowboy_req:reply( 405, [], <<"method not allowed">>, Req ),
  { ok, Req2, State }.


handle_data(Req, State, Data) ->
  { Path, Req2 }  = cowboy_req:path_info( Req ),
  {Headers, Req4} = cowboy_req:headers(Req2),

  {ok, Req5} =
    case catch test_task_api_engine:request(Path, Data, Headers) of

      {ok, Message} ->
        cowboy_req:reply( 200, [], response_ok(Message), Req4 );

      {ok, HeadersResp, Message} ->
        cowboy_req:reply( 200, HeadersResp, response_ok(Message), Req4 );

      {error, Message} ->
        cowboy_req:reply( 400, [], response_error(Message), Req4 );

      {error, Code, Message} ->
        cowboy_req:reply( Code, [], response_error(Message), Req4 )
    end,

  { ok, Req5, State }.


response_ok(Data) when is_list(Data) ->
  eutils:to_json([{<<"result">>, <<"ok">>} | Data]);
response_ok(Body) ->
  Body.

response_error(Data) when is_list(Data) ->
  eutils:to_json([{<<"result">>, <<"error">>} | Data]);

response_error(Data) when is_binary(Data) ->
  eutils:to_json([{<<"result">>, <<"error">>}, {<<"description">>, Data}]).

% client closed browser
terminate(_Reason, _Req, _Data)->
  ok.