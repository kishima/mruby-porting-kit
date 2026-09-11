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

