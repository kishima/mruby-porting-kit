# 移植の段階（Porting stages）

本「Deep dive into mruby」の「移植の手順」章の段階表。`data/porting_stages.yml` から生成。
各段階: 到達点、参照（本の章・節と本家ソース）、踏みやすい点（症状 -> 原因）、通るべき本家テスト（`mrbtest/src/*.rb`）。

## 段階 0: 前提を決める

**到達点**: 対象バージョン、対象のビルド設定（整数幅、Boxing、float、文字列のエンコーディング）、コンパイラを含めるかを決め、検証環境（本家のバイナリ）を用意する

**通るべきテスト**: （本家のテストは対象外。自作スクリプトの出力を本家と比べる）

**参照**:
 * overview（本書の検証環境、mrubyとCRubyの違い）
 * references（版の変遷）
 * codegen（コンパイラを含める場合）

**踏みやすい点**:
 * 本家の出力と一致しない → 検証環境の mruby に拡張 gem（array-ext、enum-ext、sprintf など）が入っている。本体の挙動を見るときは gem のメソッドを避ける

## 段階 1: バイトコードを読む

**到達点**: RITE 0400 のヘッダ、IREP セクション（irep レコード、catch ハンドラ表、リテラル 5 種、シンボル、子 irep）、LVAR、END を読み、命令を EXT1〜3 込みでデコードして mrbc --verbose と同じ一覧を出せる

**通るべきテスト**: （本家のテストは対象外。自作スクリプトの出力を本家と比べる）

**参照**:
 * bytecode（バイナリ構造、命令のフェッチ）
 * opcodes（各命令の operand 形式）
 * src/dump.c、src/load.c、src/codedump.c

**踏みやすい点**:
 * ダンプは合うのに実行がずれる → EXT1〜3 は次の 1 命令の operand a／b だけを 16bit にする。第 3 operand は拡張されない
 * catch ハンドラの範囲判定 → begin < pc <= end で、pc は次の命令を指す。後ろのエントリが優先
 * LVAR を読むと壊れる／名前が空になる → LVAR のシンボル数は 4 バイト、各シンボルの長さは 2 バイト、irep ごとの対応は 1 レジスタ 2 バイト（dump.c の write_lv_sym_table）。local_variables と Proc#parameters はこの名前に依存し、.mrb を使うなら mrbc -g（--remove-lv しない）

## 段階 2: 値と分岐

**到達点**: 値の表現（nil、true、false、Integer、Float、Symbol、ヒープのオブジェクト）を決め、LOAD 系、MOVE、算術・比較の高速経路、JMP 系、STOP を実装して、メソッド呼び出しの無いスクリプトを本家と同じ出力で実行できる

**通るべきテスト**: `true`、`false`、`nil`、`bs_literal`、`literals`、`lang`、`iterations`、`unicode`

**参照**:
 * vm（mrb_value、mrb_vtype）
 * opcodes|chap_LOADI
 * opcodes|chap_ADD
 * opcodes|chap_JMP
 * corelib（Integer の 3 つの表現、Float の文字列化）

**踏みやすい点**:
 * 整数の演算結果が本家と違う → 即値の幅（63bit／31bit）と溢れた時の挙動（RInteger か bigint か RangeError か）をビルド設定に合わせる
 * Float の表示が違う → 16 桁の有効数字と指数表記の切り替え（1.0e+20、1.0e-05）は本家の書式に合わせる
 * STOP の戻り値 → トップレベルの最後の式の値は R[nlocals] に置かれている

## 段階 3: メソッド呼び出しと引数

**到達点**: callinfo の積み下ろし、レジスタの重ね方、SEND 系、ENTER（必須・省略可能・rest・後置引数）、RETURN 系、メソッド探索（特異クラス → クラス → ICLASS → スーパークラス）、method_missing、super／ARGARY、ネイティブメソッドの呼び出し規約を実装する

**通るべきテスト**: `methods`、`superclass`、`argumenterror`、`nomethoderror`、`object`、`basicobject`、`kernel`

**参照**:
 * vm（メソッド呼び出し、callinfo、C 関数と Ruby コードの境界）
 * opcodes|chap_SEND
 * opcodes|chap_ENTER
 * opcodes|chap_RETURN
 * opcodes|chap_SUPER
 * src/vm.c の vm_op_enter、L_SENDB、vm_op_argary

**踏みやすい点**:
 * 引数の数が given 16 のように大きく出る → SEND 系の第 3 operand は下位 4bit が位置引数の数、上位 4bit がキーワード引数の数。受け手にキーワード仮引数が無ければ ENTER がハッシュを末尾の位置引数にする
 * 省略可能引数の既定値が評価されない／二重に評価される → ENTER の後の pc の進め方（与えられた数に応じてジャンプ表を飛ばす）
 * raise ArgumentError, "..." が NoMethodError になる → クラスのメタクラスの連鎖（親のメタクラスを super にする）がクラス生成時に作られていない。Exception.exception はメタクラス経由で継承される
 * 引数無しの super が動かない → ARGARY は R[a] に引数の配列、R[a+1] にブロック（キーワードがあれば R[a+1] がハッシュ、R[a+2] がブロック）を置き、続く SUPER は n=15
 * 深い再帰でホストごと落ちる → 呼び出しの深さの上限（MRB_CALL_LEVEL_MAX = 512）で SystemStackError を起こす
 * Foo.new(a: 1) で initialize がキーワードを受け取れない → 本家の Class#new は C 関数ではなく「*、**、& を受けて initialize に n=15|nk=15 で送る」1 個の irep（class.c の new_iseq）。ホスト言語の関数経由（mrb_funcall 相当）ではキーワードは渡らない
 * a.[]=(1, 4) の値が配列になる → SETIDX は代入した値を R[a] に書き戻す（式の値は右辺）
 * x += 1 の x がオブジェクトのとき結果が捨てられる → ADDILV／SUBILV の遅い経路は、作業レジスタ b に呼び出しを組まず、ホスト側の同期呼び出し（mrb_funcall）で結果を a に書く

## 段階 4: ブロックと環境

**到達点**: BLOCK／LAMBDA／METHOD による Proc の生成、環境（REnv）の捕捉と退避、GETUPVAR／SETUPVAR、BLKPUSH、BLKCALL と CALL（Proc#call）、BREAK と RETURN_BLK、LocalJumpError の条件を実装する

**通るべきテスト**: `bs_block`、`proc`、`enumerable`、`comparable`、`range`、`array`、`symbol`

**参照**:
 * vm（環境とクロージャ）
 * opcodes|chap_LAMBDA
 * opcodes|chap_GETUPVAR
 * opcodes|chap_CALL
 * opcodes|chap_RETURN
 * src/vm.c の OP_CALL、OP_BLKCALL、OP_BREAK、vm_call_proc、src/proc.c の call_irep

**踏みやすい点**:
 * Enumerable#collect などで「配列ではない」というエラー → ARYCAT は R[a] が nil のとき新しい配列を作る（引数の蓄積の起点）
 * ブロックの break の戻り先が見つからない → Proc#call は CALL でフレームを差し替え、yield は BLKCALL でフレームを 1 つ積む。break の戻り先は「1 つ下のフレームの Proc がブロックを作った Proc か」で探すので、ブロック呼び出しをホスト言語からの再入で実装するとこの探索が成立しない
 * each を回すと二乗の時間がかかる → mrblib の Array#each は length と [] で書かれている。Array#[] と length は定数時間にする
 * ブロック引数の |a, b| に配列を 1 つ渡すと展開されない → ENTER は非厳密（ブロック）で引数が 1 つの配列なら展開する。lambda（厳密）はしない
 * メソッドに渡したブロックを Proc として取り出し、メソッドが戻った後に break すると LocalJumpError にならない → フレームを外すとき（cipop）、そのフレームに渡されていたブロックが呼び出し元の環境を持つ非厳密 Proc なら MRB_PROC_ORPHAN を立てる。Proc.new と Proc#dup も孤立させる
 * proc {} を 2 回作ると == が false になる → Proc#== は同じ irep と同じ環境なら真（オブジェクトの同一性ではない）
 * lambda の中のブロックで return すると lambda ではなく外のメソッドやトップレベルから返る（トップレベルなら黙って終了） → RETURN_BLK の戻り先は top_proc の規則で決める。upper を辿り、scope でも strict でもない proc の捕捉環境を env に残して、scope か strict に当たったら止まる。その env を自分の環境として持つフレームが戻り先（フレームの環境 = そのフレームで作られたブロックの捕捉環境）。戻り先の環境が別の Fiber のものなら LocalJumpError

## 段階 5: 例外と大域脱出

**到達点**: catch ハンドラ表による rescue／ensure、EXCEPT／RESCUE／RAISEIF、例外の伝播（フレームを外しながら、ホスト関数の境界で受け渡す）、return／break／JMPUW が ensure を通る仕組み（break オブジェクト）、例外クラスの階層とメッセージの扱いを実装する

**通るべきテスト**: `exception`、`ensure`、`standarderror`、`runtimeerror`、`typeerror`、`rangeerror`、`indexerror`、`localjumperror`、`nameerror`

**参照**:
 * vm（例外処理、ensure と大域脱出）
 * opcodes|chap_EXCEPT
 * opcodes|chap_JMP
 * opcodes|chap_RETURN
 * corelib（例外）
 * src/vm.c の L_RAISE、L_RETURN、UNWIND_ENSURE、OP_JMPUW、OP_RAISEIF、src/error.c、src/backtrace.c

**補足**: setjmp／longjmp は実装都合。ホスト言語に longjmp 相当が無ければ、例外を戻り値で運び、実行ループがフレームの列を歩いて catch ハンドラ表を引く。ホスト関数がブロックを呼び戻すときは入れ子の実行ループを起こし、捕捉されなかった例外は戻り値として外側のループへ返す（vm「大域脱出の二つの流儀」）

**踏みやすい点**:
 * return や break で ensure が走らない → RETURN／BREAK／JMPUW は現在の pc を覆う ensure ハンドラを先に探し、あれば「戻り先と値」を持つ break オブジェクトを例外の場所に置いてハンドラへ飛ぶ。ensure 本体の末尾の RAISEIF がそれを見て脱出を続ける
 * 未実装の機能に当たると 1 ファイル全部が止まる → 未実装は NotImplementedError の例外として起こす。本家のテストは 1 つの assert ごとに rescue する
 * エラーメッセージの比較で落ちる → NoMethodError の受け手はクラス名、TypeError の %Y は nil／true／false だけ値、引数無し raise は空メッセージの RuntimeError、メッセージは設定時に String 化
 * 未捕捉例外の表示に行番号が出ない → DBG セクションが要る。無ければ (unknown):0 になる
 * 例外の name／args が nil → VM が起こす NoMethodError は @name（メソッド名）と @args（引数の配列）を、NameError は @name を持つ。mrblib の attr_reader がそれを読む

## 段階 6: クラス、モジュール、定数、変数

**到達点**: CLASS／MODULE／EXEC、DEF／TDEF／SDEF、ALIAS／UNDEF、SCLASS／TCLASS、include（ICLASS）、GETCONST／SETCONST／GETMCNST の探索順、クラス変数、グローバル変数、attr_*、Class#new（allocate + initialize）、可視性を実装する

**通るべきテスト**: `class`、`module`、`syntax`、`codegen`、`integer`、`float`、`numeric`、`string`、`hash`

**参照**:
 * vm（オブジェクト、クラス、定数、シンボル）
 * opcodes|chap_CLASS
 * opcodes|chap_TDEF
 * opcodes|chap_GETCV
 * opcodes|chap_GETCONST
 * corelib（組込みクラスの全体像、三層の分担）
 * src/class.c、src/variable.c

**踏みやすい点**:
 * def self.m の中の @@x が nil になる → クラス変数の起点は「実行中の proc のターゲットクラス」ではなく、upper をたどって最初に見つかる特異クラスでないクラス
 * 定数が見つからない／CRuby と違う定数が見える → 探索はターゲットクラスの継承鎖、次にレキシカルスコープ（upper の proc のターゲットクラス）、最後に Object。順序は mruby 固有
 * include したモジュールのメソッドが見えない → ICLASS（モジュールの表を共有するクラス）をクラスと親の間に挿し込む。同じモジュールを二度挿さない
 * when *list が NoMethodError になる → __case_eqq にコンパイルされる（Kernel の内部メソッド）
 * クラスに @@x = 2 と書き、その後 include したモジュールに @@x = 1 があると 1 になる → mrb_mod_cv_get は継承鎖を最後まで歩き、最後に見つかった表の値を返す（include したモジュールが勝つ）。書き込みは最初に見つかった表
 * private の後の def が公開のままになる → 既定の可視性はフレームではなく「スコープ」に属し、そのフレームが環境（REnv）を作った後は環境が持つ（class.c の find_visibility_scope）。class_eval／instance_eval のフレームは境界（VISIBILITY_BREAK）
 * prepend したモジュールのメソッドが呼ばれない → prepend はクラス自身のメソッド表を origin という ICLASS に移し、モジュールの ICLASS をクラスと origin の間に挿す。メソッド探索でクラス本体の表は飛ばす。super の行き先もこの鎖で決まる
 * prepend を持つモジュールを include すると、そのモジュールの prepend が効かない → ICLASS が共有するのはモジュールの origin の表。include／prepend はモジュールの鎖（prepend と include したもの）ごと挿す
 * 同じモジュールを親と子で prepend すると子で消える → prepend の重複判定は自クラスの区間（最初の実クラスまで）だけ。include の重複判定は鎖全体（class.c の include_module_at の search_super）
 * nil／true／false に特異メソッドを定義できない → それらの特異クラスは NilClass／TrueClass／FalseClass そのもの

## 段階 7: mrblib と組込みクラスを動かす

**到達点**: 本家の mrblib/*.rb を本家の mrbc でコンパイルしたバイトコードをそのまま読み込み、それが前提にする C の内部メソッド（__svalue、__sub_replace、byteindex など）と mrb_init_core の範囲のネイティブメソッドを実装して、本家のテストスイートを走らせる

**通るべきテスト**: `array`、`hash`、`string`、`integer`、`float`、`range`、`enumerable`、`comparable`、`kernel`、`symbol`、`gem_array`、`gem_enum`、`gem_hash`、`gem_range`、`gem_string`、`gem_numeric`

**参照**:
 * corelib（三層の分担、mrblib が呼ぶ内部メソッドの表、各クラスの節）
 * extension（gem の初期化順序）
 * src/*.c 末尾の ROM メソッド表（MRB_MT_ENTRY）

**踏みやすい点**:
 * mrblib の読み込み中に NoMethodError → module_function、attr_accessor、include、alias、to_enum が先に要る
 * String#sub／gsub が動かない → mrblib 側が byteindex、byteslice、__sub_replace を呼ぶ
 * テストスイートが起動しない → ドライバが足す t_print、_str_match?（グロブ照合）、Mrbtest::FLOAT_TOLERANCE、Mrbtest.nofree_cstr?、__ENCODING__ が要る
 * 再帰的な配列の inspect でホストごと落ちる → inspect 中のオブジェクトを記録して [...]／{...} を出す。ネイティブ同士の再帰にも深さの上限を置く
 * ハッシュのキーに eql? だけで一致させると本家と結果がずれる → 検索は「hash が等しい、かつ検索キー.eql?(格納キー)」。String のキーは複製して凍結する（凍結済みならそのまま）。rehash も同じ規則
 * Integer と Float の比較が丸めで一致してしまう → 本家は mrb_int_float_cmp で正確に比べる（2**53+1 == 2**53.0 は偽）。NaN との比較は <=> が nil、< などは false（例外ではない）。比較できない型のときだけ ArgumentError
 * Float の表示 → 有効数字 15 桁を超えると指数表記（1.0e+15）。1e-4 未満も指数表記
 * Array#rindex が変更途中の配列で本家と違う → == やブロックの中で配列が縮んでも落ちないよう、毎回長さを読み直す
 * Hash#[] が再定義した default を呼ばない → キーが無いとき Hash#[] は default メソッドを呼ぶ（#3272）
 * gem を入れても gem の Ruby 定義（mrblib）が効かない → 本家が gem の mrblib（Ruby）で定義しているメソッドをホスト側にネイティブで置いている（例: Range#count、Hash#count、Array#zip、Kernel#to_enum）。クラス直下のネイティブは Enumerable 経由の Ruby 定義より先に見つかる。ネイティブを書く前に「本家はそれを C で定義しているか」を確かめる
 * gem 同士で同じメソッドを定義していて結果が違う → gem の mrblib は default.gembox の初期化順に読む。後に読んだ方が勝つ（Enumerable#zip は enum-ext より enumerator）
 * == が常に偽のオブジェクトを count(obj) で数えられない → EQ 命令は == を送る前に同一オブジェクトなら真（mrb_obj_eq）。即値だけでなくヒープのオブジェクトも
 * max_by／min_by で NoMethodError (<=> for NilClass) → Kernel#<=>（同一か == なら 0、他は nil）が要る
 * 本家の test/t/range.rb の Range#last が落ちる → range-ext を入れた本家自身も落ちる（gem の Ruby 版 last が endless range で RangeError）。本体だけの VM と gem 入りの VM で本家テストの期待が食い違う例
 * 巨大な添字でホストごと落ちる（insert(2**62, x)、slice!(1, INT_MAX)） → 加算はすべて checked、確保は上限付き（本家は mrb_int_add_overflow と ARY_MAX_SIZE で ArgumentError "array size too big"）
 * Array#- や uniq が本家と違う → これらは == ではなく eql? と hash の集合（khash）。1 == 1.0 を同一視してはいけない
 * "1-z".succ が "2-a" になる → 右端の英数字が進み、英数字でない文字をまたいで桁上がりするが、英字から数字、数字から英字へはまたがない（str_succ_bang）。"1.9" は "2.0"、"1-z" は "1-aa"
 * delete／squeeze／count の範囲パターンが 1 文字足りない → 本家の tr_compile_pattern は範囲の終端を含まない（i < ch[1]）。tr は含む。本家どおりに移植する
 * Kernel.instance_method(:inspect) が無い、gem が Kernel に置いた定義が効かない → 本家は inspect、to_s、methods、instance_variable_get などを Object ではなく Kernel に定義する（kernel.c の mrb_init_kernel）。ホスト側の定義も同じクラスに置く。Object に置くと Kernel の定義を隠す
 * proc { break }.call が LocalJumpError にならない → 本家は C 関数のフレームを外すとき（cipop）に渡されたブロックを孤立させる。ネイティブにフレームを積まない設計では、ネイティブから戻った直後に同じ印を付ける
 * ホスト側からの呼び出し（funcall 相当）で method_missing が呼ばれない → SEND 命令と同じく、利用者定義の method_missing があればそれを呼ぶ。public_send や Method#call がこれに依存する
 * ネイティブの Method#arity が答えられない → 本家はネイティブにも MRB_ARGS_* の引数仕様を持つ。ホスト側の定義に仕様を持たせるか、表で補う（差異として記録）
 * eval の文字列から呼び出し元のローカル変数が見えない（Can't find local variables） → 本家のコンパイラは呼び出し元の Proc の連鎖から irep の lv（変数名の表）を読み、パーサとコード生成の両方に使う（MRC_TARGET_MRUBY）。VM から独立したコンパイラなら、各スコープの変数名を lv と同じ並びで渡す入口を足す。できた Proc には呼び出し元フレームの環境（REnv）を付け、upper を呼び出し元にする（codegen|cg_eval）
 * class_eval／instance_eval に文字列を渡した後、呼び出し元の def が受け手のクラスに入る → 4.1.0-rc の mruby-eval の問題（Proc と共有した環境のターゲットクラスを書き換える）。master で修正済み。本家 rc の挙動に合わせない
 * Comparable#clamp が Range 1 個の引数で ArgumentError → ホスト側のネイティブ clamp が gem（compar-ext、純 Ruby）の定義を隠している。gem のテストは Ruby 版の形（clamp(range)）を要求する
 * Range に特異メソッドを定義すると FrozenError → 本家の Range は凍結されていない（初期化済みの印 RANGE_INITIALIZED は別のフラグ）。凍結オブジェクトの特異クラスは凍結される（class.c の sc->frozen = o->frozen）ので、Range を凍結扱いにすると define_method が通らない
 * alias したメソッドの中で __method__ や super が新しい名前を見る → 本家は alias に別の Proc（MRB_PROC_ALIAS、body.mid が元の名前）を作り、呼び出しフレームの mid は元の名前になる。__method__、__callee__、super はそれを見る（kernel-ext のテスト）
 * 1.instance_exec { class B; end } が TypeError（特異クラスが作れない） → Integer／Float／Symbol に特異クラスは無い（mrb_singleton_class_ptr が NULL）。ターゲットクラスを上書きせずにブロックを実行し、中の class はブロックの字句上のクラスに入る
 * caller の並びが本家と違う → 本家の backtrace はデバッグ情報の無い Ruby フレームを飛ばし、C 関数のフレームは直下の Ruby フレームの位置（file:line）で載る。先頭は caller 自身のフレーム。-g 無しでコンパイルすると caller(0) は []、caller は nil
 * catch／throw を例外で実装すると rescue Exception に捕まる → 本家の throw は RBreak（ensure だけを走らせる非局所脱出）を catch のフレームに向けて投げる。ブロック内の return と同じ機構で実装し、catch はタグとフレームの深さを積んでおく
 * 同じ名前の gem テストファイルが片方消える → string-ext と numeric-ext の numeric.rb、range-ext と string-ext の range.rb。テストの複製先に gem 名を付ける
 * Struct の中に自分自身を入れて inspect すると "[...]" になる → Struct のインスタンスは本家では配列の形（MRB_TT_STRUCT は RArray と同じ）。ホスト側の inspect が「配列の形なら [...]」と格納形で判断していると、Struct#inspect の "#<struct ...>" に届かない。再帰の印はクラスで決める
 * Struct のアクセサを 1 メンバー 1 関数で作れない → 本家はメンバーの番号を環境に持つ C の Proc（mrb_proc_new_cfunc_with_env）。ネイティブに環境が無い設計なら、呼ばれた名前（mid）をディスパッチ時に記録してアクセサがそれを引く
 * Set のテストで「eql? の途中で Set を変更すると RuntimeError」が通らない → 本家の khash が再ハッシュ中の変更を検出して投げる（GHSA-4jw6-mq65-g3c8）。Hash の上に作った Set には守る状態が無い。差異として記録する
 * Time.local と Time.utc の差が出ない／Time.now が 1970 年 → no_std の VM にはタイムゾーンも時計も無い。local は UTC のまま "+0000" で表示し、現在時刻はホストの差し込み口（wall_clock）から受け取る。Time のテストはこの形でも全件通る（ローカルの offset は 900 の倍数であることしか見ない）
 * 多倍長整数のリテラルで「pool の型が不正」になる → pool 型 7（IREP_TT_BIGINT）は「長さバイト、基数バイト、数字列」で、本家 load.c の pool_data_len = len + 2 は長さバイト自身を数える。長さバイトの後に読むのは len + 1 バイト。基数が負なら負の数（mrb_bint_new_str）
 * 桁あふれを RangeError にすると bigint 入りの本家と食い違う → +、-、*、**、<<、MIN / -1、-@ は多倍長に昇格する。VM の高速経路（あふれ検査付きの演算）はそのままにし、あふれた出口だけ多倍長へ回す
 * 多倍長を足すと ==／eql?／hash／Hash のキーが壊れる → 「機械語整数に収まる値は必ず即値に戻す」（本家 bint_norm）を不変条件にする。同じ数が二つの形を持たなくなる。ハッシュ値は桁の列と符号から計算する
 * 添字やシフト幅や指数に多倍長が来たときの例外 → TypeError ではなく RangeError "integer out of range"（mrb_bint_as_int）。Float から Integer への変換も多倍長へ（1e30.to_i は 31 桁の整数）
 * 本家 mruby-bigint 自身の取りこぼしを写してしまう → ~x が -(x-1) になる（負号を付けてから絶対値を 1 減らす）、負数の >> が 0 方向に丸まる、div(Float) が割り算ではなく掛け算、% Float が fmod（切り捨て）、dup が 0。いずれも即値の Integer と意味が食い違う。即値と同じ意味にそろえ、差異として記録する
 * ObjectSpace.count_objects に多倍長の型が出ない → 型の一覧に T_BIGINT を足す（本家の型 enum では T_BREAK より後）。本家は生きているオブジェクトがある型だけを載せる
 * Class#new で allocate を再定義したクラスの答えが変わる → 本家の Class#new はバイトコード（src/class.c の new_iseq）で、allocate を send してから initialize を送る。ホスト側で「確保して initialize を呼ぶ」ネイティブにすると再定義が効かない
 * pack／unpack は指示子の表と read_tmpl を写す作業 → 判断が要るのは本家の癖だけ（i／I と j／J は C の int／intptr_t の大きさで別名、修飾子は sSiIlLqQ の後だけ、# は行末までのコメント、p／P／% は拒否、Q の読み出しは多倍長があっても RangeError）。テストだけでは穴が残るので、指示子ごとに本家と突き合わせる
 * eval を入れるのにコンパイラと VM を結合しなくてよい → 必要なのは (1) 外側のローカル変数名の表をコンパイラに渡す入口、(2) VM が「文字列をコンパイルして」と頼むホストの差し込み口。本家がコンパイラに渡している Proc 連鎖の代わりに名前の表を渡せば、パーサ（ローカル変数かどうか）とコード生成（GETUPVAR の番号と段数）の両方が決まる
 * eval の文字列から呼び出し元の変数が読めても書けない → 文字列の Proc に呼び出し元フレームの環境をそのまま付ける（upper は呼び出し元の Proc）。深さ 0 の GETUPVAR／SETUPVAR が呼び出し元のレジスタになる。文字列の中のブロックからは 1 段外（本家 search_upvar の lv - 1）
 * binding で作った変数が呼び出し元のフレームを壊す → 本家は binding を作るとき「ローカル変数を持たない Proc と自分だけの環境」を 1 段かぶせる（lvspace）。新しい名前はその空間の名前表と環境を一緒に伸ばす。dup は共有された空間の上にもう 1 段かぶせる
 * 文字列を「文字の並び」にすると分岐が全メソッドに散る → 本家も
 * UTF-8 ビルドで位置がずれる → 位置は文字（length、[]、index、chars、reverse、chop、succ、center）、byte* はバイト（bytesize、byteslice、byteindex、getbyte）。sprintf の幅と精度も両ビルドでバイト
 * 壊れたバイト列の扱い → mrb_utf8len は overlong・サロゲート・U+10FFFF 超を拒否し、拒否されたバイトは 1 文字として数える（"\xED\xA0\x80".length は 3）。文字を求める場所（ord、codepoints、大文字小文字変換）は ArgumentError、scrub は Unicode 3.9 の maximal subpart ごとに U+FFFD
 * 文字を綴らないバイト列を針にした検索 → どこにも見つからない（index、rindex、byteindex、[]、include?、end_with?、partition、chomp、slice!）。バイト検索のオフセットが文字の途中なら IndexError。String#b の針はバイト列として探す
 * 本家の delete_prefix／delete_suffix／strip／lstrip／rstrip が多バイト文字で変な位置を切る → バイトで測った位置を文字で数える mrb_str_substr に渡している本家の取りこぼし。ASCII と多バイトで意味を変えない側に合わせ、差異として記録する
 * mrblib の sub／gsub が多バイト文字を壊す → mrblib の Ruby 実装が文字とバイトを混ぜている。本家イメージでは regexp gem が C 版で置き換えるので表に出ない。regexp が無い移植先では mrblib の後にネイティブを登録して同じ形にする
 * String#succ が多バイト文字で止まる／飛ぶ → 英字と数字の「連なり」の表が要る（本家 str_alnum.h、1635 区間）。大文字小文字は処理系の文字テーブルで足りるが、succ だけは表を写す
 * String#b の伝播 → b から作った文字列は同じ読み方を継ぐ（切り出し、複製、大文字小文字、詰め物、分割、置換）。追記は「バイトとして読まれた ASCII 超のバイトが入ったら入った先もバイト読み」。+ だけは両辺から新しい文字列の読み方を決める別規則
 * ビルド構成が 2 通りになったときの検証 → 参照イメージも回帰の床（baseline）も構成ごとに持つ。テストのバイトコードは共通でよく、どの assertion を走らせるかは実行時に __ENCODING__ が決める
 * 正規表現エンジンを丸ごと移植しようとして手が止まる → エンジンは実装都合で、処理系の持つ有限オートマトンに置き換えてよい。表面（Regexp、MatchData、String のメソッド、$~）は本家から移植する。ただし後方参照・先読み・後読み・アトミックグループ・絶対最大量指定子・部分式呼び出し・条件・不在演算子は有限オートマトンに無く、言語仕様の差になる。コンパイル時に構文名を入れた RegexpError で断り、本家テストの該当件数を意図した差異として数える
 * 翻訳層で書き直すもの → ASCII の略記（\d、\w、\s、\h。Ruby は ASCII、汎用ライブラリの既定は Unicode なので /i で ASCII の外へ広がらないよう囲う）、8 進と \xNN（連続するものはまとめて復号する。2 バイトが綴る 1 文字に量指定子が付く）、\u、(?'name'…)、コメント群 (?#…)、{,m}、繰り返しを開かない {、そして Ruby の m（ドットが改行に一致する旗。^ と $ は旗に関係なく常に行アンカー）
 * /x の空白をライブラリ任せにすると [ ] が壊れる → 汎用ライブラリの free-spacing はクラスの中の空白まで落とす。翻訳層で空白と
 * 名前付きグループがあると md[1] の番号がずれる → 名前付きが 1 つでもあると平の (...) は捕獲しない（Onigmo の DONT_CAPTURE_GROUP）。パターン全体を先に走査して決め、平の ( を非捕獲に書き換える。走査はクラスの中・エスケープの後・コメント群・/x のコメントを飛ばす（[(?<a>] は名前付きを開かない）
 * 名前を汎用ライブラリにそのまま渡すと拒まれる → Ruby は同じ名前を 2 つのグループに付けられ、ライブラリが拒む名前も付けられる。名前と番号の対応は自分で持ち、ライブラリには番号だけの捕獲グループとして渡す
 * \1 が後方参照か 8 進かで揺れる → N が 9 以下か、パターンが開くグループ数以下なら後方参照、そうでなければ 8 進（\101 は A）。8 と 9 で始まるものはその数字そのもの。名前付きがあるパターンでも平のグループは数に入る（降格はパースの後）
 * パターンの中の「文字を綴らないバイト」が文字として扱われる → その範囲だけ Unicode を切った区間として書く（クラスなら丸ごと）。バイトとして読むパターンとバイト列ビルドは全体が Unicode 無しになり、そこでは \u{…} はその符号位置の UTF-8 の綴りになる
 * $~ をグローバル変数の表に置くと呼び出し元に漏れる → 4.1.0-rc の $~ はメソッドのスコープが持つ特別変数。ブロックは定義元と共有し、C のフレームは素通しで下の Ruby フレームに書き、Fiber は自分のものを持つ。$1 や $& はコンパイラが $~ の読み方に落とす。スコープの環境（REnv）に容れ物を置き、容れ物は最初の非 nil 書き込みまで作らない（読みは作らない）
 * 埋め込みホストが実行中に文字列を読み込んだときの $~ → その最上位フレームは自分のスコープを持たず、下のスコープに素通しする。フレームが戻った後も透明さは続くので、逃げた環境に「下のスコープへの転送」を残す。Fiber は逆に、自分の根のブロックが定義されたスコープに解決が着いたら自分の根へ向け直す
 * 正規表現 gem の String#sub／gsub が効かない → gem は core の mrblib の後に初期化される。退避してから置き換えるネイティブを mrblib より先に登録すると mrblib の Ruby 定義が勝つ
 * コンパイルが例外になった Regexp と initialize_copy で super を呼ばなかった複製が区別できない → 「初期化済み」の印はインスタンス変数ではなくデータポインタ（本家はコンパイル前に空の器を入れる）。前者は source や inspect に答えつつマッチを断り、後者はインスタンス変数を継いでいても何にも答えない
 * unicode_* と ascii_* のテストが両方落ちる → この 2 対は同じパターンについて反対のことを主張し、gem の spec.build_settings が構成に応じて片方を外している。移植先でも走らせる一覧から外す（バイトコードは両方作ってよい）
 * 正規表現を足したら core の codegen のテストが落ちた → test/t/codegen.rb は /static/ が NoMethodError になることを確かめるが、それは Regexp クラスが無いビルドでしか成り立たない。正規表現 gem はどの gembox にも入っていないので本家の mrbtest は結びつけない。gem を全部載せる移植先では落ちる。理由を記録して先へ進む
 * step 数やバックトラック段数の上限のテストが落ちる → 有限オートマトンは対象の長さに比例するので上限が要らない。定数はテストが読むので置き、何も投げない。意図した差異
 * require を入れたいが File も POSIX も無い → 探索は Ruby、ファイル読みはホストの差し込み口にする。パスは Ruby で文字列として組み立て（expand_path は省く）、「そこにファイルはあるか」「中身をくれ」の 2 つだけをネイティブにする。eval がコンパイルを頼むのと同じ差し込み口に足せばよく、ホストが居なければ require も居ない、という関係が自然に出る（本家 mruby に require は無い。PicoRuby の picoruby-require が土台）
 * require 'fiber' が組み込み gem を読みに行く → gem を全部リンクする移植先では、gem の名前を最初から $LOADED_FEATURES に並べておく。PicoRuby の extern(name) の代わり
 * A が B を、B が A を require すると止まらない → $LOADED_FEATURES への登録は実行の前（CRuby と同じ。PicoRuby は後に入れるので循環が止まらない）。例外が出たら取り消して、次の require がやり直せるようにする
 * require "./x.rb" が見つからない → 拡張子を持つ名前は付け足さずにそのまま探す（CRuby と同じ規則）。裸の名前だけ .mrb、.rb の順に試す
 * rescue の中の裸の raise が「メッセージの無い RuntimeError」になる → $! を持たない VM では裸の raise は何も持たない。rescue => e で名前を付けて raise e と書く

## 段階 8: Fiber、タスク、GC

**到達点**: Fiber ごとのコンテキスト（レジスタ領域と callinfo）と状態遷移、resume／yield／transfer、ホスト関数の境界の扱い、命令境界での中断（タスク）、到達可能性 GC を実装する

**通るべきテスト**: `gc`、`gem_fiber`、`gem_fiber2`、`gem_enumerator`

**参照**:
 * vm（Fiber、タスクスケジューラ）
 * gc
 * extension（拡張から見た GC の約束）

**踏みやすい点**:
 * 入れ子の実行ループで中断すると内側の戻り値が失われる → ホスト関数の境界をまたいでいる間は切り替えを保留する（task_across_c_boundary）
 * Fiber を C 関数の境界をまたいで切り替える → mruby は FiberError にする。許すならホスト側のスタックの扱いを決める
 * Enumerator（外部イテレータ）が全部 FiberError になる → send／__send__ をホスト側の関数にしている。本家の send はフレームを差し替えて同じ実行ループで呼ぶ（kernel.c の mrb_f_send → mrb_exec_irep）。Enumerator#each は __send__ 経由でブロックが Fiber.yield する
 * Fiber を切り替えた瞬間に実行ループが誤って終わる／終わらない → ループの停止条件を「どのコンテキストの、どの深さか」の組で持つ。別コンテキストのフレームは Fiber の先頭フレームが返るまで止めない
 * ホスト関数から resume した Fiber が yield すると戻ってこない → 入れ子の実行ループ（本家 vmexec）を使い、yield でそのループを抜けて値を返す（本家は resumer の ci に CINFO_RESUMED）
 * resume／yield の戻り値が消える → 一時停止中の呼び出しの戻り先レジスタをコンテキストごとに覚える。本家は C 関数の callinfo を積んだまま残し、再開時に stack[0] へ書いて外す
 * root.transfer が常に FiberError になる → 境界判定から各コンテキストの先頭フレームを除外する（task_across_c_boundary と同じ）。ルートの先頭フレームはホストから起動した印が付いている
 * to_enum が gem を入れても NotImplementedError のまま → ホスト側の仮実装が Kernel の Ruby 定義を隠している。mrblib に定義があるものをホスト側で二重に置かない。Array#zip も本体には無く enumerator gem の Enumerable#zip
 * Enumerator#dup が TypeError にならない → dup／clone は initialize_copy(orig) を呼ぶ（本家 init_copy）。Kernel と Range の initialize_copy（private）も要る
 * ObjectSpace.count_objects が GC.start の後も減らない → レジスタ領域全体をルートにすると、戻ったフレームの残骸が指すオブジェクトが生き続ける。本家の mark_context_stack は先頭フレームの nregs（引数の方が多ければその分）までを走査し、その上を nil で埋める。埋めないと、フレームが戻って呼び出し元の範囲に入った残骸が解放済みを指し、次の GC で壊れる（stress で再現）
 * mrb_gc_register を 2 回した対象が 1 回の unregister で消える → 登録は回数を数える（objectspace の C テスト __gc_root_survivors）。スイープで末尾を切り詰めた slot は「解放済み」と答える
 * タスクスケジューラを一から作ろうとして手が止まる → タスクは Fiber と同じ「文脈」。本家の mrb_task は struct mrb_context を丸ごと抱え、スケジューラは mrb->c を差し替えて VM を呼ぶ。Fiber がある移植先なら、CPU を渡すのは resume、sleep／pass／join／キュー待ちは yield で、新しく作るのは優先度キューと状態遷移だけ
 * tick の出どころが無い → 本家はタイマー割り込み（POSIX なら SIGALRM + setitimer）で MRB_TICK_UNIT ごとに mrb_tick を呼ぶ。タイマーもスレッドも無い移植先では命令数で数える。timeslice は「時間」ではなく「仕事量」になり、テストが決定的になるという副産物もある。時計を持つホストには自分で tick を進める口を出す
 * 起きるタスクが無いときスケジューラが空回りする → 本家は CPU を眠らせてタイマーを待つ。仮想時計なら最も早い期限までカウンタを進める。何も起こせない待ち（全部が suspended、互いを join）は本家では永久に眠るので、移植先ではそこでスケジューラを返す方が使える（差異として記録）
 * 横取り（timeslice 切れ）で rescue されるはずの例外が消える → 切り替えを保留する条件が 3 つある。(1) root コンテキストでは切り替えない（受け止めるスケジューラのフレームが無い）、(2) 例外が飛んでいる間は切り替えない（catch ハンドラが例外を取る前に抜けると、rescue されるはずの例外がタスクの結果に化ける）、(3) ネイティブのフレームをまたいでいる間は切り替えない。本家の RETURN_IF_TASK_STOPPED がこの 3 つ
 * ホストが 1 歩ずつ回す形にしたら、プログラム中の Task.run で壊れる → 走っているタスクは READY キューの先頭に居るので、その中から Task.run を呼ぶと「自分の文脈」を再開しようとする。本家のループは loop_running フラグで入れ子を止めているが、ホストが 1 歩ずつ回す形（本家 mrb_task_run_once）ではそのフラグが立たない。呼び出し元がタスクなら Task.run は何もしない、とする。こうすると Task.run で終わるプログラムが、ホスト駆動でもそのまま動く
 * 全タスクが眠ったまま二度と起きない → 命令数でティックを数える方式では、眠っている VM は命令を実行しないのでティックを作れず、時計が止まる。スケジューラのループ先頭と、待ちに入る直前・出た直後にも時計を進める口を置く（本家がアイドルで「いちばん早い起床時刻までカウンタを飛ばす」のはこの穴を塞ぐため）
 * sleep が毎回ループ 1 周分だけ長い → ホストのループが「走らせる→時計を進める」の順になっている。起床に気づくのが常に 1 周遅れ、すべての sleep に上乗せされる（100ms x 10 が 1500ms になる）。「時計を進める→走らせる」に直す。待っただけの周回でも先頭で進める
 * 時計が少しずつ遅れる → 前回からの経過を足していくと端数の切り捨てが積もる。起動時刻という原点から due =（いまの時刻 - 起動時刻）/ ティック長 で逆算し、due - 供給済み を供給する。まとめて供給してよいかは起床判定の作り次第（時刻を比較する実装なら可、残りティックを数える実装は 1 つずつ）
 * Task.pass や sleep の戻り値がレシーバになる → 止まる呼び出しの中でその場で文脈を切り替えてはいけない。本家のネイティブはフラグを立てて普通に値を返し、呼び出し側の命令が戻り値をレジスタに書いてから、次の命令の切れ目で文脈が入れ替わる。ネイティブの中で切り替えると書き込み先が別の文脈になり、止まった側のレジスタにはレシーバが残る（Task.pass が nil ではなく Task を返す）。join の戻り値が「呼んだ時点の結果」になる（本当に待ったときは nil）のもこの順番の帰結
 * タスクの中の例外がスケジューラを止める → 捕まえられなかった例外はタスクの結果にする（本家 exception_as_result）。Task#value がその例外オブジェクトを答える
 * タスクを閉じた後、そのタスクの中で作ったブロックが壊れた値を読む → フレームが指しているスタックを消す前に、逃げた環境へ値を写す（本家 mrb_env_detach_all）。到達不能になった文脈を GC が掃除するときと同じ操作で、close／terminate／文脈の作り直しの 3 か所で要る
 * キュー待ちをビジーループにしない → 「取れた／閉じている／空（非ブロック）／時間切れ／待ちに入った」を返し分け、待ちに入ったときだけ番兵を返す。Ruby 側の pop はその番兵の間だけ回る。番兵を返す前にタスクは WAITING になっていて、次に走るのは push か close の後
 * Task.run が全部終わるまで戻らない → 毎フレーム少し進めたいホストには「1 つ動かして戻る」口が要る（本家 mrb_task_run_once。Ruby 側の名前は本家にも無い）
 * GC をスケジューラに渡す → アイドルで回収すれば確保のたびに止まらない（GC.scheduler_driven）。世代別 GC とは両立しない（マイナーサイクルが 1 ステップで終わってしまう）ので、本家は同時に立てると例外にする

