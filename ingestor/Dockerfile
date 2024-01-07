FROM ocaml/opam:debian-ocaml-4.14

WORKDIR /app

COPY . .

RUN sudo apt -y install libgmp-dev
RUN opam install -y dune
RUN eval $(opam env)
RUN opam install -y cohttp-lwt-unix 
RUN eval $(opam env)
RUN opam install -y cohttp-async 
RUN eval $(opam env)
RUN opam install -y yojson
RUN eval $(opam env)

RUN opam exec dune build

ENV PORT 8000
EXPOSE 8000

CMD ["./_build/default/bin/main.exe"]

