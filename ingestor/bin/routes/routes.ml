open Lwt

let parse_json_body body =
  try
    let json = Yojson.Safe.from_string body in
    match json with
    | `Assoc fields -> Some fields
    | _ -> None
  with
  | Yojson.Json_error _ -> None


let push_metric _ body =
  Cohttp_lwt.Body.to_string body >>= fun body_str ->
  match parse_json_body body_str with
    | Some fields -> (
        match Database.metric_of_fields fields with
        | Some m -> Database.push_metric m >>= fun error -> (
          match error with
          | Some(cause) -> Lwt.return (`Internal_server_error, cause) 
          | None -> Lwt.return (`Created, "")
        )
        | None -> Lwt.return (`Bad_request, "error constructing metric")
      )
    | None -> Lwt.return (`Bad_request, "error parsing json")



