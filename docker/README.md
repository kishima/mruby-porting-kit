The verification image `kishima/mruby:4.1.0-rc2` (linux/amd64, arm64) is built from this Dockerfile with
`docker build --build-arg MRUBY_VER=4.1.0-rc2 -t kishima/mruby:4.1.0-rc2 -f Dockerfile .` (the original uses buildx for both platforms).
It builds mruby 4.1.0-rc2 with the `default` gembox (`rake && rake install`): Word Boxing, 64-bit integers, double floats,
byte strings (no `MRB_UTF8_STRING`), bigint, no task scheduler. Source: github.com/kishima/mruby_containers.
