# YakUmbrella

## Setup

Initialise hex
`mix hex.local`

Install the phoenix hex archive
`$ mix archive.install https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez`

Setup
`mix deps.get`
`mix compile`

cd into apps/yak
`mix ecto.create`
`mix ecto.migrate`
`mix phoenix.server`
