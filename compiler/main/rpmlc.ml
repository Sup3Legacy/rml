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

(* file: main.ml *)

(* Warning: *)
(* This file is based on the original version of main.ml *)
(* from the Lucid Synchrone version 2 distribution, Lip6 *)

(* first modification: 2004-05-06 *)
(* modified by: Louis Mandel      *)

(* $Id$ *)

open Misc
open Modules
open Compiler
open Compiler_options

(* list of object files passed on the command line *)
let object_files = ref []

let compile file =
  if Filename.check_suffix file ".rml"
  then
    let filename = Filename.chop_suffix file ".rml" in
    let modname = Filename.basename filename in
    compile_implementation (String.capitalize modname) filename;
    object_files := modname::!object_files
  else if Filename.check_suffix file ".rmli"
  then
    let filename = Filename.chop_suffix file ".rmli" in
    compile_interface (String.capitalize (Filename.basename filename)) filename
  else if Filename.check_suffix file ".mli"
  then
    let filename = Filename.chop_suffix file ".mli" in
    compile_scalar_interface
      (String.capitalize (Filename.basename filename)) filename
  else
    raise (Arg.Bad ("don't know what to do with " ^ file))


let main () =
  try
    set_init_stdlib ();
    set_init_pervasives ();
    parse_cli ();
    List.iter compile !to_compile
  with x ->
    Errors.report_error Format.err_formatter x;
    exit 2
;;

let _ =
  main ();
  (*if !interactive then Interactive.compile ();*)
  if !dtime then Diagnostic.print stderr;
  exit 0

