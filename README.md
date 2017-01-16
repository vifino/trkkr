# Trkkr

A BitTorrent Tracker in Elixir.

## Why?
Because:
- There are never enough implementations of anything, ever.
- I was bored and programming is fun.
- Made it cause I can. Severe lack of ego inflation was bad for my health.

## Installation

1) Install OTP and Elixir v1.4.

2) Clone the repo.

3) `mix deps.get`

4) Set up Redis.

5) Edit config.

6) `iex -S mix`

# Something broke?
Create a detailed Issue. Or make a PR with a fix.
Thanks.

Even though you don't have to, I'd appreciate if you'd share changes and contribute back.

I test this mainly on Gentoo, so if it is broken on Debian... get a better distro.

# WHERE IS FEATURE `X`???
If you are complaining, probably not there.

I mainly try to stick to [the BitTorrent Specification here](btspec) and some BEPs.

If some feature is missing from [the BitTorrent Specification](btspec) in this tracker, it's either a 
TODO or a bug.

[btspec]: https://wiki.theory.org/BitTorrentSpecification
# License
BSD 3-clause.
