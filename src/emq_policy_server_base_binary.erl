%%%--------------------------------------------------------------------------------
%% emq_policy_server_base_binary
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

-module(emq_policy_server_base_binary).
%% Bytes
-export([reverse/1
  , join/2
  , duplicate/2
  , suffix/2
  , prefix/2
]).

%% Bits
-export([union/2
  , subtract/2
  , intersection/2
  , inverse/1
]).

%% Trimming
-export([trimBOM/1, rtrim/1
  , rtrim/2
  , ltrim/1
  , ltrim/2
  , trim/1
  , trim/2
]).

%% Parsing
-export([bin_to_int/1]).

%% Matching
-export([optimize_patterns/1]).

trimBOM(S) ->
  ltrim(ltrim(ltrim(S, "\xEF"), "\xBB"), "\xBF").

trim(B) -> trim(B, 0).
ltrim(B) -> ltrim(B, 0).
rtrim(B) -> rtrim(B, 0).


rtrim(B, X) when is_binary(B), is_integer(X) ->
  S = byte_size(B),
  do_rtrim(S, B, X);
rtrim(B, [_ | _] = Xs) when is_binary(B) ->
  S = byte_size(B),
  do_mrtrim(S, B, Xs).


ltrim(B, X) when is_binary(B), is_integer(X) ->
  do_ltrim(B, X);
ltrim(B, [_ | _] = Xs) when is_binary(B) ->
  do_mltrim(B, Xs).


%% @doc The second element is a single integer element or an ordset of elements.
trim(B, X) when is_binary(B), is_integer(X) ->
  From = ltrimc(B, X, 0),
  case byte_size(B) of
    From ->
      <<>>;
    S ->
      To = do_rtrimc(S, B, X),
      binary:part(B, From, To - From)
  end;
trim(B, [_ | _] = Xs) when is_binary(B) ->
  From = mltrimc(B, Xs, 0),
  case byte_size(B) of
    From ->
      <<>>;
    S ->
      To = do_mrtrimc(S, B, Xs),
      binary:part(B, From, To - From)
  end.



do_ltrim(<<X, B/binary>>, X) ->
  do_ltrim(B, X);
do_ltrim(B, _X) ->
  B.


%% multi, left trimming.
do_mltrim(<<X, B/binary>> = XB, Xs) ->
  case ordsets:is_element(X, Xs) of
    true -> do_mltrim(B, Xs);
    false -> XB
  end;
do_mltrim(<<>>, _Xs) ->
  <<>>.


do_rtrim(0, _B, _X) ->
  <<>>;
do_rtrim(S, B, X) ->
  S2 = S - 1,
  case binary:at(B, S2) of
    X -> do_rtrim(S2, B, X);
    _ -> binary_part(B, 0, S)
  end.


%% Multiple version of do_rtrim.
do_mrtrim(0, _B, _Xs) ->
  <<>>;
do_mrtrim(S, B, Xs) ->
  S2 = S - 1,
  X = binary:at(B, S2),
  case ordsets:is_element(X, Xs) of
    true -> do_mrtrim(S2, B, Xs);
    false -> binary_part(B, 0, S)
  end.


ltrimc(<<X, B/binary>>, X, C) ->
  ltrimc(B, X, C + 1);
ltrimc(_B, _X, C) ->
  C.


%% multi, left trimming, returns a count of matched bytes from the left.
mltrimc(<<X, B/binary>>, Xs, C) ->
  case ordsets:is_element(X, Xs) of
    true -> mltrimc(B, Xs, C + 1);
    false -> C
  end;
mltrimc(<<>>, _Xs, C) ->
  C.


% This clause will never be matched.
%do_rtrimc(0, _B, _X) ->
%    0;
do_rtrimc(S, B, X) ->
  S2 = S - 1,
  case binary:at(B, S2) of
    X -> do_rtrimc(S2, B, X);
    _ -> S
  end.


do_mrtrimc(S, B, Xs) ->
  S2 = S - 1,
  X = binary:at(B, S2),
  case ordsets:is_element(X, Xs) of
    true -> do_mrtrimc(S2, B, Xs);
    false -> S
  end.


%% @doc Reverse the bytes' order.
reverse(Bin) when is_binary(Bin) ->
  S = bit_size(Bin),
  <<V:S/integer-little>> = Bin,
  <<V:S/integer-big>>.


join([B | Bs], Sep) when is_binary(Sep) ->
  iolist_to_binary([B | add_separator(Bs, Sep)]);

join([], _Sep) ->
  <<>>.

add_separator([B | Bs], Sep) ->
  [Sep, B | add_separator(Bs, Sep)];
add_separator([], _) ->
  [].


%% @doc Repeat the binary `B' `C' times.
duplicate(C, B) ->
  iolist_to_binary(lists:duplicate(C, B)).


prefix(B, L) when is_binary(B), is_integer(L), L > 0 ->
  binary:part(B, 0, L).


suffix(B, L) when is_binary(B), is_integer(L), L > 0 ->
  S = byte_size(B),
  binary:part(B, S - L, L).


union(B1, B2) ->
  S = bit_size(B1),
  <<V1:S>> = B1,
  <<V2:S>> = B2,
  V3 = V1 bor V2,
  <<V3:S>>.


subtract(B1, B2) ->
  S = bit_size(B1),
  <<V1:S>> = B1,
  <<V2:S>> = B2,
  V3 = (V1 bxor V2) band V1,
  <<V3:S>>.


intersection(B1, B2) ->
  S = bit_size(B1),
  <<V1:S>> = B1,
  <<V2:S>> = B2,
  V3 = V1 band V2,
  <<V3:S>>.


inverse(B1) ->
  S = bit_size(B1),
  <<V1:S>> = B1,
  V2 = bnot V1,
  <<V2:S>>.

%% @doc string:to_integer/1 for binaries
bin_to_int(Bin) ->
  bin_to_int(Bin, 0).

bin_to_int(<<H, T/binary>>, X) when $0 =< H, H =< $9 ->
  bin_to_int(T, (X * 10) + (H - $0));
bin_to_int(Bin, X) ->
  {X, Bin}.

%% Remove longer patterns if shorter pattern matches
%% Useful to run before binary:compile_pattern/1
optimize_patterns(Patterns) ->
  Sorted = lists:usort(Patterns),
  remove_long_duplicates(Sorted).

remove_long_duplicates([H | T]) ->
  %% match(Subject, Pattern)
  DedupT = [X || X <- T, binary:match(X, H) =:= nomatch],
  [H | remove_long_duplicates(DedupT)];
remove_long_duplicates([]) ->
  [].


