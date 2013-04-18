(**********************************************************************)
(*                                                                    *)
(*                           ReactiveML                               *)
(*                    http://reactiveML.org                           *)
(*                    http://rml.inria.fr                             *)
(*                                                                    *)
(*                          Louis Mandel                              *)
(*                                                                    *)
(*  Copyright 2002, 2007 Louis Mandel.  All rights reserved.          *)
(*  This file is distributed under the terms of the Q Public License  *)
(*  version 1.0.                                                      *)
(*                                                                    *)
(*  ReactiveML has been done in the following labs:                   *)
(*  - theme SPI, Laboratoire d'Informatique de Paris 6 (2002-2005)    *)
(*  - Verimag, CNRS Grenoble (2005-2006)                              *)
(*  - projet Moscova, INRIA Rocquencourt (2006-2007)                  *)
(*                                                                    *)
(**********************************************************************)

(* file: def_types.ml *)

(* Warning: *)
(* This file has been done from CamlLight, Lucid Synchrone and the book *)
(* "Le langage Caml" Pierre Weis Xavier Leroy *)

(* first modification: 2004-04-23 *)
(* author: Louis Mandel *)

(* $Id$ *)

(* The abstract syntax for the types *)

open Asttypes
open Global

type 'a global = (unit, 'a) Global.global

(* types *)
type clock_scheme =
    { cs_vars : clock_param list;
      cs_desc: clock;                (* the type *)
    }

and clock = clock_desc repr
and clock_desc =
  | Clock_static
  | Clock_var
  | Clock_depend of carrier_row
  | Clock_arrow of clock * clock * effect_row
  | Clock_product of clock list
  | Clock_constr of clock_constr global * clock_param list
  | Clock_process of clock * carrier * effect_row * react_effect
    (* result clock, activation carrier, reactivity effect *)
  | Clock_link of clock
  | Clock_forall of clock_scheme

and carrier = carrier_desc repr
and carrier_desc =
  | Carrier_var of string           (* a. keep a source name when possible *)
  | Carrier_skolem of string * int  (* skolem name c *)
  | Carrier_link of carrier

and carrier_row = carrier_row_desc repr
and carrier_row_desc =
  | Carrier_row_empty
  | Carrier_row_var
  | Carrier_row_one of carrier
  | Carrier_row of carrier_row * carrier_row (* row var last in prefix traversal *)
  | Carrier_row_link of carrier_row

and effect = effect_desc repr
and effect_desc =
  | Effect_empty
  | Effect_var
  | Effect_depend of carrier_row
  | Effect_one of effect_row
  | Effect_sum of effect * effect
  | Effect_link of effect

and effect_row = effect_row_desc repr
and effect_row_desc =
  | Effect_row_var
  | Effect_row_empty
  | Effect_row_one of effect
  | Effect_row of effect_row * effect_row (* row var last in prefix traversal *)
  | Effect_row_link of effect_row
  | Effect_row_rec of effect_row

and react_effect = react_effect_desc repr

and react_effect_desc =
  | React_var
  | React_empty
  | React_carrier of carrier_row
  | React_seq of react_effect list
  | React_par of react_effect list
  | React_or of react_effect list
  | React_rec of bool * react_effect
  | React_run of react_effect
  | React_link of react_effect


(* Type constructors *)
and clock_constr =
    { mutable constr_abbr: clock_abbrev }      (* Abbreviation or not *)

and clock_param = (clock, carrier, carrier_row, effect, effect_row, react_effect) kind_sum

and clock_abbrev =
  | Constr_notabbrev
  | Constr_abbrev of clock_param list * clock (* Parameters and body *)

(* Value descriptions *)

and value_clock_description =
    { value_ck: clock_scheme; }


(* Constructor descriptions *)

and constructor_clock_description =
    { cstr_arg: clock option;
      cstr_res: clock; }


(* Record label descriptions *)
(* type t_arg = {e.label: t_res;...} *)
and label_clock_description =
    { lbl_res: clock;          (* Result type *)
      lbl_arg: clock;          (* Argument type *)
      lbl_mut: mutable_flag;             (* Mutable or not *)
    }

(* Type definitions *)

and clock_description =
    { clock_constr: clock_constr global;
      clock_kind: clock_kind;
      clock_def_arity : arity;
      clock_arity: arity; }

and clock_kind =
    Clock_abstract
  | Clock_rebind of clock
  | Clock_variant of constructor_clock_description global list
  | Clock_record of label_clock_description global list

type exception_declaration = clock list

let generic = (-1)
and notgeneric = 0

let clock_of_global g = (ck_info g).value_ck
let clock_of_constr_arg g = (ck_info g).cstr_arg
let clock_of_label_res g = (ck_info g).lbl_res
