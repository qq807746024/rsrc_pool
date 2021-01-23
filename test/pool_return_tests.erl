%%
%% Copyright (C) 2010-2013 by krasnop@bellsouth.net (Alexei Krasnopolski)
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License. 
%%

%% @hidden
%% @since 2012-12-01
%% @copyright 2010-2013 Alexei Krasnopolski
%% @author Alexei Krasnopolski <krasnop@bellsouth.net> [http://crasnopolski.com/]
%% @version {@version}
%% @doc This module is running unit tests for helper_common module.

-module(pool_return_tests).

%%
%% Include files
%%
-include_lib("eunit/include/eunit.hrl").
-include("test.hrl").

%%
%% Import modules
%%
-import(resource_pool, []).
-import(resource_factory, []).
-import(resource_pool_tests, [f2/0]).

%%
%% Exported Functions
%%
-export([]).

%%
%% API Functions
%%

resource_pool_test_() ->
	[ 
    {foreachx, 
      fun do_setup/1, 
      fun resource_pool_tests:do_cleanup/2, 
      [
        {test_on, fun return_test_on/2},
        {test_on_true, fun return_test_on_true/2},
        {max_idle_time, fun return_max_idle_time/2},
        {owner, fun return_owner/2}
      ]
    }
	]
.

do_setup(X) ->
  ?debug_Fmt("setup: ~p", [X]), 
  Options = set(X),   
  {ok, Pid} = resource_pool:new(test_pool, factory, 0, Options),
  Pid
.

set(test_on) -> [];
set(test_on_true) -> [{test_on_return, true}];
set(max_idle_time) -> [{max_active, 2}, {max_idle_time, 200}];
set(_) -> [].

return_max_idle_time(_X, Pool) -> {timeout, 100, fun() ->
%  ?debug_Fmt("    : pool return test: ~p",[X]),
  resource_pool:borrow(Pool),
  Ref_a = resource_pool:borrow(Pool),
  tst_resource:set_id(Ref_a, 7),
%  ?debug_Fmt("       1. Ref: ~p",[Ref_a]),
  ?assertEqual({2, 0}, f2()),
  resource_pool:return(Pool, Ref_a),
  ?assert(is_process_alive(Ref_a)),
  ?assertEqual({1, 1}, f2()),
  timer:sleep(200),
  ?assertEqual({1, 0}, f2()),
  ?assert(not is_process_alive(Ref_a)),
  ?PASSED
end}.

return_test_on(_X, Pool) -> fun() ->
%  ?debug_Fmt("    : pool return test: ~p",[X]),
  Rsrc = resource_pool:borrow(Pool),
  tst_resource:set_valid(Rsrc, false),
  resource_pool:return(Pool, Rsrc),
  ?assertEqual({0,1}, f2()),
  Rsrc1 = resource_pool:borrow(Pool),
  ?assert(is_process_alive(Rsrc1)),
  ?assert(not tst_resource:is_valid(Rsrc1)),
  ?assertEqual({1,0}, f2()),
  ?PASSED
end.

return_test_on_true(_X, Pool) -> fun() ->
%  ?debug_Fmt("    : pool return test: ~p",[X]),
  Rsrc = resource_pool:borrow(Pool),
  tst_resource:set_valid(Rsrc, false),
  tst_resource:set_id(Rsrc, 7),
  resource_pool:return(Pool, Rsrc),
  ?assertEqual({0,0}, f2()),
  Rsrc1 = resource_pool:borrow(Pool),
  ?assert(is_process_alive(Rsrc1)),
  ?assert(not is_process_alive(Rsrc)),
  ?assertNotEqual(7, tst_resource:get_id(Rsrc1)),
  ?assertEqual({1,0}, f2()),
  ?PASSED
end.

return_owner(_X, Pool) -> fun() ->
%  ?debug_Fmt("    : pool common test: ~p",[X]),
  resource_pool:borrow(Pool),
  Rsrc = resource_pool:borrow(Pool),
  resource_pool:borrow(Pool),
  resource_pool:borrow(Pool),
  ?assertEqual({4,0}, f2()),
  resource_pool:return(Pool, Rsrc),
  ?assertEqual({3,1}, f2()),
  resource_pool:return(Pool, Rsrc),
  ?assertEqual({3,1}, f2()),

  Self = self(),
  spawn_link(fun() -> 
               Rsrc1 = resource_pool:borrow(Pool), 
               Self ! Rsrc1
             end),
  receive
    Pid ->
      ?assertEqual({4,0}, f2()), 
      resource_pool:return(Pool, Pid),
      ?assertEqual({4,0}, f2()) 
  end,
  ?PASSED
end.

%%
%% Local Functions
%%

