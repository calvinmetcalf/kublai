#!/bin/bash
mkdir modules
cd modules
git clone git://github.com/alexeyr/erlang-sqlite3.git
cd erlang-sqlite3
make
cd ..
cd ..
erlc kublai.erl
cp DOTerlang .erlang
