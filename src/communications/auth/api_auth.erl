-module(api_auth).
%%
%%-include("auth.hrl").
%%-include("records.hrl").
%%-include("errors.hrl").
%%-include_lib("evalidate/include/evalidate.hrl").
%%-include("logger.hrl").
%%
%%-define(RELOAD, <<"<!DOCTYPE html><html><head><script type=\"text/javascript\">if (window.opener) {window.close();}else{document.location.href = '/';}</script></head><body></body></html>">>).
%%
%%-define(DISABLE_CACHE_HEADERS, [
%%  {<<"Cache-Control">>, <<"no-cache, no-store, must-revalidate">>},
%%  {<<"Pragma">>, <<"no-cache">>},
%%  {<<"Expires">>, <<"0">>}
%%]).
%%
%%-export([
%%  request/4
%%]).
%%
%%request([<<"logout">>], _, Headers, _Ip) ->
%%  NewCookieHeaders = session:remove(Headers),
%%  {ok, NewCookieHeaders, []};
%%
%%request([<<"dist_logout">>], Data, Headers, _Ip) ->
%%  NewCookieHeaders = session:remove(Headers),
%%  RedirectUrl =
%%    case eutils:get_value(<<"redirect_uri">>, Data) of
%%      undefined ->
%%        sa_urls:get_signin_page_url();
%%      RedirectUrl0 ->
%%        RedirectUrl0
%%    end,
%%  sa_urls:redirect(RedirectUrl, NewCookieHeaders);
%%
%%request([<<"me">>], _, Headers, _Ip) ->
%%  case session:get_user_from_headers(Headers) of
%%    undefined ->
%%      {error, [{<<"redirect">>, <<"/enter">>}]}; %% @todo  сделать редирект
%%
%%    #session{user_id = Uid, nick = Nick} ->
%%      case api_user:get_user(Uid) of
%%        undefined ->
%%          error;
%%        #users{login = Login, logins = LoginsList, lang = Lang} ->
%%          Logins = [[{<<"login">>, Login1}, {<<"type">>, api_user:parse_login_type(Type1)}] || #login{login = Login1, type = Type1} <- LoginsList],
%%          Photo = api_user:get_user_photo(Uid),
%%
%%          {ok, [{<<"user_id">>, Uid}, {<<"nick">>, Nick}, {<<"user_photo">>, Photo}, {<<"login">>, Login}, {<<"logins">>, Logins}, {<<"lang">>, Lang}]}
%%      end
%%  end;
%%
%%%% OTP__________________________________________________________________________________________________________________
%%request([<<"otp">>, <<"auth">>], Data0, _Headers, _Ip) ->
%%  Rules = [
%%    #rule{key = <<"phone">>}
%%  ],
%%  Data = evalidate:validate_and_convert(Rules, Data0),
%%  Phone = eutils:get_value(<<"phone">>, Data),
%%  ok = api_otp:create_otp(Phone),
%%  {ok, []};
%%
%%%%request([<<"otp">>, <<"confirm">>], Data0, _Headers, _Ip) ->
%%%%  Rules = [
%%%%    #rule{key = <<"phone">>},
%%%%    #rule{key = <<"otp">>}
%%%%  ],
%%%%  Data = evalidate:validate_and_convert(Rules, Data0),
%%%%  Phone = eutils:get_value(<<"phone">>, Data),
%%%%  Otp = eutils:get_value(<<"otp">>, Data),
%%%%  case api_otp:verify_otp(Phone, Otp) of
%%%%    true ->
%%%%      case auth_util:get_phone_user(Phone) of
%%%%        ok -> ok
%%%%      end;
%%%%
%%%%    false ->
%%%%      throw({error, <<"Bad OTP password">>})
%%%%  end;
%%
%%%% SINGLE_ACCOUNT_______________________________________________________________________________________________________
%%request([<<"single_account">>, <<"auth">>], Data0, Headers, Ip) ->
%%  Rules = [
%%    sa_validate:login(),
%%    sa_validate:password(),
%%    sa_validate:captcha_response(),
%%    (sa_validate:redirect_uri())#rule{presence = optional}
%%%%    #rule{key = <<"redirect_uri">>, validators = [{type, binary}, {size, {4, 2048}}], presence = optional}
%%  ],
%%  Data = evalidate:validate_and_convert(Rules, Data0),
%%  Login = eutils:get_value(<<"login">>, Data),
%%
%%  F = fun(ShowCaptcha) ->
%%      Pass = eutils:get_value(<<"password">>, Data),
%%      UserPassHash = auth_utils:get_password_hash(Login, Pass),
%%      auth_utils:check_domain_is_allowed(Login, ?AUTH_TYPE_SIMPLE_EMAIL),
%%
%%      case api_db:get_user_by_login_type(Login, ?AUTH_TYPE_SIMPLE_EMAIL) of
%%        [] ->
%%          {error, [{<<"description">>, ?ERROR_INVALID_LOGIN_OR_PASSWORD}, {<<"show_captcha">>, ShowCaptcha}] };
%%
%%        [{UserId, UserNick, UserStatus, UserPassHash}] ->
%%
%%          Lang = auth_utils:search_lang_cookie(Headers),
%%          api_user:update_user_state(UserId, null, Lang, UserStatus, UserNick),
%%          {ok, Cookie} = auth_utils:update_user_session(UserId, Login, Headers, null, UserNick),
%%          auth_utils:reset_login_attempts(Login),
%%          case eutils:get_value(<<"redirect_uri">>, Data) of
%%            undefined ->
%%              {ok, Cookie, []};
%%            RedirectUri -> %% @todo согласовать c фронтендом
%%              {redirect, 302, [ {<<"location">>, RedirectUri} | Cookie] }
%%          end;
%%        _ ->
%%          {error, [{<<"description">>, ?ERROR_INVALID_LOGIN_OR_PASSWORD}, {<<"show_captcha">>, ShowCaptcha}] }
%%      end
%%    end,
%%
%%  case auth_utils:check_login_attempts(Login) of
%%    {true, _} ->
%%      ok = api_captcha:check_captcha(Data, Ip),
%%      F(true);
%%    {false, IsNeedToCheckCaptcha} ->
%%      F(IsNeedToCheckCaptcha)
%%  end;
%%
%%request([<<"single_account">>, <<"register">>], Data0, Headers, Ip) -> %% todo
%%
%%  Rules = [
%%    sa_validate:login(),
%%    sa_validate:password_security_policy(),
%%    #rule{key = <<"nick">>, validators = [{type, binary}, {size, {3, 255}}]},
%%    sa_validate:captcha_response(),
%%    (sa_validate:redirect_uri())#rule{presence = optional}
%%  ],
%%  Data = evalidate:validate_and_convert(Rules, Data0),
%%
%%  Login = eutils:get_value(<<"login">>, Data),
%%  Pass = eutils:get_value(<<"password">>, Data),
%%  Nick  = eutils:get_value(<<"nick">>, Data),
%%
%%  Email = Login,
%%  ok = api_captcha:check_captcha(Data, Ip),
%%  Lang = auth_utils:search_lang_cookie(Headers),
%%  ?LOG_DEBUG("Receiving register1111 ~p", [Data0]),
%%
%%  auth_utils:check_domain_is_allowed(Login, ?AUTH_TYPE_SIMPLE_EMAIL),
%%  case api_user:get_user_id(Login, ?AUTH_TYPE_SIMPLE_EMAIL) of
%%    undefined ->
%%      case sa_env:registration_with_email_confirm() of
%%        true ->
%%          Query = eutils:keyfilter([<<"redirect_uri">>], Data),
%%
%%          ConfirmUrl = sa_urls:get_confirm_reg_url(Query),
%%
%%          ?LOG_DEBUG("Sending reg ~p", [{Login, Pass, Email, Nick, ?AUTH_TYPE_SIMPLE_EMAIL, Lang, eutils:to_bin(ConfirmUrl)}]),
%%
%%          case corezoid_sdk:create_registration(Login, Pass, Email, Nick, ?AUTH_TYPE_SIMPLE_EMAIL, Lang, eutils:to_bin(ConfirmUrl)) of
%%            {ok, _R} ->
%%              ?LOG_DEBUG("Receiving response Reg response ~p", [_R]),
%%              {ok, [{<<"email_confirm">>, true}]};
%%            Err ->
%%              lager:error("Sending invite error ~p", [Err]),
%%              {error, ?ERROR_SENDING_INVITE}
%%          end;
%%        false ->
%%          {ok, _UserId, Cookie} = auth_utils:create_simple_email_user(Login, Nick, Pass, Headers, Lang), %% TODO Refactor Overhead
%%          {ok, Cookie, []}
%%      end;
%%    _ ->
%%      {error, ?ERROR_USER_ALREADY_EXIST_USE_ANOTHER_EMAIL}
%%  end;
%%
%%request([<<"single_account">>, <<"confirm_reg">>, Hash], Data, Headers, _Ip) -> %% TODO перенести на местный редис
%%  Me = session:get_user_from_headers(Headers),
%%  case Me of
%%    undefined ->
%%      case corezoid_sdk:confirm_registration(Hash) of
%%        {ok, UserData} ->
%%          ?LOG_DEBUG("Receiving reg and fetching from cache ~p", [UserData]),
%%          Login = eutils:get_value(<<"login">>, UserData),
%%          Nick = eutils:get_value(<<"nick">>, UserData),
%%          _AutType = eutils:get_value(<<"auth_type">>, UserData),
%%          Pass = eutils:get_value(<<"pass">>, UserData),
%%          Lang = eutils:get_value(<<"lang">>, UserData),
%%
%%          {ok, _UserId, Cookie} = auth_utils:create_simple_email_user(Login, Nick, Pass, Headers, Lang),
%%
%%
%%          case eutils:get_value(<<"redirect_uri">>, Data) of
%%            undefined ->
%%              AdminUrl = sa_urls:get_admin_url(),
%%              sa_urls:redirect(AdminUrl, Cookie);
%%            Url -> sa_urls:redirect(Url, Cookie)
%%          end;
%%
%%        {error, ErrorText} ->
%%          {error, 400, ErrorText}
%%      end;
%%    _ ->
%%      {error, 400, ?ERROR_NOT_ALLOWED_YOU_NEED_LOGOUT_FROM_OTHER_ACCOUNTS_BEFORE}
%%  end;
%%
%%request([<<"single_account">>, <<"change_password">>], Data0, _Headers, _Ip) -> % POST
%%  Rules = [
%%    sa_validate:login(),
%%    sa_validate:password(<<"old_password">>),
%%    sa_validate:password_security_policy(<<"new_password">>)
%%  ],
%%  Data = evalidate:validate_and_convert(Rules, Data0),
%%
%%  Login = eutils:get_value(<<"login">>, Data),
%%  OldPassword = eutils:get_value(<<"old_password">>, Data),
%%  NewPassword = eutils:get_value(<<"new_password">>, Data),
%%  UserPassHash = auth_utils:get_password_hash(Login, OldPassword),
%%
%%  case api_db:get_user_password(Login) of
%%    [] -> {error, ?ERROR_NOT_FOUND_USER};
%%    UserPassHashFromDb ->
%%      case lists:member(UserPassHash, UserPassHashFromDb) of
%%        false ->
%%          {error, ?ERROR_INVALID_CURRENT_PASSWORD };
%%        true ->
%%          NewUserPassHash = auth_utils:get_password_hash(Login, NewPassword),
%%          1 = api_db:update_user_password(Login, ?AUTH_TYPE_SIMPLE_EMAIL, NewUserPassHash),
%%          {ok, []}
%%      end
%%  end;
%%
%%
%%request([<<"single_account">>, <<"recovery">>], Data0, _Headers, Ip) ->  %% POST
%%
%%  Rules = [
%%    sa_validate:login(),
%%    sa_validate:captcha_response(),
%%    (sa_validate:redirect_uri())#rule{presence = optional},
%%    (sa_validate:client_id())#rule{presence = optional}
%%  ],
%%  Data = evalidate:validate_and_convert(Rules, Data0),
%%
%%  ok = api_captcha:check_captcha(Data, Ip),
%%  Login = eutils:get_value(<<"login">>, Data),
%%
%%  case api_db:get_login_id(Login, ?AUTH_TYPE_SIMPLE_EMAIL) of
%%    [] -> %% any user
%%      {ok, []}; %% https://jira.corezoid.com/browse/COR-2608
%%%%      {error, ?ERROR_NOT_FOUND_USER};
%%    _ ->
%%
%%      Query = eutils:keyfilter([<<"redirect_uri">>, <<"client_id">>], Data),
%%
%%      ConfirmUrl = sa_urls:get_password_confirm_url(Query),
%%
%%      ?LOG_DEBUG("Sending recovery ~p", [{Login, ?AUTH_TYPE_SIMPLE_EMAIL, eutils:to_bin(ConfirmUrl)}]),
%%
%%      case corezoid_sdk:create_recovery(Login, ?AUTH_TYPE_SIMPLE_EMAIL, eutils:to_bin(ConfirmUrl)) of
%%        {ok, _Res} ->
%%          {ok, []};
%%        {error, Reason} ->
%%          lager:error("Sending invite error ~p", [Reason]),
%%          {error, ?ERROR_SENDING_INVITE}
%%      end
%%  end;
%%
%%
%%request([<<"single_account">>, <<"recovery">>, Hash], Data0, Headers, _Ip) -> %% POST
%%  Rules = [
%%    sa_validate:password_security_policy(<<"new_password">>)
%%  ],
%%  Data = evalidate:validate_and_convert(Rules, Data0),
%%
%%  ?LOG_DEBUG("Sending confirm recovery Data ~p, Hash ~p", [Data0, Hash]),
%%
%%  case corezoid_sdk:confirm_recovery(Hash) of
%%    {error, Descr} ->
%%      {error, 400, Descr};
%%
%%    {ok, Recovery} ->
%%      Login = eutils:get_value(<<"login">>, Recovery),
%%      AuthType = eutils:get_value(<<"auth_type">>, Recovery),
%%      NewPassword = eutils:get_value(<<"new_password">>, Data),
%%
%%      NewUserPassHash = auth_utils:get_password_hash(Login, NewPassword),
%%      1 = api_db:update_user_password(Login, AuthType, NewUserPassHash),
%%
%%      case api_db:get_user_by_login_type(Login, ?AUTH_TYPE_SIMPLE_EMAIL) of
%%%%        [{_UserId, _UserNick, false, _Hash}] ->
%%%%          {error, 403, ?ERROR_USER_IS_BLOCKED};
%%        [{UserId, UserNick, UserStatus, _NewUserPassHash}] ->
%%          api_user:update_user_state(UserId, null, null, UserStatus, UserNick),
%%          {ok, Cookie} = auth_utils:update_user_session(UserId, Login, Headers, null, UserNick),
%%          {ok, Cookie, []}
%%      end
%%  end;
%%
%%%% LDAP_AUTH____________________________________________________________________________________________________________
%%request([<<"ldap">>], Data0, Headers, _Ip) ->
%%  Rules = [
%%    #rule{key = <<"login">>, validators = [{type, binary}, {size, {3, 25}}], converter = fun eutils:to_lower/1, on_validate_error = <<"invalid eldap login">>},
%%    sa_validate:password()
%%  ],
%%  Data = evalidate:validate_and_convert(Rules, Data0),
%%
%%  Login = eutils:get_value(<<"login">>, Data),
%%  Pass = eutils:get_value(<<"password">>, Data),
%%
%%  case api_eldap:login(Login, Pass) of
%%    {ok, Nick} ->
%%      {ok, _UserId, Cookie} = auth_utils:get_or_create_ldap_user(Login, Nick, Headers),
%%      {ok, Cookie, []};
%%
%%    {error, Reason} ->
%%      {error, 403, Reason}
%%  end;
%%
%%%% GOOGLE_AUTH__________________________________________________________________________________________________________
%%request([<<"google">>], Data, _Headers, _Ip) -> %% @todo TODO
%%  State = get_state(Data),
%%  {ok, Url} = api_google:get_redirect_url(State),
%%  sa_urls:redirect(Url);
%%
%%request([<<"google">>, <<"return">>], Data, Headers, _Ip) ->
%%
%%  State0 = auth_utils:decode_state(eutils:get_value(<<"state">>, Data)),
%%  ReturnUserUrl = eutils:get_value(<<"redirect_uri">>, State0, sa_urls:get_admin_url() ),
%%
%%  ?LOG_DEBUG("Google callback ~p", [Data]),
%%  case eutils:get_value(<<"error">>, Data, undefined) of
%%    undefined ->
%%      Code = eutils:get_value(<<"code">>, Data),
%%      case api_google:get_token_by_code(Code) of
%%        {ok, AccessToken} ->
%%          case api_google:get_user_info_by_token(AccessToken) of
%%            {ok, Login, Nick, Photo} ->
%%
%%              Lang = auth_utils:search_lang_cookie(Headers),
%%
%%              {ok, _UserId, CookieHeader} = auth_utils:get_or_create_google_user(Login, Nick, Photo, Headers, Lang),
%%
%%              ?LOG_DEBUG("Setting cookie header after google auth ~p ", [CookieHeader]),
%%
%%%%              {ok, CookieHeader, ?RELOAD}; %% For cases when auth opens in new window
%%              sa_urls:redirect(ReturnUserUrl, CookieHeader);
%%            {error, _Reas} -> %% TODO redirect to error page
%%              sa_urls:redirect(ReturnUserUrl)
%%          end;
%%        {error, _Reas} ->
%%          sa_urls:redirect(ReturnUserUrl)
%%      end
%%  end;
%%
%%%% GITHUB_AUTH__________________________________________________________________________________________________________
%%request([<<"github">>], Data, _Headers, _Ip) -> %% @todo TODO
%%  State = get_state(Data),
%%  {ok, Url} = api_github:get_redirect_url(State),
%%  sa_urls:redirect(Url);
%%
%%request([<<"github">>, <<"return">>], Data, Headers, _Ip) ->
%%
%%  State0 = auth_utils:decode_state(eutils:get_value(<<"state">>, Data)),
%%  ReturnUserUrl = eutils:get_value(<<"redirect_uri">>, State0, sa_urls:get_admin_url() ),
%%
%%  Lang = auth_utils:search_lang_cookie(Headers),
%%
%%  ?LOG_DEBUG("GitHub callback ~p", [Data]),
%%
%%  case eutils:get_value(<<"error">>, Data, undefined) of
%%    undefined ->
%%      Code = eutils:get_value(<<"code">>, Data),
%%      case api_github:get_token_by_code(Code) of
%%        {ok, AccessToken} ->
%%          case api_github:get_user_info_by_token(AccessToken) of
%%            {Login, Name, Photo, Email} ->
%%
%%              maybe_create_user_or_add_email(Login, ?AUTH_TYPE_GITHUB, Email, Name, Photo, Lang, State0, ReturnUserUrl, Headers);
%%
%%            {error, _Resp} -> %% TODO redirect to error page
%%              sa_urls:redirect(ReturnUserUrl)
%%          end;
%%        {error, _Resp} -> %% TODO redirect to error page
%%          sa_urls:redirect(ReturnUserUrl)
%%      end;
%%    Error -> %% TODO redirect to error page
%%      lager:error("Error during github auth ~p", [Error]),
%%      sa_urls:redirect(ReturnUserUrl)
%%  end;
%%
%%%% FACEBOOK_AUTH________________________________________________________________________________________________________
%%request([<<"facebook">>], Data, _Headers, _Ip) -> %% @todo TODO
%%
%%  State = get_state(Data),
%%  {ok, Url} = api_facebook:get_redirect_url(State),
%%  sa_urls:redirect(Url);
%%
%%request([<<"facebook">>, <<"return">>], Data, Headers, _Ip) ->
%%  State0 = auth_utils:decode_state(eutils:get_value(<<"state">>, Data)),
%%  ReturnUserUrl = eutils:get_value(<<"redirect_uri">>, State0, sa_urls:get_admin_url()),
%%
%%  Lang = auth_utils:search_lang_cookie(Headers),
%%
%%  ?LOG_DEBUG("Facebook callback ~p", [Data]),
%%  case eutils:get_value(<<"error">>, Data, undefined) of
%%    undefined ->
%%      Code = eutils:get_value(<<"code">>, Data),
%%      case api_facebook:get_token_by_code(Code) of
%%        {ok, AccessToken} ->
%%          case api_facebook:get_user_info_by_token(AccessToken) of
%%            {Login, Name, Photo, Email} ->
%%
%%              maybe_create_user_or_add_email(Login, ?AUTH_TYPE_FACEBOOK, Email, Name, Photo, Lang, State0, ReturnUserUrl, Headers);
%%
%%            {error, _Resp} -> %% TODO redirect to error page
%%              sa_urls:redirect(ReturnUserUrl)
%%          end;
%%        {error, _Resp} ->
%%          sa_urls:redirect(ReturnUserUrl) %% TODO redirect to error page
%%      end;
%%    Error ->
%%      lager:error("Error during facebook auth ~p", [Error]),
%%%%      Reason = eutils:get_value(<<"error_reason">>, Data),
%%%%      https://account.pre.corezoid.com/auth/facebook/return?error=access_denied&error_code=200&error_description=Permissions+error&error_reason=user_denied&state=eyJyZWRpcmVjdF91cmkiOiIiLCJjbGllbnRfaWQiOiJ1bmRlZmluZWQifQ%3D%3D#_=_
%%      sa_urls:redirect(ReturnUserUrl) %% TODO redirect to error page
%%  end;
%%
%%%% ADD EMAIL (for facebook and github auth)_____________________________________________________________________________
%%request([<<"single_account">>, <<"add_email">>, Hash], Data0, _Headers, _Ip) ->
%%  Rules = [
%%    #rule{key = <<"email">>, validators = [{type, binary}, ?V_EMAIL, {size, {5, 100}} ], converter = fun eutils:to_lower/1, on_validate_error = <<"Email is not valid">>},
%%    (sa_validate:redirect_uri())#rule{presence = optional}
%%  ],
%%  Data = evalidate:validate_and_convert(Rules, Data0),
%%
%%  Email = eutils:get_value(<<"email">>, Data),
%%  RedirectUri = eutils:get_value(<<"redirect_uri">>, Data, sa_urls:get_admin_url()),
%%
%%  case auth_utils:confirm_email_addition(Hash) of
%%    {ok, Userinfo} ->
%%      auth_utils:create_email_confirm_invite(Userinfo#userinfo_invite{email = Email, redirect_uri = RedirectUri}),
%%
%%      {ok, []};
%%    {error, Reason} ->
%%      {error, Reason}
%%  end;
%%
%%%% CONFIRM EMAIL (for facebook and github auth)_________________________________________________________________________
%%request([<<"confirm_email">>, Hash], _Data, Headers, _Ip) ->
%%  case auth_utils:confirm_email_invite(Hash) of
%%    {ok, #userinfo_invite{login = Login, name = Name, auth_type = AuthType, photo = Photo, email = Email, redirect_uri = RedirectUrl, lang = Lang}} ->
%%
%%      {ok, _UserId, CookieHeader} =
%%        case AuthType of
%%          ?AUTH_TYPE_FACEBOOK ->
%%            auth_utils:get_or_create_facebook_user(Login, Name, Photo, Email, Headers, Lang);
%%          ?AUTH_TYPE_GITHUB ->
%%            auth_utils:get_or_create_github_user(Login, Name, Photo, Email, Headers, Lang)
%%        end,
%%      sa_urls:redirect(RedirectUrl, CookieHeader);
%%    {error, Reason} ->
%%      {error, Reason}
%%  end;
%%
%%request(_, _, _, _) ->
%%  {error, 400, ?ERROR_AUTH_METHOD_NOT_ALLOWED }.
%%
%%%% PRIVATE______________________________________________________________________________________________________________
%%get_state(Data) ->
%%  case Data of
%%    [] -> [];
%%    _ -> auth_utils:encode_state(Data)
%%  end.
%%
%%maybe_create_user_or_add_email(Login, Type, Email, Name, Photo, Lang, State0, ReturnUserUrl, Headers) ->
%%  case api_db:get_user_by_login_type(Login, Type) of
%%    [] ->
%%      Hash = auth_utils:create_email_addition(Login, Name, Photo, Lang, Type, ReturnUserUrl),
%%      State = lists:keystore(<<"redirect_uri">>, 1, State0, {<<"redirect_uri">>, ReturnUserUrl}),
%%      QSParams0 = State ++ [{<<"hash">>, Hash}, {<<"name">>, Name}],
%%
%%      QSParams1 =
%%        case Email of
%%          undefined -> QSParams0;
%%          _ -> [{<<"email">>, Email} | QSParams0 ]
%%        end,
%%
%%      AddEmailUrl = sa_urls:get_add_email_url(QSParams1),
%%
%%      sa_urls:redirect(AddEmailUrl);
%%
%%    [{UserId, UserNick, UserStatus, _}] ->
%%      api_user:update_user_state(UserId, null, Lang, UserStatus, UserNick),
%%      {ok, CookieHeader} = auth_utils:update_user_session(UserId, Login, Headers, null, UserNick),
%%      sa_urls:redirect(ReturnUserUrl, CookieHeader)
%%  end.
