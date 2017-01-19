open Core.Std
open Quickcheck

let%test_unit "count vs length" =
  Quickcheck.test
    (* (\* Initial example that fails on NaN: *\)
     * (List.gen Float.gen) *)
    (* Working example that filters out NaN: *)
    (List.gen (Generator.filter Float.gen ~f:(Fn.non Float.is_nan)))
    (* (\* Simplest version: *\)
     * (List.gen Float.gen_without_nan) *)
    ~sexp_of:[%sexp_of: float list]
    ~f:(fun float_list ->
      [%test_result: int]
        (List.count float_list ~f:(fun x -> x = x))
        ~expect:(List.length float_list))

let list_gen elt_gen =
  (* Manually control size via [Generator.size] and [Generator.with_size].  This generator
     skews toward larger elements near the head of the list. *)
  Generator.(recursive (fun self ->
    size >>= function
    | 0 -> return []
    | n ->
      with_size ~size:(n-1)
        (elt_gen  >>= fun head ->
         self     >>= fun tail ->
         return (head :: tail))))

let sexp_gen =
  (* Here we rely on [list_gen] to decrease the size of sub-elements, which also
     guarantees that the recursion will eventually bottom out. *)
  Generator.(recursive (fun self ->
    size >>= function
    | 0 -> String.gen    >>| fun atom -> Sexp.Atom atom
    | _ -> list_gen self >>| fun list -> Sexp.List list))
