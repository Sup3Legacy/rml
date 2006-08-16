(*************************************************************************)
(*                              Reactive ML                              *)
(*                                                                       *)
(*  Fichier : caml2caml.ml                                               *)
(*  Date de creation : 09/08/2006                                        *)
(*  Auteur : Louis Mandel                                                *)
(*************************************************************************)

(* $Id$ *)

(* Source to source transformations *)

open Misc
open Caml_ast
open Caml_misc



module Env = Symbol_table.Make (Ident)

(* Constant propagation *)
let constant_propagation =
  let rec constant_propagation env expr =
    let expr' =
      begin match expr.cexpr_desc with
      | Cexpr_local id ->
	  begin try 
	    Env.find id env
	  with Not_found ->
	    expr.cexpr_desc
	  end

      | Cexpr_global gl -> expr.cexpr_desc

      | Cexpr_constant c -> expr.cexpr_desc

      | Cexpr_let (rec_flag, patt_expr_list, expression) ->
	  let patt_expr_list' =
	    List.rev_map
	      (fun (patt,expr) -> (patt, constant_propagation env expr))
	      patt_expr_list
	  in
	  let env', patt_expr_list'' =
	    List.fold_left
	      (fun (env, pe_list) (patt, expr) ->
		begin match patt.cpatt_desc with
		| Cpatt_var (Cvarpatt_local id) ->
		    if is_constant expr then
		      let env' = Env.add id expr.cexpr_desc env in
		      (env', pe_list)
		    else
		      (env, (patt, expr) :: pe_list)
		| _ -> (env, (patt, expr) :: pe_list)
		end)
	      (env, [])
	      patt_expr_list'
	  in
	  begin match patt_expr_list'' with
	  | [] -> (constant_propagation env' expression).cexpr_desc
	  | _ ->
	      Cexpr_let(rec_flag, 
			patt_expr_list'', 
			constant_propagation env' expression)
	  end

      | Cexpr_function patt_expr_list ->
	  let patt_expr_list' =
	    List.map 
	      (fun (patt,expr) -> (patt, constant_propagation env expr))
	      patt_expr_list
	  in
	  Cexpr_function patt_expr_list'

      | Cexpr_fun (patt_list, expr) ->
	  Cexpr_fun (patt_list, constant_propagation env expr)

      | Cexpr_apply (expr, expr_list) ->
	  Cexpr_apply
	    (constant_propagation env expr,
	     List.map (fun expr -> constant_propagation env expr) expr_list)

      | Cexpr_tuple expr_list ->
	  Cexpr_tuple
	    (List.map (fun expr -> constant_propagation env expr) expr_list)

      | Cexpr_construct (const, expr_option) ->
	  Cexpr_construct
	    (const,
	     opt_map (constant_propagation env) expr_option)

      | Cexpr_array expr_list ->
	  Cexpr_array 
	    (List.map (fun expr -> constant_propagation env expr) expr_list)

      | Cexpr_record lbl_expr_list ->
	  Cexpr_record
	    (List.map 
	       (fun (lbl,expr) -> (lbl, constant_propagation env expr))
	       lbl_expr_list)

      | Cexpr_record_access (expr, lbl) ->
	  Cexpr_record_access (constant_propagation env expr, lbl)

      | Cexpr_record_update (e1, lbl, e2) ->
	  Cexpr_record_update
	    (constant_propagation env e1, 
	     lbl,
	     constant_propagation env e2)

      | Cexpr_constraint (expr, ty) ->
	  Cexpr_constraint (constant_propagation env expr, ty)

      | Cexpr_trywith (expr, patt_expr_list) ->
	  Cexpr_trywith
	    (constant_propagation env expr,
	     List.map 
	       (fun (patt, expr) -> (patt, constant_propagation env expr))
	       patt_expr_list)

      | Cexpr_assert expr ->
	  Cexpr_assert (constant_propagation env expr)

      | Cexpr_ifthenelse (e1, e2, e3) ->
	  Cexpr_ifthenelse
	    (constant_propagation env e1,
	     constant_propagation env e2,
	     constant_propagation env e3)

      | Cexpr_match  (expr, patt_expr_list) ->
	  Cexpr_match
	    (constant_propagation env expr,
	     List.map 
	       (fun (patt, expr) -> (patt, constant_propagation env expr))
	       patt_expr_list)

      | Cexpr_when_match (e1,e2) ->
	  Cexpr_when_match
	    (constant_propagation env e1,
	     constant_propagation env e2)

      | Cexpr_while (e1,e2) ->
	  Cexpr_while
	    (constant_propagation env e1,
	     constant_propagation env e2)

      | Cexpr_for (id, e1, e2, dir, e3) ->
	  Cexpr_for
	    (id,
	     constant_propagation env e1,
	     constant_propagation env e2,
	     dir,
	     constant_propagation env e3)

      | Cexpr_seq (e1,e2) ->
	  Cexpr_seq
	    (constant_propagation env e1,
	     constant_propagation env e2)
      end
    in
    make_expr expr' expr.cexpr_loc
  in constant_propagation Env.empty


let constant_propagation_impl impl =
  let loc = impl.cimpl_loc in
  match impl.cimpl_desc with
  | Cimpl_expr e -> make_impl (Cimpl_expr (constant_propagation e)) loc

  | Cimpl_let (rec_flag, patt_expr_list) ->
      let patt_expr_list' =
	List.map (fun (p,e) -> (p, constant_propagation e)) patt_expr_list
      in
      make_impl (Cimpl_let (rec_flag, patt_expr_list')) loc

  | _ -> impl
