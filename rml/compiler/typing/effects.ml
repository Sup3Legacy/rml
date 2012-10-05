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

open Usages

module Key = struct
    type t = Id of Ident.t | Var of Ident.t
    let compare = Pervasives.compare
end

module M = Map.Make(Key)

type key = M.key
type t = signal_usage M.t

let id x = Key.Id x
let var x = Key.Var x

(* generating fresh names *)
let new_id s =
  Ident.create Ident.gen_var s Ident.Val_RML

let empty = M.empty
let is_empty = M.is_empty
let mem = M.mem
let find = M.find
let iter = M.iter

let add k loc u_emit u_get m =
  let su = Usages.mk_su loc u_emit u_get in
  M.add k su m

let singleton k loc ty_emit ty_get =
  add (Key.Id k) loc ty_emit ty_get empty

let merge t1 t2 =
  M.fold (fun k u1 t ->
    try
      let u2 = M.find k t in
      match k with
        | Key.Id i -> M.add k (add_s u1 u2) t
        | Key.Var i -> M.add k (max_s u1 u2) t
    with Not_found ->
      M.add k u1 t
  )
  t1
  t2

let rec flatten = function
| [] -> empty
| a::l -> merge a (flatten l)

let apply u m =
  M.fold
    (fun k v t ->
      match k with
        | Key.Id _ -> M.add k (add_s u (Usages.constraints v)) t
        | Key.Var _ -> M.add k (max_s u v) t
    )
    m
    empty

let apply_m m1 m2 =
  let vars = M.fold
    (fun k v t ->
      match k with
        | Key.Id _ -> t
        | Key.Var k -> v::t
    )
    m2
    [] in
  match vars with
    | [] -> m1
    | u::_ ->
        M.fold
          (fun k v t ->
            match k with
              | Key.Id _ -> M.add k u t
              | Key.Var _ -> M.add k (max_s u v) t
          )
          m1
          empty

let update_loc m loc =
  M.map (Usages.update_loc loc) m

let gen non_gen m =
  M.fold
    (fun k u t ->
      match k with
        | Key.Id i ->
            if non_gen i
            then M.add k u t
            else M.add (var i) u t
        | Key.Var _ ->
            M.add k u t
    )
    m
    empty

let instance m =
  M.fold
    (fun k u t ->
      match k with
      | Key.Id i ->
          M.add k u t
      | Key.Var i ->
          let new_i = new_id i.Ident.name in
          M.add
            (Key.Id new_i)
            u
            (M.add (Key.Var i) u t)
    )
    m
    empty

let print t =
  if not (M.is_empty t) then begin
    Printf.printf "  ";
    M.iter (fun k v ->
      let v = string_of_signal_usage v in
      match k with
        | Key.Id i -> Printf.printf "Id(%s):%s; " (Ident.unique_name i) v
        | Key.Var i -> Printf.printf "Var(%s):%s; " (Ident.unique_name i) v
      ;
    )
    t;
    Printf.printf "\n%!"
  end
