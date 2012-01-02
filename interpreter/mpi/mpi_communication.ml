
module type TAG_TYPE = sig
  type 'gid t
  val print : (Format.formatter -> 'gid -> unit) -> Format.formatter -> 'gid t -> unit
end

module type S = sig
  type lid
  type gid

  type msg
  type 'gid tag
  type site

  val print_gid : Format.formatter -> gid -> unit
  val print_site : Format.formatter -> site -> unit

  module GidMap : (Map.S with type key = gid)
  module GidSet : (Set.S with type elt = gid)

  module SiteMap : (Map.S with type key = site)
  module SiteSet : (Set.S with type elt = site)

  val is_master : unit -> bool
  val available_site : unit -> site

  val fresh : unit -> gid
  val is_local : gid -> bool

  val to_msg : 'a -> msg
  val from_msg : msg -> 'a

  val send : site -> gid tag -> 'a -> unit
  val send_owner : gid -> gid tag -> 'a -> unit
  val receive : unit -> gid tag * msg
end


module Make (P : TAG_TYPE) = struct
  type msg = string
  type msg_handler = msg -> unit

  type lid = int (* local unique id *)
  type gid =
      { g_rank : Mpi.rank; g_id : lid } (* global unique id *)
  type 'gid tag = 'gid P.t

  module Gid = struct
    type t = gid
    let compare = compare
  end
  module GidMap = Map.Make (Gid)
  module GidSet = Set.Make (Gid)

  type site = Mpi.rank

  module Site = struct
    type t = site
    let compare = compare
  end
  module SiteMap = Map.Make (Site)
  module SiteSet = Set.Make (Site)


  let print_here ff () =
    Format.fprintf ff "%d" (Mpi.comm_rank Mpi.comm_world)

  let print_gid ff gid =
    Format.fprintf ff "%d.%d" gid.g_rank gid.g_id

  let print_site ff (site:site) =
    Format.fprintf ff "%d" site

  let print_tag = P.print print_gid

  let is_master () =
    Mpi.comm_rank Mpi.comm_world = 0

  let available_site () =
    let me = Mpi.comm_rank Mpi.comm_world in
      ((me + 1) mod (Mpi.comm_size Mpi.comm_world)  : Mpi.rank)

  let counter = ref 0
  let fresh () =
    incr counter;
    { g_rank = Mpi.comm_rank Mpi.comm_world;
      g_id = !counter }

  let is_local gid =
    gid.g_rank = Mpi.comm_rank Mpi.comm_world

  let to_msg d =
    Marshal.to_string d [Marshal.Closures]

  let from_msg s =
    Marshal.from_string s 0

  let send_owner gid tag d =
    Format.eprintf "%a: Send '%a' to gid '%a' at site '%a'@."
      print_here ()  print_tag tag  print_gid gid  print_site gid.g_rank;
    Mpi.send (tag, to_msg d) gid.g_rank 0 Mpi.comm_world
  let send site tag d =
    Format.eprintf "%a: Send '%a' to site '%a'@."
      print_here ()  print_tag tag  print_site site;
    Mpi.send (tag, to_msg d) site 0 Mpi.comm_world

  let receive () =
    let tag, (msg:msg) = Mpi.receive Mpi.any_source Mpi.any_tag Mpi.comm_world in
      Format.eprintf "%a: Received '%a'@."
        print_here ()  print_tag tag;
      tag, msg
end
