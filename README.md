change of plan, kublai is written in erlang now

at the moment it can only write a  tile to disk, that will change very soon. 

at the moment the only requirement is erlang, and [sqlite3](http://github.com/alexeyr/erlang-sqlite3) installed.

also point your erlang path to erlang sqlite3, by making a file in your home directory called .erlang and putting in it

	code:add_patha("/home/planner/erlang-sqlite3/ebin").
	
or you can get all the dependencies (not including erlang also only on linux as I don't know how to write a .bat) by running 

	./start.sh

also you may nead to make it exicutable first

	sudo chmod a+x start.sh

if you don't have sqlite installed you'll need to run

	sudo apt-get install sqlite3

