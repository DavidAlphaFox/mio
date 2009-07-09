%%%-------------------------------------------------------------------
%%% File    : mio_node_SUITE.erl
%%% Author  : higepon <higepon@users.sourceforge.jp>
%%% Description :
%%%
%%% Created : 30 Jun 2009 by higepon <higepon@users.sourceforge.jp>
%%%-------------------------------------------------------------------
-module(mio_node_SUITE).

-compile(export_all).

init_per_suite(Config) ->
    error_logger:tty(false),
    ok = error_logger:logfile({open, "./error.log"}),
    {ok, Pid} = mio_sup:start_link(),
    unlink(Pid),
    {ok, NodePid} = mio_sup:start_node(myKey, myValue, mio_mvector:make([1, 0])),
    register(mio_node, NodePid),
    Config.

end_per_suite(Config) ->
    ok.


get_call() ->
    [].

get_call(_Config) ->
    {myKey, myValue} = gen_server:call(mio_node, get),
    {myKey, myValue} = gen_server:call(mio_node, get),
    ok.

left_right_call(_Config) ->
    [[], []] = gen_server:call(mio_node, left),
    [[], []] = gen_server:call(mio_node, right).



dump_nodes_call(_Config) ->
    %% insert to right
    {ok, Pid} = gen_server:call(mio_node, {insert, myKey1, myValue1}),

    %% insert to left
    {ok, Pid2} = gen_server:call(mio_node, {insert, myKex, myKexValue}),
    [{myKex, myKexValue}, {myKey, myValue}, {myKey1, myValue1}] =  mio_node:dump_nodes(mio_node, 0), %% dump on Level 0

    ok.

search_call(_Config) ->
%%     %% I have the value
%%     {ok, myValue2} = mio_node:search(mio_node, myKey),
%%     %% search to right
%%     {ok, myValue1} = mio_node:search(mio_node, myKey1),
%%     {ok, myValue1} = mio_node:search(mio_node, myKey1),
%%     %% search to left
%%     {ok, myKexValue} = mio_node:search(mio_node, myKex),

%%     %% not found
%%     %% returns closest node
%%     {ok, myKey1, myValue1} = gen_server:call(mio_node, {search, mio_node, [], myKey2}),
%%     %% returns ng
%%     ng = mio_node:search(mio_node, myKey2),
    ok.

%% very simple case: there is only one node.
search_level2_simple(_Config) ->
    {ok, Node} = mio_sup:start_node(myKey, myValue, mio_mvector:make(mio_mvector:make([1, 0]))),
    {ok, myKey, myValue} = gen_server:call(Node, {search, Node, [], myKey}),

    %% dump nodes on Level 0 and 1
    [{myKey, myValue}] = mio_node:dump_nodes(Node, 0),
    [{myKey, myValue}] = mio_node:dump_nodes(Node, 1),
    ok.

search_level2_1(_Config) ->
    %% We want to test search-op without insert op.
    %%   setup predefined nodes as follows.
    %%     level1 [3] [5]
    %%     level0 [3 <-> 5]
    {ok, Node3} = mio_sup:start_node(key3, value3, mio_mvector:make(mio_mvector:make([0, 0]))),
    {ok, Node5} = mio_sup:start_node(key5, value5, mio_mvector:make(mio_mvector:make([1, 1]))),

    ok = link_nodes(0, [Node3, Node5]),

    %% dump nodes on Level 0 and 1
    [{key3, value3}, {key5, value5}] = mio_node:dump_nodes(Node3, 0),
%    [[{key3, value3}], [{key5, value5}]] = mio_node:dump_nodes(Node3, 1),


    %% search!
    {ok, value3} = mio_node:search(Node3, key3),
    {ok, value3} = mio_node:search(Node5, key3),
    {ok, value5} = mio_node:search(Node3, key5),
    {ok, value5} = mio_node:search(Node5, key5),
    ok.

search_level2_2(_Config) ->
    %% We want to test search-op without insert op.
    %%   setup predefined nodes as follows.
    %%     level1 [3 <-> 9] [5]
    %%     level0 [3 <-> 5 <-> 9]
    {ok, Node3} = mio_sup:start_node(key3, value3, mio_mvector:make([1, 0])),
    {ok, Node5} = mio_sup:start_node(key5, value5, mio_mvector:make([1, 0])),
    {ok, Node9} = mio_sup:start_node(key9, value9, mio_mvector:make([1, 0])),

    ok = link_nodes(0, [Node3, Node5, Node9]),
    ok = link_nodes(1, [Node3, Node9]),

    %% dump nodes on Level 0 and 1
    [{key3, value3}, {key5, value5}, {key9, value9}] = mio_node:dump_nodes(Node3, 0),

    %% search!
    {ok, value3} = mio_node:search(Node3, key3),
    {ok, value3} = mio_node:search(Node5, key3),
    {ok, value3} = mio_node:search(Node9, key3),

    {ok, value5} = mio_node:search(Node3, key5),
    {ok, value5} = mio_node:search(Node5, key5),
    {ok, value5} = mio_node:search(Node9, key5),

    {ok, value9} = mio_node:search(Node3, key9),
    {ok, value9} = mio_node:search(Node5, key9),

    ng = mio_node:search(Node5, key10),
    %% closest node should be returned
    {ok, key5, value5} = gen_server:call(Node5, {search, Node5, [], key8}),
    ok.

search_level2_3(_Config) ->
    %% We want to test search-op without insert op.
    %%   setup predefined nodes as follows.
    %%     level1 [3 <-> 7 <-> 9] [5 <-> 8]
    %%     level0 [3 <-> 5 <-> 7 <-> 8 <-> 9]
    {ok, Node3} = mio_sup:start_node(key3, value3, mio_mvector:make([1, 0])),
    {ok, Node5} = mio_sup:start_node(key5, value5, mio_mvector:make([1, 0])),
    {ok, Node7} = mio_sup:start_node(key7, value7, mio_mvector:make([1, 0])),
    {ok, Node8} = mio_sup:start_node(key8, value8, mio_mvector:make([1, 0])),
    {ok, Node9} = mio_sup:start_node(key9, value9, mio_mvector:make([1, 0])),

    %% level 0
    ok = link_nodes(0, [Node3, Node5, Node7, Node8, Node9]),

    %% level 1
    ok = link_nodes(1, [Node3, Node7, Node9]),
    ok = link_nodes(1, [Node5, Node8]),

    %% dump nodes on Level 0 and 1
    [{key3, value3}, {key5, value5}, {key7, value7}, {key8, value8}, {key9, value9}] = mio_node:dump_nodes(Node3, 0),

    %% search!
    %%  level1: 3->7 level0: 7->8
    {ok, value8} = mio_node:search(Node3, key8),
    {ok, value3} = mio_node:search(Node3, key3),
    {ok, value5} = mio_node:search(Node3, key5),
    {ok, value7} = mio_node:search(Node3, key7),
    {ok, value9} = mio_node:search(Node3, key9),

    {ok, value8} = mio_node:search(Node5, key8),
    {ok, value3} = mio_node:search(Node5, key3),
    {ok, value5} = mio_node:search(Node5, key5),
    {ok, value7} = mio_node:search(Node5, key7),
    {ok, value9} = mio_node:search(Node5, key9),

    {ok, value8} = mio_node:search(Node7, key8),
    {ok, value3} = mio_node:search(Node7, key3),
    {ok, value5} = mio_node:search(Node7, key5),
    {ok, value7} = mio_node:search(Node7, key7),
    {ok, value9} = mio_node:search(Node7, key9),

    {ok, value8} = mio_node:search(Node8, key8),
    {ok, value3} = mio_node:search(Node8, key3),
    {ok, value5} = mio_node:search(Node8, key5),
    {ok, value7} = mio_node:search(Node8, key7),
    {ok, value9} = mio_node:search(Node8, key9),

    {ok, value8} = mio_node:search(Node9, key8),
    {ok, value3} = mio_node:search(Node9, key3),
    {ok, value5} = mio_node:search(Node9, key5),
    {ok, value7} = mio_node:search(Node9, key7),
    {ok, value9} = mio_node:search(Node9, key9),


    ng = mio_node:search(Node5, key10),
    ng = mio_node:search(Node5, key6),
    %% closest node should be returned
    %% Is this ok?
    %%  The definition of closest node will change depends on whether search direction is right or left.
    {ok, key9, value9} = gen_server:call(Node5, {search, Node5, [], key9_9}),
    {ok, key7, value7} = gen_server:call(Node9, {search, Node9, [], key6}),
    ok.

test_set_nth(_Config) ->
    [1, 3] = mio_node:set_nth(2, 3, [1, 2]),
    [0, 2] = mio_node:set_nth(1, 0, [1, 2]),
    ok.

all() ->
    [test_set_nth, get_call, left_right_call, dump_nodes_call, search_call, search_level2_simple, search_level2_1, search_level2_2, search_level2_3].

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------
link_node(Level, NodeA, NodeB) ->
    ok = mio_node:set_right(NodeA, Level, NodeB),
    ok = mio_node:set_left(NodeB, Level, NodeA).

link_nodes(Level, [NodeA | [NodeB | More]]) ->
    link_node(Level, NodeA, NodeB),
    link_nodes(Level, [NodeB | More]);
link_nodes(Level, []) -> ok;
link_nodes(Level, [Node | []]) -> ok.

