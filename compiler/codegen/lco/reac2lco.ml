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

(* file: reac2lco.ml *)
(* created: 2004-06-04  *)
(* author: Louis Mandel *)

(* $Id: reac2lco.ml,v 1.2 2005/03/14 09:58:54 mandel Exp $ *)

(* The translation of Reac to Lco *)

open Asttypes
open Reac
open Lco_ast
open Global
open Misc


let make_expr e loc =
  { coexpr_desc = e;
    coexpr_loc = loc; }

let make_proc e loc =
  { coproc_desc = e;
    coproc_loc = loc; }

let make_patt p loc =
  { copatt_desc = p;
    copatt_loc = loc; }

let make_te t loc =
  { cote_desc = t;
    cote_loc = loc; }

let make_ce t loc =
  { coce_desc = t;
    coce_loc = loc; }

let make_ee t loc =
  { coee_desc = t;
    coee_loc = loc; }

let make_conf c loc =
  { coconf_desc = c;
    coconf_loc = loc; }

let make_impl it loc =
  { coimpl_desc = it;
    coimpl_loc = loc; }

let make_intf it loc =
  { cointf_desc = it;
    cointf_loc = loc; }

let make_unit () =
  make_expr
    (Coexpr_constant Const_unit)
    Location.none

let make_nothing () =
  make_proc Coproc_nothing Location.none

(* Translation of type expressions *)
let rec translate_te typ =
  let cotyp =
    match typ.te_desc with
    | Tvar x -> Cotype_var x
    | Tdepend ce -> Cotype_depend (translate_ce ce)
    | Tarrow (t1, t2, ee) ->
        Cotype_arrow (translate_te t1, translate_te t2, translate_ee ee)
    | Tproduct typ_list ->
        Cotype_product (List.map translate_te typ_list)
    | Tconstr (cstr, p_list) ->
        Cotype_constr (cstr, List.map translate_pe p_list)
    | Tprocess (t, _, act, ee) ->
        Cotype_process (translate_te t, translate_ce act, translate_ee ee)
    | Tforall (pe_list, te) ->
        Cotype_forall (List.map translate_pe pe_list, translate_te te)
  in
  make_te cotyp typ.te_loc

and translate_ce ce =
  let coce =
    match ce.ce_desc with
      | Cvar s -> Cocar_var s
      | Ctopck -> Cocar_topck
  in
  make_ce coce ce.ce_loc

and translate_ee ee =
  let coee =
    match ee.ee_desc with
      | Effempty -> Coeff_empty
      | Effvar s -> Coeff_var s
      | Effsum (ee1, ee2) -> Coeff_sum (translate_ee ee1, translate_ee ee2)
      | Effdepend ce -> Coeff_depend (translate_ce ce)
  in
  make_ee coee ee.ee_loc

and translate_pe pe = match pe with
  | Ptype te -> Cop_type (translate_te te)
  | Pcarrier ce -> Cop_carrier (translate_ce ce)
  | Peffect ee -> Cop_effect (translate_ee ee)

(* Translation of type declatations *)
let rec translate_type_decl typ =
  match typ with
  | Tabstract -> Cotype_abstract
  | Trebind typ -> Cotype_rebind (translate_te typ)
  | Tvariant constr_te_list ->
      let l =
        List.map
          (fun (c, typ_opt) ->
            let typ_opt =
              match typ_opt with
              | None -> None
              | Some typ -> Some (translate_te typ)
            in
            (c, typ_opt))
          constr_te_list
      in
      Cotype_variant l
  | Trecord l ->
      let l =
        List.map
          (fun (lab, flag, typ) ->
            (lab, flag, translate_te typ))
          l
      in
      Cotype_record l

(* Translation of a pattern *)
let rec translate_pattern p =
  let copatt =
    match p.patt_desc with
    | Pany -> Copatt_any

    | Pvar x ->
        begin
          match x with
          | Vglobal gl -> Copatt_var (Covarpatt_global gl)
          | Vlocal id -> Copatt_var (Covarpatt_local id)
        end

    | Palias (patt, x) ->
        let vp =
          match x with
          | Vglobal gl -> Covarpatt_global gl
          | Vlocal id ->  Covarpatt_local id
        in
        Copatt_alias (translate_pattern patt, vp)

    | Pconstant im -> Copatt_constant im

    | Ptuple l ->
        Copatt_tuple (List.map translate_pattern l)

    | Pconstruct (constr, patt_opt) ->
        Copatt_construct (constr, opt_map translate_pattern patt_opt)

    | Por (p1, p2) ->
        Copatt_or (translate_pattern p1, translate_pattern p2)

    | Precord l ->
        Copatt_record (List.map (fun (l,p) -> (l,translate_pattern p)) l)

    | Parray l ->
        Copatt_array (List.map translate_pattern l)

    | Pconstraint (patt, typ) ->
        Copatt_constraint (translate_pattern patt, translate_te typ)

  in
  make_patt copatt p.patt_loc

(* Translation of ML expressions *)
let rec translate_ml e =
  let coexpr =
    match e.e_desc with
    | Elocal id -> Coexpr_local id

    | Eglobal gl -> Coexpr_global gl

    | Econstant im -> Coexpr_constant im

    | Elet (flag, patt_expr_list, expr) ->
        Coexpr_let (flag,
                    List.map
                      (fun (p,e) -> (translate_pattern p, translate_ml e))
                      patt_expr_list,
                    translate_ml expr)

    | Efunction  patt_expr_list ->
        Coexpr_function (List.map
                           (fun (p,e) -> (translate_pattern p, translate_ml e))
                           patt_expr_list)

    | Eapply (expr, expr_list) ->
        Coexpr_apply (translate_ml expr,
                      List.map translate_ml expr_list)

    | Etuple expr_list ->
        Coexpr_tuple (List.map translate_ml expr_list)

    | Econstruct (c, expr_opt) ->
        Coexpr_construct (c, opt_map translate_ml expr_opt)

    | Earray l ->
        Coexpr_array (List.map translate_ml l)

    | Erecord l ->
        Coexpr_record (List.map (fun (lab,e) -> lab, translate_ml e) l)

    | Erecord_access (expr, label) ->
        Coexpr_record_access (translate_ml expr, label)

    | Erecord_update (e1, label, e2) ->
        Coexpr_record_update (translate_ml e1, label, translate_ml e2)

    | Econstraint (expr, typ) ->
        Coexpr_constraint (translate_ml expr, translate_te typ)

    | Etrywith (expr, l) ->
        Coexpr_trywith (translate_ml expr,
                        List.map
                          (fun (p,e) -> translate_pattern p, translate_ml e)
                          l)
    | Eassert expr -> Coexpr_assert (translate_ml expr)

    | Eifthenelse (e1, e2, e3) ->
        Coexpr_ifthenelse (translate_ml e1,
                           translate_ml e2,
                           translate_ml e3)

    | Ematch (expr, l) ->
        Coexpr_match (translate_ml expr,
                      List.map
                        (fun (p,e) -> translate_pattern p, translate_ml e)
                        l)

    | Ewhen_match (e1, e2) ->
        Coexpr_when_match (translate_ml e1, translate_ml e2)

    | Ewhile(e1, e2) ->
        Coexpr_while (translate_ml e1, translate_ml e2)

    | Efor (id, e1, e2, flag, e3) ->
        Coexpr_for (id,
                    translate_ml e1,
                    translate_ml e2,
                    flag,
                    translate_ml e3)

    | Eseq (e1::e_list) ->
        let rec f acc l =
          match l with
          | [] -> assert false
          | [e] ->
              Coexpr_seq (acc, translate_ml e)
          | e::l' ->
              let acc' =
                make_expr
                  (Coexpr_seq (acc, translate_ml e))
                  Location.none
              in
              f acc' l'
        in f (translate_ml e1) e_list

    | Eprocess (p) ->
        Coexpr_process (translate_proc p)

    | Epre (flag,s) ->
        Coexpr_pre (flag, translate_ml s)

    | Elast s ->
        Coexpr_last (translate_ml s)

    | Edefault s ->
        Coexpr_default (translate_ml s)

    | Eemit (s, None) -> Coexpr_emit (translate_ml s)

    | Eemit (s, Some e) ->
        Coexpr_emit_val (translate_ml s, translate_ml e)

    | Esignal ((s,typ), ck, r, comb, e) ->
      let ck = match ck with
        | CkExpr e -> CkExpr (translate_ml e)
        | CkLocal -> CkLocal
        | CkTop -> CkTop
      in
      let r = match r with
        | CkExpr e -> CkExpr (translate_ml e)
        | CkLocal -> CkLocal
        | CkTop -> CkTop
      in
        Coexpr_signal ((s, opt_map translate_te typ),
                       ck, r,
                       opt_map
                         (fun (e1,e2) ->
                           translate_ml e1, translate_ml e2) comb,
                       translate_ml e)

    | Etopck -> Coexpr_topck

    | _ ->
        raise (Internal (e.e_loc,
                         "Reac2lco.translate_ml: expr"))

  in
  make_expr coexpr e.e_loc

(* Translation of Process expressions                                    *)
and translate_proc p =
  let coproc =
    begin match p.e_static with
    | Static.Static ->
        Coproc_compute (translate_ml p)
    | Static.Dynamic _ ->
        begin match p.e_desc with
        | Enothing -> Coproc_nothing

        | Epause (kboi, ck) ->
          let tr_ck = match ck with
            | CkTop -> CkTop
            | CkLocal -> CkLocal
            | CkExpr e -> CkExpr (translate_ml e) in
          Coproc_pause (kboi, tr_ck)

        | Ehalt kboi -> Coproc_halt kboi

        | Eemit (s, None) -> Coproc_emit (translate_ml s)

        | Eemit (s, Some e) ->
            Coproc_emit_val (translate_ml s, translate_ml e)

        | Eloop (n_opt, proc) ->
            Coproc_loop (opt_map translate_ml n_opt, translate_proc proc)

        | Ewhile (expr, proc) ->
            Coproc_while (translate_ml expr, translate_proc proc)

        | Efor (i, e1, e2, flag, proc) ->
            Coproc_for(i,
                       translate_ml e1,
                       translate_ml e2,
                       flag,
                       translate_proc proc)

        | Efordopar (i, e1, e2, flag, proc) ->
            Coproc_fordopar(i,
                            translate_ml e1,
                            translate_ml e2,
                            flag,
                            translate_proc proc)

        | Eseq (p1::p_list) ->
            let rec f acc l =
              match l with
              | [] -> assert false
              | [p] ->
                  Coproc_seq (acc, translate_proc p)
              | p::l' ->
                  let acc' =
                    make_proc
                      (Coproc_seq (acc, translate_proc p))
                      Location.none
                  in
                  f acc' l'
            in f (translate_proc p1) p_list

(*
      | Epar p_list ->
          let p_list' =
            List.map (fun p -> translate_proc p) p_list
          in
          Coproc_par p_list'
*)
        | Epar [p1; p2] ->
            Coproc_par [translate_proc p1; translate_proc p2]
        | Epar p_list ->
            let p_list' =
              List.map
                (fun p ->
                  if p.e_type = Initialization.type_unit then
                    translate_proc p
                  else
                    if p.e_static = Static.Static then
                      make_proc
                        (Coproc_compute
                           (make_expr
                              (Coexpr_seq (translate_ml p, make_unit()))
                              Location.none))
                        Location.none
                    else
                      make_proc
                        (Coproc_seq (translate_proc p, make_nothing()))
                        Location.none)
                p_list
            in
            Coproc_par p_list'

        | Emerge (p1, p2) ->
            Coproc_merge (translate_proc p1,
                          translate_proc p2)

        | Esignal ((s,typ), ck, r, comb, proc) ->
            Coproc_signal ((s, opt_map translate_te typ),
                           clock_map translate_ml ck, clock_map translate_ml r,
                           opt_map
                             (fun (e1,e2) ->
                               translate_ml e1, translate_ml e2) comb,
                           translate_proc proc)

(*
   | Elet (Nonrecursive,[(patt, expr)], proc) ->
   Coproc_def ((translate_pattern patt, translate_ml expr),
   translate_proc proc)
   | Elet (flag, patt_expr_list, proc) ->
   Coproc_def (translate_proc_let flag patt_expr_list,
   translate_proc proc)
 *)
        | Elet (flag, patt_expr_list, proc) ->
            translate_proc_let flag patt_expr_list proc

        | Erun (expr) ->
            Coproc_run (translate_ml expr)

        | Euntil (s, proc, patt_proc_opt) ->
            Coproc_until (translate_conf s,
                          translate_proc proc,
                          opt_map
                            (fun (patt, proc) ->
                              translate_pattern patt, translate_proc proc)
                            patt_proc_opt)

        | Ewhen (s, proc) ->
            Coproc_when (translate_conf s, translate_proc proc)

        | Econtrol (s, patt_proc_opt, proc) ->
            Coproc_control (translate_conf s,
                            opt_map
                              (fun (patt, proc) ->
                                translate_pattern patt, translate_ml proc)
                              patt_proc_opt,
                            translate_proc proc)

        | Eget (s, patt, proc) ->
            Coproc_get (translate_ml s,
                        translate_pattern patt,
                        translate_proc proc)

        | Epresent (s, p1, p2) ->
            Coproc_present (translate_conf s,
                            translate_proc p1,
                            translate_proc p2)

        | Eifthenelse (expr, p1, p2) ->
            Coproc_ifthenelse (translate_ml expr,
                               translate_proc p1,
                               translate_proc p2)

        | Ematch (expr, l) ->
            Coproc_match (translate_ml expr,
                          List.map
                            (fun (p,e) ->
                              (translate_pattern p, translate_proc e))
                            l)

        | Ewhen_match (e1, e2) ->
            Coproc_when_match (translate_ml e1, translate_proc e2)

        | Eawait (flag, s) -> Coproc_await (flag, translate_conf s)

        | Eawait_val (flag1, flag2, s, patt, proc) ->
            Coproc_await_val (flag1,
                              flag2,
                              translate_ml s,
                              translate_pattern patt,
                              translate_proc proc)

        | Enewclock (id, sch, e) ->
            Coproc_newclock (id, Misc.opt_map translate_ml sch, translate_proc e)

        | Epauseclock e1 ->
          Coproc_pauseclock (translate_ml e1)

        | _ ->
            raise (Internal (p.e_loc,
                             "Reac2lco.translate_proc: expr"))
        end
    end
  in
  make_proc coproc p.e_loc

(* Translation of event configurations *)
and translate_conf conf =
  let coconf =
    match conf.conf_desc with
    | Cpresent e -> Coconf_present (translate_ml e)

    | Cand (c1,c2) ->
        Coconf_and (translate_conf c1, translate_conf c2)

    | Cor (c1,c2) ->
        Coconf_or (translate_conf c1, translate_conf c2)

  in
  make_conf coconf conf.conf_loc

(* Translation of let definitions in a PROCESS context *)
and translate_proc_let =
  let rec is_static patt_expr_list =
    match patt_expr_list with
    | [] -> true
    | (_, expr) :: tl ->
        if expr.e_static <> Static.Static then
          false
        else
          is_static tl
  in
  fun rec_flag patt_expr_list proc ->
    if is_static patt_expr_list then
      begin match rec_flag, patt_expr_list with
      | Nonrecursive, [(patt, expr)] ->
          Coproc_def ((translate_pattern patt, translate_ml expr),
                      translate_proc proc)
      | _ ->
          (* x, C y = e1 and z = e2                              *)
          (* is translated in                                    *)
          (* x,y,z = let x, C y = e1 and z = e2 in x,y,z         *)
          let vars =
            List.fold_left
              (fun vars (patt,_) -> (Reac_utils.vars_of_patt patt) @ vars)
              [] patt_expr_list
          in
          let rexpr_and_copatt_of_var x =
            match x with
            | Vlocal id ->
                Reac_utils.make_expr (Elocal id) Location.none,
                make_patt (Copatt_var (Covarpatt_local id)) Location.none
            | Vglobal gl -> assert false
          in
          let rexpr_of_vars, copatt_of_vars =
            List.fold_left
              (fun (el,pl) var ->
                let e, p = rexpr_and_copatt_of_var var in
                e::el, p::pl)
              ([],[])
              vars
          in
          let body =
            translate_ml
              (Reac_utils.make_expr
                 (Elet(rec_flag,
                            patt_expr_list,
                            Reac_utils.make_expr
                              (Etuple rexpr_of_vars)
                              Location.none))
                 Location.none)
          in
          Coproc_def
            ((make_patt (Copatt_tuple copatt_of_vars) Location.none, body),
             translate_proc proc)
      end
    else
      begin match patt_expr_list with
      | [(patt, expr)] ->
          Coproc_def_dyn
            ((translate_pattern patt, translate_proc expr),
             translate_proc proc)
      | _ ->
(*
          Coproc_def_and_dyn
            (List.map
               (fun (patt,expr) ->
                 (translate_pattern patt, translate_proc expr))
               patt_expr_list,
             translate_proc proc)
*)
          (*  let x1 = e1                                  *)
          (*  and x2 = e2                                  *)
          (*  in e                                         *)
          (*                                               *)
          (*  is translated into                           *)
          (*                                               *)
          (*  let v1, v2 = ref None, ref None in           *)
          (*  (let x1 = e1 in v1 := Some x1                *)
          (*   ||                                          *)
          (*   let x2 = e2 in v2 := Some x2);              *)
          (*  let x1, x2 =                                 *)
          (*    match !v1, !v2 with                        *)
          (*    | Some v1, Some v2 -> v1, v2               *)
          (*    | _ -> assert false                        *)
          (*  in e                                         *)
          let ref_global =
            Modules.find_value_desc (Initialization.pervasives_val "ref")
          in
          let set_global =
            Modules.find_value_desc (Initialization.pervasives_val ":=")
          in
          let deref_global =
            Modules.find_value_desc (Initialization.pervasives_val "!")
          in
          let id_array =
            Array.init (List.length patt_expr_list)
              (fun i -> Ident.create Ident.gen_var ("v"^(string_of_int i))
                  Ident.Internal)
          in
          let par =
            Coproc_par
              (List.fold_right2
                 (fun id (_, expr) expr_list ->
                   let local_id =
                     Ident.create Ident.gen_var "x" Ident.Internal
                   in
                   make_proc
                     (Coproc_def_dyn
                        ( (* let x_i = e_i *)
                         (make_patt
                            (Copatt_var (Covarpatt_local local_id))
                            Location.none,
                          translate_proc expr),
                          (* in ref_i := Some x1*)
                         make_proc
                           (Coproc_compute
                              (make_expr
                                 (Coexpr_apply
                                    (make_expr
                                       (Coexpr_global set_global)
                                       Location.none,
                                     [make_expr (Coexpr_local id)
                                        Location.none;
                                      make_expr
                                        (Coexpr_construct
                                           (Initialization.some_constr_desc,
                                            Some
                                              (make_expr
                                                 (Coexpr_local local_id)
                                                 Location.none)))
                                        Location.none;]))
                                 Location.none))
                           Location.none))
                     Location.none
                   :: expr_list)
                 (Array.to_list id_array) patt_expr_list [])
          in
          let let_match =
            Coproc_def
              ((make_patt
                  (Copatt_tuple
                     (List.fold_right
                        (fun (patt, _) patt_list ->
                          (translate_pattern patt) :: patt_list)
                        patt_expr_list []))
                  Location.none,

                make_expr
                  (Coexpr_match
                     ((make_expr
                         (Coexpr_tuple
                            (Array.fold_right
                               (fun id expr_list ->
                                 make_expr
                                   (Coexpr_apply
                                      ((make_expr
                                          (Coexpr_global deref_global)
                                          Location.none,
                                        [make_expr (Coexpr_local id)
                                           Location.none])))
                                   Location.none
                                 :: expr_list)
                               id_array []))
                         Location.none),
                      [(make_patt
                          (Copatt_tuple
                             (Array.fold_right
                                (fun id patt_list ->
                                  make_patt
                                    (Copatt_construct
                                       (Initialization.some_constr_desc,
                                        Some
                                          (make_patt
                                             (Copatt_var (Covarpatt_local id))
                                             Location.none)))
                                    Location.none
                                  :: patt_list)
                                id_array []))
                          Location.none,
                        make_expr
                          (Coexpr_tuple
                             (Array.fold_right
                                (fun id expr_list ->
                                  make_expr (Coexpr_local id) Location.none
                                  :: expr_list)
                                id_array []))
                          Location.none);
                       (make_patt (Copatt_any) Location.none,
                        make_expr (Coexpr_assert
                                     (make_expr (Coexpr_constant
                                                   (Const_bool false))
                                        Location.none))
                          Location.none)]))
                  Location.none),
               translate_proc proc)
          in
          Coproc_def
            ((make_patt
                (Copatt_tuple
                   (Array.fold_right
                      (fun id patt_list ->
                        (make_patt
                           (Copatt_var (Covarpatt_local id))
                           Location.none)
                        :: patt_list)
                      id_array []))
                Location.none,
              make_expr
                (Coexpr_tuple
                   (Array.fold_left
                      (fun expr_list id ->
                        (make_expr
                           (Coexpr_apply
                              (make_expr
                                 (Coexpr_global ref_global)
                                 Location.none,
                               [ make_expr
                                   (Coexpr_construct
                                      (Initialization.none_constr_desc, None))
                                   Location.none ]))
                           Location.none)
                        :: expr_list)
                      [] id_array))
                Location.none),
             make_proc
               (Coproc_seq
                  (make_proc par Location.none,
                   make_proc let_match Location.none))
               Location.none)
      end

let translate_impl_item info_chan item =
  let coitem =
    match item.impl_desc with
    | Iexpr e -> Coimpl_expr (translate_ml e)
    | Ilet (flag, l) ->
        Coimpl_let (flag,
                   List.map
                     (fun (p,e) -> (translate_pattern p, translate_ml e))
                     l)
    | Isignal (l) ->
        Coimpl_signal
          (List.map
             (fun ((s, ty_opt), comb_opt) ->
               (s, opt_map translate_te ty_opt),
               opt_map
                 (fun (e1,e2) ->(translate_ml e1, translate_ml e2))
                 comb_opt)
             l)
    | Itype l ->
        let l =
          List.map
            (fun (name, param, typ) ->
              (name, param, translate_type_decl typ))
            l
        in
        Coimpl_type l
    | Iexn (name, typ) ->
        Coimpl_exn (name, opt_map translate_te typ)
    | Iexn_rebind (name, gl_name) ->
        Coimpl_exn_rebind(name, gl_name)
    | Iopen s ->
        Coimpl_open s
  in
  make_impl coitem item.impl_loc

let translate_intf_item info_chan item =
  let coitem =
    match item.intf_desc with
    | Dval (gl, typ) -> Cointf_val (gl, translate_te typ)

    | Dtype l ->
        let l =
          List.map
            (fun (name, param, typ) ->
              (name, param, translate_type_decl typ))
            l
        in
        Cointf_type l

    | Dexn (name, typ) ->
        Cointf_exn (name, opt_map translate_te typ)

    | Dopen m -> Cointf_open m

  in
  make_intf coitem item.intf_loc

