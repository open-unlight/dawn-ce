#!/bin/sh
./authserver stop
./lobbyserver stop
./dataserver stop
./questserver stop
./matchserver stop
./chatserver stop
./gameserver stop
./watchserver stop
./raidserver stop
./raidchatserver stop
./raiddataserver stop
./raidrankserver stop
./globalchatserver stop

./authserver start
./lobbyserver start
./dataserver start
./questserver start
./matchserver start
./chatserver start
./gameserver start
./watchserver start
./raidserver start
./raidchatserver start
./raiddataserver start
./raidrankserver start
./globalchatserver start
