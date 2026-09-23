# Fixtures

Each `NAME.rb` was compiled by the reference `mrbc` (4.1.0-rc2) into `NAME.mrb`, listed with `mrbc --verbose` into `NAME.dump`,
and run by the reference `mruby` into `NAME.out` (stdout + stderr). A port that runs `NAME.mrb` should produce `NAME.out` byte for byte.
`kwargs.rb` needs keyword parameters. The scripts use only core methods (no mrbgems) except where a comment says otherwise.
