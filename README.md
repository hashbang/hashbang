# #! - Core Infrastructure #

<http://github.com/hashbang/hashbang>


## About ##

This repository contains the design documents and documentation for
[Hashbang's](https://hashbang.sh) overall infrastructure.

Likewise, its associated [issue tracker](https://github.com/hashbang/hashbang/issues)
is used for keeping track of infra-wide issues, bugs, improvements, ...


## Services ##

Currently we provide the following services:

  * SSH - `ssh://hashbang.sh:22`
    - [Source Code](https://github.com/hashbang/shell-server)
    - [Docker Image](https://hub.docker.com/r/hashbang/shell-server/)
  * IRC - `ircs://irc.hashbang.sh:6697`
    - Server
      - [Source Code](https://github.com/hashbang/hashbang)
      - [Docker Image](https://hub.docker.com/r/hashbang/unrealircd/)
    - Services
      - [Source Code](https://github.com/hashbang/docker-anope)
      - [Docker Image](https://hub.docker.com/r/hashbang/anope/)

  * Bitlbee - `ircs://im.hashbang.sh:6697`
    - [Source Code](https://github.com/hashbang/hashbang)
    - [Docker Image](https://hub.docker.com/r/hashbang/unrealircd/)

  * SMTP - `smtp://mail.hashbang.sh`
    - [Source Code](https://github.com/hashbang/docker-postfix)
    - [Docker Image](https://hub.docker.com/r/hashbang/postfix/)

  * VOIP - `mumble://voip.hashbang.sh:64738`
    - [Source Code](https://github.com/hashbang/docker-mumble)
    - [Docker Image](https://hub.docker.com/r/hashbang/mumble/)

  * LDAP - `ldaps://ldap.hashbang.sh`
    - [Source Code](https://github.com/hashbang/docker-slapd)
    - [Docker Image](https://hub.docker.com/r/hashbang/slapd/)


## Documentation ##

  - [Abuse Prevention](https://github.com/hashbang/hashbang/tree/master/abuse)
  - [Next-Gen UserDB](https://github.com/hashbang/hashbang/tree/master/userdb)


## Notes ##

  Use at your own risk. You may be eaten by a grue.

  Questions/Comments?

  Talk to us via:

  [Email](mailto://team@hashbang.sh) |
  [IRC](ircs://irc.hashbang.sh:6697/#!) |
  [Github](http://github.com/hashbang/)
