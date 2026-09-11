# Running mruby's test suite on a port

mruby's tests (`test/t/*.rb`) are plain Ruby driven by `test/assert.rb`. The only things the C
side of the reference driver (`mrbgems/mruby-test/driver.c`) adds are:

| name | definition |
|---|---|
| `Kernel#t_print(*args)` | `mrb_obj_as_string` each argument and write it to stdout, no newline |
| `Kernel#_str_match?(pattern, str)` | glob match used by `assert_match`: `*`, `?`, `[...]` (with `!`/`^` negation and ranges), `{a,b}` alternatives (nested, depth <= 100), backslash escapes. Port of `str_match_p` in `driver.c` |
| `Mrbtest::FLOAT_TOLERANCE` | `1e-10` for double, `1e-4` / `1e-5` for `MRB_USE_FLOAT32` |
| `Mrbtest.nofree_cstr?` | may return `true` |

Also needed by `assert.rb` itself: `RUBY_ENGINE == "mruby"`, `Object.const_defined?`, `__send__`,
`__id__`, singleton `alias` on an Array instance (`class << $mrbtest_assert_idx; alias to_s _assertion_join; end`),
`Kernel#__ENCODING__` (string.rb).

Procedure (what `sabiruby mrbtest` and `reference_runner.rb` in this directory do):

1. fresh VM with the core library (`mrblib`) loaded
2. define the helpers above
3. run `assert.mrb`
4. run `t/<file>.mrb`
5. call `report` on the top-level object and parse `OK:` / `KO:` / `Crash:` / `Warning:` / `Skip:`

One VM per file: the globals `$ok_test` etc. must start at zero. Unimplemented features should raise
`NotImplementedError` rather than abort, so that `assert` counts them as `Crash` and the file continues.

`reference-results.md` holds the numbers of the reference `mruby` itself (4.1.0-rc, `default` gembox,
so tests that need mrbgems pass there and may not on a core-only port). It was produced with
`reference_runner.rb`, a pure-Ruby version of the helpers, by concatenating it with `assert.rb` and the test file.
