# Convos

Convos is a minimum feature comments system for blogs in Ruby.  Convos
accepts new comments from users, presents comments to users and
provides a moderation feature for admins.

# Server setup

## Install

```
curl https://raw.githubusercontent.com/mrrusof/convos/refs/heads/master/install.sh | bash
```

## Configure

Create `config.yml`.

```
production:
  host: 'https://comments.example.com'
  port: 4567
  access_control_allow_origin: '*'
  session_secret: <A cryptographically secure random value at least 64 bytes long>
  session_idle_timeout: 1_800 # 30 minutes
  session_ttl: 86_400 # 1 day
  admin_password: hola
  altcha_challenge_cost: 1_000_000
  altcha_hmac_secret: <A cryptographically secure random value at least 64 bytes long>

  #
  # For sqlite3
  #
  db_adapter: sqlite3
  db_database: production.db

  #
  # For postgresql
  #
  # db_adapter: postgresql
  # db_host: <The postgres host>
  # db_port: 5432
  # db_name: convos_prod
  # db_user: convos
  # db_password: hola
  # db_pool: 1
  # db_timeout: 5000
```

## First time setup

```
CONFIG_FILE=<Path to config.yml> convos db:create
CONFIG_FILE=<Path to config.yml> convos db:load_schema
```

## Run

```
CONFIG_FILE=<Path to config.yml> convos server
```

# Client setup

Add the following to each page that needs a comments section.

```
<script async defer src="<Hostname of your server>/convos.js" type="module"></script>

<convos-comments-section
  thread_id='<A unique identifier string, up to you>' />
```

# Development

```
bundle install
bundle exer rake db:create db:migrate
bundle exec rake test
```

# License

The MIT License (MIT)

Copyright (c) 2026 Ruslán Ledesma Garza

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
