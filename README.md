# yak

Web chat application using Elixir and Phoenix with rudimentary comand processing.

This is an Elixir Umbrella application, containing two seperate applications. `Yak` the chat Phoenix application and `Graze` the command processor.

# Setup

Required:
* Elixir 1.4
* Erlang/OTP 20
* Postgresql
* Node

Install dependencies using `mix deps.get` in the root of the umbrella, and to run the server run `mix phx.server` in `yak_umbrella/apps/yak`.
