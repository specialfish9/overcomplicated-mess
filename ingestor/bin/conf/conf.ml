open Sys

exception EnvNotFound of string

let read_env name = 
  match getenv_opt name with
  | Some(v) -> v
  | None -> raise (EnvNotFound name)

let port = int_of_string (read_env "PORT")

let influxdb_url = read_env "INFLUX_URL"

let token = read_env "INFLUX_TOKEN"

