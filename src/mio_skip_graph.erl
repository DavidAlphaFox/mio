%%    Copyright (C) 2010 Cybozu Labs, Inc., written by Taro Minowa(Higepon) <higepon@labs.cybozu.co.jp>
%%
%%    Redistribution and use in source and binary forms, with or without
%%    modification, are permitted provided that the following conditions
%%    are met:
%%
%%    1. Redistributions of source code must retain the above copyright
%%       notice, this list of conditions and the following disclaimer.
%%
%%    2. Redistributions in binary form must reproduce the above copyright
%%       notice, this list of conditions and the following disclaimer in the
%%       documentation and/or other materials provided with the distribution.
%%
%%    3. Neither the name of the authors nor the names of its contributors
%%       may be used to endorse or promote products derived from this
%%       software without specific prior written permission.
%%
%%    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
%%    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
%%    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
%%    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
%%    OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
%%    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
%%    TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
%%    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
%%    LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
%%    NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
%%    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%%%-------------------------------------------------------------------
%%% File    : mio_skip_graph.erl
%%% Author  : higepon <higepon@labs.cybozu.co.jp>
%%% Description : bucket
%%%
%%% Created : 12 Apr 2010 by higepon <higepon@labs.cybozu.co.jp>
%%%-------------------------------------------------------------------
-module(mio_skip_graph).
-include("mio.hrl").
-include_lib("eunit/include/eunit.hrl").

-define(LOGF(Msg), io:format(Msg ++ " ~p:~p~p~n", [?MODULE, ?LINE, self()])).
-define(LOGF(Msg, Args), io:format(Msg ++ " ~p:~p~p~n", Args ++ [?MODULE, ?LINE, self()])).


%% API
-export([search_op/2, search_op/3,
         get_key_op/1


        ]).

%% Exported for handle_call
-export([search_op_call/5,
         get_key/1

        ]).
%%--------------------------------------------------------------------
%%  accessors
%%--------------------------------------------------------------------
get_key_op([]) -> [];
get_key_op(Bucket) ->
    gen_server:call(Bucket, skip_graph_get_key_op).


%%--------------------------------------------------------------------
%%  Search operation
%%
%%  Condition : SearchKey > NodeKey && right exists
%%    Level ge 1 : to the right on the same level
%%    Level 0    : to the right on the same level
%%
%%  Condition : SearchKey > NodeKey && right not exists
%%    Level ge 1 : to the lower level
%%    Level 0    : not found (On mio this case can't be happen, since it handles ?MAX_KEY)
%%
%%  Condition : SearchKey = NodeKey
%%    Level ge 1 : Search on the bucket and return
%%    Level 0    : Search on the bucket and return
%%
%%  Condition : SearchKey < NodeKey && left exist && SearchKey <= LeftKey
%%    Level ge 1 : to the left on the same level
%%    Level 0    : to the left on the same level
%%
%%  Condition : SearchKey < NodeKey && left exist && SearchKey > LeftKey
%%    Level ge 1 : to the lower level
%%    Level 0    : Search on the bucket and return
%%
%%  Condition : SearchKey < NodeKey && left not exist
%%    Level ge 1 : to the lower level
%%    Level 0    : not_found  (On mio this case can't be happen, since it handles ?MIX_KEY)

%%--------------------------------------------------------------------
search_op(StartNode, SearchKey) ->
    search_op(StartNode, SearchKey, []).
search_op(StartNode, SearchKey, StartLevel) ->
    gen_server:call(StartNode, {skip_graph_search_op, SearchKey, StartLevel}, infinity).

search_op_to_right(From, State, Self, SearchKey, SearchLevel) ->
    case {neighbor_node(State, right, SearchLevel), SearchLevel} of
        {[], 0} ->
            gen_server:reply(From, {error, not_found});
        {[], _} ->
            search_op_call(From, State, Self, SearchKey, SearchLevel - 1);
        {RightNode, _} ->
            gen_server:reply(From, mio_skip_graph:search_op(RightNode, SearchKey, SearchLevel))
    end.

search_op_to_left(From, State, Self, SearchKey, SearchLevel) ->
    case {neighbor_node(State, left, SearchLevel), SearchLevel} of
        {[], 0} ->
            gen_server:reply(From, mio_bucket:get_op(Self, SearchKey));
        {[], _} ->
            search_op_call(From, State, Self, SearchKey, SearchLevel - 1);
        {LeftNode, _} ->
            LeftKey = get_key_op(LeftNode),
            if SearchKey =< LeftKey ->
                    gen_server:reply(From, mio_skip_graph:search_op(LeftNode, SearchKey, SearchLevel));
               SearchLevel =:= 0 ->
                    gen_server:reply(From, mio_bucket:get_op(Self, SearchKey));
               true ->
                    search_op_call(From, State, Self, SearchKey, SearchLevel - 1)
            end
    end.


search_op_call(From, State, Self, SearchKey, Level) ->
    SearchLevel = start_level(State, Level),
    MyKey = get_key(State),
    ?LOGF("SearchKey=~p MyKey=~p Level=~p~n", [SearchKey, MyKey, Level]),
    if SearchKey > MyKey ->
            search_op_to_right(From, State, Self, SearchKey, SearchLevel);
       SearchKey =:= MyKey ->
            %% We have to right buckt on case [00, 01, 02] -> [] -> [1 2 3],
            %% since [] has key 1.
            gen_server:reply(From,
                             case mio_bucket:get_op(Self, SearchKey) of
                                 {error, not_found} ->
                                     case neighbor_node(State, right, 0) of
                                         [] -> {error, not_found};
                                         RightNode0 ->
                                             mio_bucket:get_op(RightNode0, SearchKey)
                                     end;
                                 Found -> Found
                             end);
       true ->
            search_op_to_left(From, State, Self, SearchKey, SearchLevel)
    end.



%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------

%% My key is max_range.
get_key(State) ->
    State#node.max_key.

start_level(State, []) ->
    length(State#node.right) - 1; %% Level is 0 origin
start_level(_State, Level) ->
    Level.

node_on_level(Nodes, Level) ->
    case Nodes of
        [] -> [];
        _ ->  lists:nth(Level + 1, Nodes) %% Erlang array is 1 origin.
    end.

neighbor_node(State, Direction, Level) ->
    case Direction of
        right ->
            node_on_level(State#node.right, Level);
        left ->
            node_on_level(State#node.left, Level)
    end.

reverse_direction(Direction) ->
    case Direction of
        right ->
             left;
        left ->
            right
    end.

set_right(State, Level, Node) ->
    State#node{right=mio_util:lists_set_nth(Level + 1, Node, State#node.right)}.

set_left(State, Level, Node) ->
    State#node{left=mio_util:lists_set_nth(Level + 1, Node, State#node.left)}.