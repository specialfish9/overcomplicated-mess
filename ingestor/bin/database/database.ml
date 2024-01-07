open Lwt
open Cohttp
open Cohttp_lwt_unix
open Appconf

exception JsonParsingException of string

type metric = {
  timestamp: int64;
  temperature: float;
  humidity: float;
  sensor: string;
}

let find_field_opt name = List.find_opt (fun (key, _) -> key = name)

let json_int fields key =
  match find_field_opt key fields with 
  | Some(_, `Int value) -> Some value
  | _ -> None

let json_float fields key =
  match find_field_opt key fields with 
  | Some(_, `Float value) -> Some value
  | _ -> None

let json_string fields key =
  match find_field_opt key fields with 
  | Some(_, `String value) -> Some value
  | _ -> None

let json_bool fields key =
  match find_field_opt key fields with 
  | Some(_, `Bool value) -> Some value
  | _ -> None

let must_parse fields key func = match func fields key with 
  | Some(value) -> value
  | None -> raise (JsonParsingException (Printf.sprintf "Field %s is missing or has the wrong type" key))

let metric_of_fields (fields: (string * Yojson.Safe.t) list) =
  let sens = must_parse fields "sensor" json_string in
  let temp = must_parse fields "temperature" json_float  in
  let hum = must_parse fields "humidity" json_float  in
  let ts = must_parse fields "timestamp" json_int in
  let ts = Int64.of_int ts in
  Some ({
    timestamp=ts;
    temperature=temp;
    humidity=hum;
    sensor=sens;
  })

let string_of_metric metric = 
  Printf.sprintf "airSensorsOcaml,sensord_id=%s temperature=%f,humidity=%f timestamp=%Ld" 
    metric.sensor 
    metric.temperature 
    metric.humidity 
    metric.timestamp

let push_metric metric =
  let uri = Uri.of_string Conf.influxdb_url in
  let body = Cohttp_lwt.Body.of_string (string_of_metric metric) in
  let headers = Header.init_with "Authorization" (Printf.sprintf "Token %s" Conf.token) in
  let headers = Header.add headers "Content-Type" "text/plain" in
  Client.post ~headers ~body:body uri >>= fun (response, resp_body) ->
  let status = response |> Response.status in
  let success = Code.is_success (Code.code_of_status status) in
  if not success then
    Cohttp_lwt.Body.to_string resp_body >>= fun s -> Lwt.return (Some s)
  else
    Lwt.return None
