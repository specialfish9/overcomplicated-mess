open Cohttp
open Cohttp_lwt_unix
open Lwt

type http_method = string

let http_get: http_method= "GET"
let http_post: http_method= "POST"

type route_cb = Request.t -> Cohttp_lwt.Body.t -> (Code.status_code * string) t

type route = {
  path: string;
  meth: http_method;
  callback: route_cb 
}

let get ?(routes=[]) path callback = 
  let route = {path=path; meth=http_get; callback=callback} in
  routes @ [route]

let post ?(routes=[]) path callback = 
  let route = {path=path; meth=http_post; callback=callback} in
  routes @ [route]

let log_resp meth path code =
  let status = Code.string_of_status code in
  print_endline (Printf.sprintf "[%s] %s - %s" status meth path)

let find_route path meth routes = 
  List.find_opt (fun route -> route.meth = meth && route.path = path) routes

let fail_404 = Lwt.return (`Not_found, "404 not found")

let handle_exc e =
  let msg = Printexc.to_string e in
  Lwt.return (`Internal_server_error, msg)

let handle routes _conn req bod =
  let path = req |> Request.uri |> Uri.path in
  let meth = req |> Request.meth |> Code.string_of_method in
  (match find_route path meth routes with
  | None ->  fail_404
  | Some route -> try route.callback req bod with e -> handle_exc e)
  >>= fun (status, body) -> 
      log_resp meth path status;
      Server.respond_string ~status: status ~body: body ()

let new_server port routes = 
  let callback = handle routes in
  Server.create ~mode:(`TCP (`Port port)) (Server.make ~callback: callback ())
