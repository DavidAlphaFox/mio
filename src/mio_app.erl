%%%-------------------------------------------------------------------
%%% File    : mio.erl
%%% Author  : higepon <higepon@users.sourceforge.jp>
%%% Description : mio application
%%%
%%% Created : 3 Aug 2009 by higepon <higepon@users.sourceforge.jp>
%%%-------------------------------------------------------------------
-module(mio_app).

-behaviour(application).
-import(mio).
%% Application callbacks
-export([start/2, stop/1]).

%% For init script
-export([start/0, stop/0]).

-include("mio.hrl").

start() ->
    application:start(mio).

stop() ->
    %% todo name should be placed mio.ihr
    ok = rpc:call(mioserver@localhost, application, stop, [mio]).

start(_Type, _StartArgs) ->
    case application:get_env(mio, debug) of
        {ok, IsDebugMode} ->
            if IsDebugMode =:= true ->
                    [];
               true ->
                    error_logger:tty(false)
            end;
        _ -> []
    end,
    supervisor:start_link({local, mio_sup}, mio_sup, []).

stop(_State) ->
    ok.
