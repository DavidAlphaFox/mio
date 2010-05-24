%%-define(PROFILER_ON, true).
%%-define(DEBUG_ON, true).

-record(node, {store, type, min_key, encompass_min, max_key, encompass_max, left, right, membership_vector, gen_mvector,
                expire_time, inserted, deleted, allocator
               }).


-define(SERVER, ?MODULE).
-define(INFOF(Msg, Args), error_logger:info_msg(Msg ++ " ~p:~p~p~n", Args ++ [?MODULE, ?LINE, self()])).
-define(INFO(Msg), ?INFOF(Msg, [])).

%%-define(MIN_KEY, <<16#20>>).
-define(MIN_KEY, "").
-define(MAX_KEY, <<16#7F>>).

-define(LOG(Msg), io:format(Msg ++ " ~p:~p~p~n", [?MODULE, ?LINE, self()])).
-define(LOGF(Msg, Args), io:format(Msg ++ " ~p:~p~p~n", Args ++ [?MODULE, ?LINE, self()])).


%% ERROR should be always written to stderr.
-define(ERRORF(Msg, Args), error_logger:error_msg(Msg ++ " ~p:~p~n", Args ++ [?MODULE, ?LINE]), io:format(Msg ++ "~n", Args)).
-define(ERROR(Msg), ?ERRORF(Msg, [])).
-define(FATALF(Msg, Arg), mio_app:fatal(Msg, Arg, ?MODULE, ?LINE)).
-define(WARNF(Msg, Args), error_logger:warn_msg(Msg ++ " ~p:~p~n", Args ++ [?MODULE, ?LINE])).
-define(WARN(Msg), ?WARNF(Msg, [])).

-ifdef (DEBUG_ON).
  -define(CHECK_SANITY(Node, Level), mio_debug:check_sanity(Node, Level, ?MODULE, ?LINE)).
  -define(ASSERT_MATCH(EXPECTED, X),
          case X of
              EXPECTED -> true;
              _ ->
                  io:format("** Assertion failed: ~p expected, but got ~p at ~p:~p~n", [EXPECTED, X, ?MODULE, ?LINE]),
                  exit(assertion_failed)
          end.
  -define(ASSERT_NOT_NIL(X),
          case X of
              [] ->
                  io:format("** Assertion failed~p: not [] expected, but got [] at ~p:~p~n", [self(), ?MODULE, ?LINE]),
                  exit(assertion_failed);
              _ ->
                  true
          end.
-else.
  -define(CHECK_SANITY(Node, Level), []).
  -define(ASSERT_MATCH(EXPECTED, X), []).
  -define(ASSERT_NOT_NIL(X), []).
-endif.

-ifdef (PROFILER_ON).
  -define(PROFILER_STOP(), fprof:trace([stop]), fprof:profile(), fprof:analyse([totals, {details, true}]), fprof:stop()).
  -define(PROFILER_START(X), fprof:trace([start, {procs, [X]}])).
-else.
  -define(PROFILER_STOP(), []).
  -define(PROFILER_START(X), []).
-endif.