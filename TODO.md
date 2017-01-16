# TODO

* [ ] Fix this shit.

* [ ] Replace use of `Trkkr.Helpers.pmap` with GenStage/Flow?
  - Would help not spawning hundreds of processes on a request.

* [ ] Replace single redis connection with a worker pool?
  - Using poolboy?

* [ ] Make more stuff use GenServers, supervised and such?
  - Restarting on crash is very, very handy.
  - For Redis, Memory storage, Web API and internal API stuff.
  - The internal "complete" API should be one, for sure.
    - Many things fail and have no error handeling, partly on purpose.
    - This way, many things can go down without complete failure.

* [ ] Make more behaviour configurable.
  - Currently, there are practically no options. Except port.
  - Options to make:
    - Allow tracking unknown torrents.
    - Allow writing statistics to redis.
    - Disable scraping...? I dunno.
    - Disable using the IP provided in the query string of the peer announcing.
    - Different URIs, boy.

* [ ] Port to Phoenix and write a web ui?
  - First part is definitly possible, has quite a few nifty things.
  - Second part? Ehhh, I don't like web dev. Maybe I'll get someone to do the fancy stuff and I'll just plug in values.

* [ ] Performance metrics?
  - Currently I can see the handler processing time in the console, but no error percentage, average, etc...

* [ ] Write tests like a sane programmer??
  - Well, I'm not. Contributions welcome. <3
