# mruby opcode dataset

「mruby バイトコードハンドブック」（改訂版、mruby 4.1.0 対応）の第3章から機械的に抽出した、
mruby 4.1.0 の opcode 1 個 = 1 レコードの JSONL データセットです。
ライセンスは MIT（`LICENSE`）。本文（PDF / Markdown）とはライセンスが異なります。

生成: `ruby tools/build_dataset.rb`（`sub-article/*.re`、`data/code/*.rb`、`docs/reports/*.md`、
`docs/notes/opcode-history.json`、`../ref/mruby/include/mruby/ops.h` から）。

## レコードの項目

| 項目 | 内容 |
|---|---|
| `opcode` | 命令名（例 `MOVE`） |
| `mruby_version` | 対象バージョン（`4.1.0`。`4.1.0-rc` タグで検証） |
| `operand_format` | `BB` などの operand フォーマット（`Z`=なし） |
| `operands` | operand の名前とビット幅の配列 |
| `definition` | 本文の「定義」（`R[a] = R[b]` の形。upstream の `ops.h` の表記） |
| `ops_h_comment` | `include/mruby/ops.h` の該当行のコメント（原文） |
| `summary` | 本文の「動作」（日本語） |
| `history` | 記事のコメント行 `#@# 履歴:`（本文には出ない。例 `1.0.0 から存在`、`4.0.0 で LOADT から改名`） |
| `since` / `since_tag` | 最初に現れた安定版 / 最初に現れたタグ（`opcode-history.json`） |
| `removed_at` | 消えたタグ（4.1.0-rc に存在する命令は `null`） |
| `present_in_4_1_0` | 4.1.0-rc の `ops.h` にあるか |
| `article` / `report` | 元になった記事と執筆レポートのパス |
| `source_refs` | レポートが「読んだ箇所」として記録した `src/vm.c:行` などの参照先 |
| `samples` | 記事が引用するサンプルコード（`data/code/`）の内容 |
| `dumps` | そのサンプルを実際に `mrbc --verbose` にかけた出力（`irep=N` はダンプ中の irep 番号） |
| `vm_impl` | 記事の補足に引用された `src/vm.c` の実装抜粋 |
| `usage_text` / `supplement_text` | 記事の「用法」「補足」の本文（Re:VIEW 記法を除いた平文。コードブロックは除く） |

## 注意

 * ダンプの `irep 0x...` のアドレスは実行ごとに変わる値で、意味はありません
 * `summary` などの日本語は本文の一部です。データセットとして MIT で提供しますが、本文全体の再配布ではありません
 * 複数の命令を 1 記事で扱っている場合、`samples`/`dumps`/`vm_impl` は記事単位の内容がその記事の全命令に付きます
