%%%-------------------------------------------------------------------
%%% File    : mio_mvector_SUITE.erl
%%% Author  : higepon <higepon@labs.cybozu.co.jp>
%%% Description :
%%%
%%% Created : 30 Jun 2009 by higepon <higepon@labs.cybozu.co.jp>
%%%-------------------------------------------------------------------
-module(mio_mvector_tests).
-include_lib("eunit/include/eunit.hrl").

make_test() ->
    [1, 0] = mio_mvector:make([1, 0]).

equal_test() ->
    A = mio_mvector:make([1, 0]),
    B = mio_mvector:make([1, 0]),
    true = mio_mvector:eq(A, B).

not_equal_test() ->
    A = mio_mvector:make([1, 0]),
    B = mio_mvector:make([1, 1]),
    false = mio_mvector:eq(A, B).

get_test() ->
    A = mio_mvector:make([3, 2, 1, 0]),
    [3, 2, 1, 0] = mio_mvector:get(A, 4),
    [3, 2, 1] = mio_mvector:get(A, 3),
    [3, 2] = mio_mvector:get(A, 2),
    [3] = mio_mvector:get(A, 1),
    [] = mio_mvector:get(A, 0),
    ok.
