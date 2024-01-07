open Appconf.Conf

let init = 
  print_endline (Printf.sprintf "\nInflux endpoint: %s" influxdb_url);
  let routes = Http_handler.post "/push" Routes.push_metric in
  print_endline (Printf.sprintf "Listening on port %d..." port);
  Http_handler.new_server port routes 
  
let () = ignore (Lwt_main.run (init))
