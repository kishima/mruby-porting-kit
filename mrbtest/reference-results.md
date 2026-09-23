# Reference results (mruby 4.1.0-rc2, default gembox)

Produced by `reference_runner.rb` + `assert.rb` + each file on the reference `mruby` (see DRIVER.md).
Gems are present in the reference binary, so some assertions pass here that need more than the core.
Failures here are the reference's own under this setup: tests that read `__FILE__`/`__LINE__` (the files are concatenated into one script),
and tests that need the C fixtures of mruby-test (`env.c`, `vformat.c`, `sysfail.c`).
`gem_*` files are the tests of mruby-fiber, mruby-enumerator, mruby-array-ext, mruby-enum-ext, mruby-hash-ext, mruby-range-ext, mruby-string-ext, mruby-sprintf, mruby-metaprog, mruby-proc-ext, mruby-method; `gem_fiber2` needs the C helpers of `mruby-fiber/test/fibertest.c`
(`resume_by_c_func`, `yield_by_c_func`, `Proc.c_tunnel`, ...), which the `mruby` command does not have, so it fails here.

| file | total | ok | ko | crash | warn | skip |
|---|---:|---:|---:|---:|---:|---:|
| argumenterror | 9 | 9 | 0 | 0 | 0 | 0 |
| array | 63 | 62 | 0 | 1 | 0 | 0 |
| basicobject | 2 | 2 | 0 | 0 | 0 | 0 |
| bs_block | 46 | 46 | 0 | 0 | 0 | 0 |
| bs_literal | 9 | 9 | 0 | 0 | 0 | 0 |
| class | 48 | 48 | 0 | 0 | 0 | 0 |
| codegen | 15 | 14 | 1 | 0 | 0 | 0 |
| comparable | 7 | 7 | 0 | 0 | 0 | 0 |
| ensure | 5 | 5 | 0 | 0 | 0 | 0 |
| enumerable | 22 | 22 | 0 | 0 | 0 | 0 |
| env | 8 | 0 | 0 | 8 | 0 | 0 |
| exception | 35 | 35 | 0 | 0 | 0 | 0 |
| false | 6 | 6 | 0 | 0 | 0 | 0 |
| float | 29 | 29 | 0 | 0 | 0 | 0 |
| gc | 24 | 24 | 0 | 0 | 0 | 0 |
| gem_array | 83 | 82 | 0 | 1 | 0 | 0 |
| gem_enum | 39 | 39 | 0 | 0 | 0 | 0 |
| gem_enumerator | 52 | 52 | 0 | 0 | 0 | 0 |
| gem_fiber | 21 | 21 | 0 | 0 | 0 | 0 |
| gem_fiber2 | 4 | 0 | 0 | 4 | 0 | 0 |
| gem_hash | 27 | 27 | 0 | 0 | 0 | 0 |
| gem_metaprog | 33 | 32 | 0 | 1 | 0 | 0 |
| gem_method | 32 | 32 | 0 | 0 | 0 | 0 |
| gem_numeric | 1 | 1 | 0 | 0 | 0 | 0 |
| gem_proc | 12 | 10 | 0 | 2 | 0 | 0 |
| gem_range | 4 | 4 | 0 | 0 | 0 | 0 |
| gem_sprintf | 13 | 10 | 0 | 0 | 0 | 3 |
| gem_string | 73 | 64 | 0 | 0 | 0 | 9 |
| hash | 45 | 45 | 0 | 0 | 0 | 0 |
| indexerror | 1 | 1 | 0 | 0 | 0 | 0 |
| integer | 41 | 41 | 0 | 0 | 0 | 0 |
| iterations | 4 | 4 | 0 | 0 | 0 | 0 |
| kernel | 37 | 32 | 1 | 4 | 0 | 0 |
| lang | 2 | 2 | 0 | 0 | 0 | 0 |
| literals | 12 | 11 | 0 | 0 | 0 | 1 |
| localjumperror | 1 | 1 | 0 | 0 | 0 | 0 |
| methods | 7 | 7 | 0 | 0 | 0 | 0 |
| module | 53 | 53 | 0 | 0 | 0 | 0 |
| nameerror | 3 | 3 | 0 | 0 | 0 | 0 |
| nil | 9 | 9 | 0 | 0 | 0 | 0 |
| nomethoderror | 2 | 2 | 0 | 0 | 0 | 0 |
| numeric | 58 | 58 | 0 | 0 | 0 | 0 |
| object | 2 | 2 | 0 | 0 | 0 | 0 |
| platform | 2 | 2 | 0 | 0 | 0 | 0 |
| proc | 15 | 15 | 0 | 0 | 0 | 0 |
| range | 22 | 21 | 0 | 1 | 0 | 0 |
| rangeerror | 1 | 1 | 0 | 0 | 0 | 0 |
| regexperror | 0 | 0 | 0 | 0 | 0 | 0 |
| runtimeerror | 1 | 1 | 0 | 0 | 0 | 0 |
| standarderror | 1 | 1 | 0 | 0 | 0 | 0 |
| string | 66 | 66 | 0 | 0 | 0 | 0 |
| superclass | 28 | 28 | 0 | 0 | 0 | 0 |
| symbol | 9 | 9 | 0 | 0 | 0 | 0 |
| syntax | 71 | 68 | 3 | 0 | 0 | 0 |
| sysfail | 1 | 0 | 0 | 1 | 0 | 0 |
| true | 6 | 6 | 0 | 0 | 0 | 0 |
| typeerror | 1 | 1 | 0 | 0 | 0 | 0 |
| unicode | 3 | 3 | 0 | 0 | 0 | 0 |
| version | 1 | 1 | 0 | 0 | 0 | 0 |
| vformat | 1 | 0 | 0 | 1 | 0 | 0 |
| **all** | 1228 | 1186 | 5 | 24 | 0 | 13 |
