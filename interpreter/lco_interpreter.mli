(**********************************************************************)
(*                                                                    *)
(*                           ReactiveML                               *)
(*                    http://reactiveML.org                           *)
(*                    http://rml.inria.fr                             *)
(*                                                                    *)
(*                          Louis Mandel                              *)
(*                                                                    *)
(*  Copyright 2002, 2007 Louis Mandel.  All rights reserved.          *)
(*  This file is distributed under the terms of the GNU Library       *)
(*  General Public License, with the special exception on linking     *)
(*  described in file ../LICENSE.                                     *)
(*                                                                    *)
(*  ReactiveML has been done in the following labs:                   *)
(*  - theme SPI, Laboratoire d'Informatique de Paris 6 (2002-2005)    *)
(*  - Verimag, CNRS Grenoble (2005-2006)                              *)
(*  - projet Moscova, INRIA Rocquencourt (2006-2007)                  *)
(*                                                                    *)
(**********************************************************************)

(* file: lco_interpreter.mli *)
(* author: Louis Mandel *)
(* created: 2004-06-04  *)


module type S =
  functor (Step : Runtime.STEP with type 'a t = 'a -> unit) ->
    functor (R : Runtime.R with module Step = Step) ->
  sig
    type event_cfg

    type 'a expr
    and 'a process = unit -> 'a expr

    val rml_make: 'a option ref -> 'a process -> unit Step.t

    val rml_pre_status: ('a, 'b) R.event -> bool
    val rml_pre_value: ('a, 'b) R.event -> 'b
    val rml_last: ('a, 'b) R.event -> 'b
    val rml_default: ('a, 'b) R.event -> 'b

    val rml_expr_emit: (unit, 'b) R.event -> unit
    val rml_expr_emit_val: ('a, 'b) R.event -> 'a -> unit

    val rml_global_signal: unit -> ('a, 'a list) R.event
    val rml_global_signal_combine: 'b -> ('a -> 'b -> 'b) -> ('a, 'b) R.event

    val cfg_present': ('a,'b) R.event -> event_cfg
    val cfg_present: (unit -> ('a,'b) R.event) -> event_cfg
    val cfg_and: event_cfg -> event_cfg -> event_cfg
    val cfg_or: event_cfg -> event_cfg -> event_cfg

    val rml_nothing: unit expr
    val rml_compute: (unit -> 'a) -> 'a expr
    val rml_pause: unit expr
    val rml_halt: 'a expr
    val rml_pause_kboi: unit expr
    val rml_halt_kboi: 'a expr
    val rml_emit': (unit, 'b) R.event -> unit expr
    val rml_emit: (unit -> (unit, 'b) R.event) -> unit expr
    val rml_emit_val': ('a, 'b) R.event -> (unit -> 'a) -> unit expr
    val rml_emit_val: (unit -> ('a, 'b) R.event) -> (unit -> 'a) -> unit expr
    val rml_get: (unit -> ('a, 'b) R.event) -> ('b -> 'c expr) -> 'c expr
    val rml_await': ('a, 'b) R.event -> unit expr
    val rml_await: (unit -> ('a, 'b) R.event) -> unit expr
    val rml_await_conf: event_cfg -> unit expr
    val rml_await_immediate': ('a, 'b) R.event -> unit expr
    val rml_await_immediate: (unit -> ('a, 'b) R.event) -> unit expr
    val rml_await_immediate_conf: event_cfg -> unit expr
    val rml_await_all': ('a, 'b) R.event -> ('b -> 'c expr) -> 'c expr
    val rml_await_all: (unit -> ('a, 'b) R.event) -> ('b -> 'c expr) -> 'c expr
    val rml_await_all_match':
        ('a, 'b) R.event -> ('b -> bool) -> ('b -> 'c expr) -> 'c expr
    val rml_await_all_match:
        (unit -> ('a, 'b) R.event) -> ('b -> bool) -> ('b -> 'c expr) -> 'c expr
    val rml_await_one':
        ('a , 'a list) R.event -> ('a -> 'c expr) -> 'c expr
    val rml_await_one:
        (unit -> ('a , 'a list) R.event) -> ('a -> 'c expr) -> 'c expr
    val rml_await_immediate_one':
        ('a , 'a list) R.event -> ('a -> 'c expr) -> 'c expr
    val rml_await_immediate_one:
        (unit -> ('a , 'a list) R.event) -> ('a -> 'c expr) -> 'c expr
    val rml_present': ('a, 'b) R.event -> 'c expr -> 'c expr -> 'c expr
    val rml_present: (unit -> ('a, 'b) R.event) -> 'c expr -> 'c expr -> 'c expr
    val rml_present_conf: event_cfg -> 'a expr -> 'a expr -> 'a expr
    val rml_seq: 'a expr -> 'b expr -> 'b expr
    val rml_par: 'a expr -> 'b expr -> unit expr
    val rml_merge: 'a expr -> 'b expr -> unit expr
    val rml_loop: 'a expr -> unit expr
    val rml_loop_n: (unit -> int) -> 'a expr -> unit expr
    val rml_while: (unit -> bool) -> 'a expr -> unit expr
    val rml_for:
        (unit -> int) -> (unit -> int) -> bool -> (int -> 'a expr) ->
          unit expr
    val rml_fordopar:
        (unit -> int) -> (unit -> int) -> bool -> (int -> 'a expr) ->
          unit expr
    val rml_signal: (('a, 'a list) R.event -> 'b expr) -> 'b expr
    val rml_signal_combine:
        (unit -> 'b) -> (unit -> ('a -> 'b -> 'b)) ->
          (('a, 'b) R.event -> 'c expr) -> 'c expr
    val rml_def: (unit -> 'a) -> ('a -> 'b expr) -> 'b expr
    val rml_def_dyn: 'a expr -> ('a -> 'b expr) -> 'b expr
(*    val rml_def_and_dyn: expr array -> (value array -> expr) -> expr *)
    val rml_match: (unit -> 'a) -> ('a -> 'b expr) -> 'b expr
    val rml_run: (unit -> 'a process) -> 'a expr
    val rml_until': ('a, 'b) R.event -> unit expr -> unit expr
    val rml_until: (unit -> ('a, 'b) R.event) -> unit expr -> unit expr
    val rml_until_conf: event_cfg -> unit expr -> unit expr
    val rml_until_handler':
        ('a, 'b) R.event -> 'c expr -> ('b -> 'c expr) -> 'c expr
    val rml_until_handler:
        (unit -> ('a, 'b) R.event) -> 'c expr -> ('b -> 'c expr) -> 'c expr
    val rml_until_handler_match':
        ('a, 'b) R.event -> ('b -> bool) -> 'c expr -> ('b -> 'c expr) -> 'c expr
    val rml_until_handler_match:
        (unit -> ('a, 'b) R.event) -> ('b -> bool) ->
          'c expr -> ('b -> 'c expr) -> 'c expr
    val rml_control': ('a, 'b) R.event -> 'c expr -> 'c expr
    val rml_control: (unit -> ('a, 'b) R.event) -> 'c expr -> 'c expr
    val rml_control_match': ('a, 'b) R.event -> ('b -> bool) -> 'c expr -> 'c expr
    val rml_control_match:
        (unit -> ('a, 'b) R.event) -> ('b -> bool) -> 'c expr -> 'c expr
    val rml_control_conf: event_cfg -> 'c expr -> 'c expr
    val rml_when': ('a, 'b) R.event -> 'c expr -> 'c expr
    val rml_when: (unit -> ('a, 'b) R.event) -> 'c expr -> 'c expr
    val rml_when_conf: event_cfg -> 'c expr -> 'c expr
    val rml_if: (unit -> bool) -> 'a expr -> 'a expr -> 'a expr

    val rml_par_n : unit expr list -> unit expr
(*
    val rml_seq_n : expr list -> expr
*)

  end
