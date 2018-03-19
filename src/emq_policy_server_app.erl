%%%--------------------------------------------------------------------------------
%% The MIT License (MIT)
%%
%% Copyright (c) 2017 Whoopschat
%%
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/ or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in all
%% copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%% SOFTWARE.
%%%--------------------------------------------------------------------------------

-module(emq_policy_server_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  reg_auth(),
  reg_acl(),
  {ok, Sup} = emq_policy_server_module_super:start_link(),
  emq_policy_server_module_connect:load(application:get_all_env()),
  emq_policy_server_module_group:load(application:get_all_env()),
  emq_policy_server_module_hook:load(application:get_all_env()),
  {ok, Sup}.

stop(_State) ->
  emq_policy_server_module_connect:unload(),
  emq_policy_server_module_group:unload(),
  emq_policy_server_module_hook:unload().

reg_auth() ->
  emqttd_access_control:register_mod(auth, emq_policy_server_module_auth, undefined),
  ok.

reg_acl() ->
  emqttd_access_control:register_mod(acl, emq_policy_server_module_cal, undefined),
  ok.