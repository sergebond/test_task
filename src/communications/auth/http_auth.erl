-module(http_auth).

-behaviour(cowboy_http_handler).
%%
%%-export([init/3, handle/2, terminate/3]).
%%
%%-include("errors.hrl").
%%-include("logger.hrl").
%%
%%  % init HTTP connection
%%init( _Transport, Req, State ) ->
%%    { ok, Req, State }.
%%
%%handle( Req, State ) ->
%%  { Method, Req2 } = cowboy_req:method(Req),
%%  handle( Method, Req2, State ).
%%%%  end.
%%
%%
%%handle( <<"GET">>, Req, State ) ->
%%	{ Data, Req2} = cowboy_req:qs_vals( Req ),
%%	handle_data(Req2, State, Data);
%%
%%
%%	%% use POST method - check body
%%handle( <<"POST">>, Req, State ) ->
%%  case cowboy_req:has_body( Req ) of %% check body
%%    false ->
%%      { ok, Req2 } = cowboy_req:reply( 400, [], ?ERROR_MISSING_BODY, Req ),
%%      { ok, Req2, State };
%%    true ->
%%      { ok, Data, Req2 } = cowboy_req:body_qs( Req ),
%%      handle_data(Req2, State, Data)
%%  end;
%%
%%% undefined method
%%handle( _, Req, State ) ->
%%	{ ok, Req2 } = cowboy_req:reply( 405, [], ?ERROR_METHOD_NOT_ALLOWED, Req ),
%%	{ ok, Req2, State }.
%%
%%
%%handle_data(Req, State, Data) ->
%%	{ Path, Req2 }  = cowboy_req:path_info( Req ),
%%	{Headers, Req3} = cowboy_req:headers(Req2),
%%	{Peer, Req4}    = cowboy_req:peer(Req3),
%%
%%	Ip = peer_addr(Headers, Peer),
%%
%%	{ok, Req5} =
%%	case catch api_auth:request(Path, Data, Headers, Ip) of
%%
%%		{ok, Message} ->
%%				cowboy_req:reply( 200, [], response_ok(Message), Req4 );
%%
%%		{ok, HeadersResp, Message} ->
%%				cowboy_req:reply( 200, HeadersResp, response_ok(Message), Req4 );
%%
%%		{redirect, RedirectCode, RedirectHeaders} ->
%%			?LOG_DEBUG("Redirect Headers ~p", [RedirectHeaders]),
%%				cowboy_req:reply( RedirectCode, RedirectHeaders, [], Req4 );
%%
%%		{error, Message} ->
%%			?LOG_DEBUG("Error during request Path:~p Message:~p Data:~p", [Path, Message, Data]),
%%				cowboy_req:reply( 400, [], response_error(Message), Req4 ); %% Правка наа 400 по просьбе Зинченко
%%
%%    {error, Code, Message} ->
%%			?LOG_DEBUG("Error during request Path:~p Message:~p Data:~p", [Path, Message, Data]),
%%        cowboy_req:reply( Code, [], response_error(Message), Req4 )
%%	end,
%%
%%	{ ok, Req5, State }.
%%
%%
%%response_ok(Data) when is_list(Data) ->
%%  eutils:to_json([{<<"result">>, <<"ok">>} | Data]);
%%response_ok(Body) ->
%%	Body.
%%
%%response_error(#error_message{code = Code, description = Description}) ->
%%	eutils:to_json([{<<"result">>, <<"error">>}, {<<"code">>, Code}, {<<"description">>, Description}]);
%%
%%response_error(Data) when is_list(Data) ->
%%  eutils:to_json([{<<"result">>, <<"error">>} | Data]);
%%
%%response_error(Data) when is_binary(Data) ->
%%  eutils:to_json([{<<"result">>, <<"error">>}, {<<"description">>, Data}]).
%%
%%% client closed browser
%%terminate(_Reason, _Req, _Data)->
%%  ok.
%%
%%peer_addr(Headers, {PeerIp, _PeerPort}) ->
%%	RealIp = proplists:get_value(<<"x-real-ip">>, Headers),
%%	ForwardedForRaw = proplists:get_value(<<"x-forwarded-for">>, Headers),
%%
%%	ForwardedFor =
%%		case ForwardedForRaw of
%%			undefined ->
%%				undefined;
%%			ForwardedForRaw ->
%%				case re:run(ForwardedForRaw, "^(?<first_ip>[^\\,]+)",
%%					[{capture, [first_ip], binary}]) of
%%					{match, [FirstIp]} -> FirstIp;
%%					_Any -> undefined
%%				end
%%		end,
%%
%%	Res =
%%		if
%%			is_binary(RealIp) -> inet_parse:address(binary_to_list(RealIp));
%%			is_binary(ForwardedFor) -> inet_parse:address(binary_to_list(ForwardedFor));
%%			true -> {ok, PeerIp}
%%		end,
%%	case Res of
%%		{ok, PeerAddr} ->
%%			PeerAddr;
%%		_ ->
%%			PeerIp
%%	end.