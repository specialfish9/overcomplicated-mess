open Appconf.Conf

let init = 
  let routes = Http_handler.post "/push" Routes.push_metric in
  print_endline (Printf.sprintf "\nListening on port %d..." port);
  Http_handler.new_server port routes 
  
let () = ignore (Lwt_main.run (init))
