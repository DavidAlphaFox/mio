#!/usr/bin/env escript
%% -*- erlang -*-
%%! -name mochiweb__test@127.0.0.1
main([Ebin]) ->
    code:add_path(Ebin),
    TestModules = [{file, Ebin ++ hd(string:tokens(M, ".")) ++ ".beam"}
                             || "../test/" ++ M <- filelib:wildcard("../test/*.erl")],

    CoverModules = [list_to_atom(hd(string:tokens(M, ".")))
                             || M <- filelib:wildcard("*.erl")],

    crypto:start(),
    start_cover(CoverModules),
    eunit:test(TestModules),
    analyze_cover(CoverModules);
main(_) ->
    io:format("usage: run_tests.escript EBIN_DIR~n"),
    halt(1).

start_cover(Modules) ->
    {ok, _Cover} = cover:start(),
    Compiled = [ M || {ok, M} <- [ cover:compile(
                                     M,
                                     [{i, "include"}
                                     ])
                                   || M <- Modules ] ],
    case length(Modules) == length(Compiled) of
        true -> ok;
        false ->
            io:format("Warning: the following modules were not"
                      " cover-compiled:~n   ~p~n", [Compiled])
    end.

analyze_cover(Modules) ->
    CoverBase = filename:join(["..", "_test", "cover"]),
    ok = filelib:ensure_dir(filename:join([CoverBase, "fake"])),
    Coverages = lists:foldl(
                  fun(M, Acc) ->
                          [analyze_module(CoverBase, M)|Acc]
                  end,
                  [], Modules),
    IndexFilename = filename:join([CoverBase, "index.html"]),
    {ok, Index} = file:open(IndexFilename, [write]),
    {LineTotal, CoverTotal} =
        lists:foldl(fun({_,_,Lines,Covered}, {LineAcc, CovAcc}) ->
                            {LineAcc+Lines, CovAcc+Covered}
                    end, {0,0}, Coverages),
    file:write(Index,
               "<html><head><title>Coverage</title></head>\n"
               "<body><h1>Coverage</h1><ul>\n"),
    file:write(Index,
               io_lib:format("<h2>Total: ~.2f%</h2>\n",
                             [percentage(CoverTotal, LineTotal)])),
    [ file:write(Index,
                 io_lib:format(
                   "<li><a href=\"~s\">~p</a>: ~.2f%</li>~n",
                   [Filename, Module, percentage(Covered, Lines)]))
      || {Filename, Module, Lines, Covered} <- Coverages ],
    file:write(Index,"</ul></body></html>"),
    file:close(Index),
    io:format("Cover analysis in ~s~n", [IndexFilename]).

analyze_module(CoverBase, Module) ->
    {ok, Filename} =
        cover:analyze_to_file(
          Module,
          filename:join(CoverBase, atom_to_list(Module)++".COVER.html"),
          [html]),
    Lines = count_lines(Filename, "[[:digit:]]\.\.|"),
    Covered = count_lines(Filename, "[[:space:]]0\.\.|"),
    {filename:basename(Filename), Module, Lines, Lines-Covered}.

count_lines(Filename, Pattern) ->
    {ok, [Lines],_} = io_lib:fread(
                        "~d",
                        os:cmd(io_lib:format("grep -e \"~s\" ~s | wc -l",
                                             [Pattern, Filename]))),
    Lines.

percentage(_, 0) -> 1000.0;
percentage(Part, Total) ->
    (Part/Total)*100.
