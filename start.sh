#!/bin/bash
mkdir modules
cd modules
git clone git://github.com/alexeyr/erlang-sqlite3.git
cd erlang-sqlite3
make
cd ..
git clone https://github.com/basho/rebar.git
cd rebar
./bootstrap
cd ..
git clone git://github.com/ostinelli/misultin.git
cp rebar/rebar misultin/rebar
cd misultin
./rebar compile
cd ..
git clone git://github.com/benoitc/couchbeam.git
cd couchbeam
make
cd ..
cd ..
erlc kublai.erl
erlc ks.erl
cp DOTerlang .erlang
