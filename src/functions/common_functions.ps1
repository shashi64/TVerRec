###################################################################################
#
#		共通関数スクリプト
#
###################################################################################
<#
	.SYNOPSIS
	TVerRecの共通機能を提供する関数群を定義します。

	.DESCRIPTION
	TVerRecアプリケーションで使用される共通の機能を提供する関数群を定義します。
	主に以下の7つのカテゴリの機能を提供します：

	1. メモリ管理関連
		- ガベージコレクションの制御
		- メモリ使用の最適化

	2. 時間処理関連
		- タイムスタンプの生成と変換
		- UNIX時間とDateTime型の相互変換

	3. 文字列処理関連
		- ファイル名の無効文字除去
		- 全角/半角文字の変換
		- 特殊文字の処理

	4. ファイル操作関連
		- ファイルの削除と管理
		- ZIPファイルの展開
		- ファイルロックの制御

	5. ディスク管理関連
		- ディスク容量の監視
		- 空き容量の確認

	6. 通知機能関連
		- トースト通知の表示
		- 進捗状況の表示と更新

	7. データ変換関連
		- Base64エンコードデータの変換
		- 画像データの処理

	.NOTES
	前提条件:
	- Windows、Linux、またはmacOS環境で実行する必要があります
	- PowerShell 7.0以上を推奨します
	- 十分なディスク容量が必要です
	- インターネット接続が必要な場合があります

	主要な機能：
	- システムリソースの効率的な管理
	- ファイルシステムの安全な操作
	- マルチプラットフォーム対応の通知機能
	- データ形式の変換と処理
	- 文字列とエンコーディングの処理

	.EXAMPLE
		# 関数の読み込み
		. .\common_functions.ps1

		# ガベージコレクションの実行
		Invoke-GarbageCollection

		# タイムスタンプの取得
		$timestamp = Get-TimeStamp

		# ファイル名の無効文字を除去
		$safeName = Remove-InvalidFileNameChars "無効な文字を含むファイル名"

	.LINK
	https://github.com/dongaba/TVerRec
#>

Set-StrictMode -Version Latest
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)

#region ガーベッジコレクション
#----------------------------------------------------------------------
# ガーベッジコレクション
#----------------------------------------------------------------------
function Invoke-GarbageCollection() {
	<#
		.SYNOPSIS
			強制的にガベージコレクション (GC) を実行し、不要なメモリを解放します。

		.DESCRIPTION
			この関数は、.NET のガベージコレクタ ([System.GC]) を手動で実行し、
			メモリ管理を最適化するために 2 回の GC サイクルを実施します。
			1 回目の GC 実行後、保留中のファイナライザを処理し、
			再度 GC を実行することで、不要なメモリを最大限解放します。

		.INPUTS
			なし

		.OUTPUTS
			なし

		.EXAMPLE
			PS> Invoke-GarbageCollection
			強制的にガベージコレクションを実行し、不要なメモリを解放します。

		.LINK
			https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/

		.NOTES
			- この関数は通常の PowerShell スクリプト実行時には不要です。
			- 高メモリ使用状態が続くアプリケーションなど、明示的に GC を実行する必要がある場合に使用してください。
			- [System.GC]::Collect() は、.NET のメモリ管理によって自動的に実行されるため、過度に使用しないよう注意してください。
	#>
	[CmdletBinding()]
	[OutputType([Void])]
	Param ()
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	Write-Verbose -Message 'Starting garbage collection ...' ; [System.GC]::Collect()
	Write-Verbose -Message 'Waiting for pending finalizers ...' ; [System.GC]::WaitForPendingFinalizers()
	Write-Verbose -Message 'Performing a final pass of garbage collection ...' ; [System.GC]::Collect()
	Write-Verbose -Message 'Garbage collection completed.'
}
#endregion ガーベッジコレクション

#region タイムスタンプ
#----------------------------------------------------------------------
# タイムスタンプ更新
#----------------------------------------------------------------------
function Get-TimeStamp {
	<#
		.SYNOPSIS
			現在のタイムスタンプを "yyyy-MM-dd HH:mm:ss" の形式で取得します。

		.DESCRIPTION
			この関数は現在の日時を取得し、"yyyy-MM-dd HH:mm:ss" 形式の文字列として返します。
			ログ記録やファイル名のタイムスタンプなどに利用できます。

		.INPUTS
			なし

		.OUTPUTS
			System.String
			- 現在の日時を "yyyy-MM-dd HH:mm:ss" の形式で表した文字列。

		.EXAMPLE
			PS> Get-TimeStamp
			2025-04-02 15:30:45

			現在のタイムスタンプを取得し、"yyyy-MM-dd HH:mm:ss" の形式で表示します。

		.LINK
			https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-date

		.NOTES
			- PowerShell の `Get-Date` を使用して現在の日時を取得しています。
			- `ToString('yyyy-MM-dd HH:mm:ss')` により、カスタムフォーマットで日時を出力します。
			- ログファイルの命名規則やスクリプト内のタイムスタンプ生成などに便利です。
	#>
	[CmdletBinding()]
	[OutputType([String])]
	Param ()
	return (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}

#----------------------------------------------------------------------
# UNIX時間をDateTime型に変換
#----------------------------------------------------------------------
function ConvertFrom-UnixTime {
	<#
		.SYNOPSIS
			Unix タイムスタンプをローカル日時に変換します。

		.DESCRIPTION
			この関数は、Unix エポック (1970-01-01 00:00:00 UTC) からの秒数を受け取り、
			ローカル時刻に変換して返します。

		.PARAMETER UnixTime
			変換する Unix タイムスタンプ (1970年1月1日 00:00:00 UTC からの経過秒数) を指定します。

		.INPUTS
			System.Int64
			- 変換する Unix タイムスタンプ (秒単位)。

		.OUTPUTS
			System.DateTime
			- 変換後のローカル日時。

		.EXAMPLE
			PS> ConvertFrom-UnixTime -UnixTime 1712050000
			2024年4月2日 15:06:40

			Unix タイムスタンプ 1712050000 をローカル時刻に変換します。

		.LINK
			https://learn.microsoft.com/en-us/dotnet/api/system.datetime

		.NOTES
			- `UnixTime` は 1970年1月1日 00:00:00 UTC からの経過秒数として扱われます。
			- `.ToLocalTime()` を使用して、現在のタイムゾーンの時刻に変換します。
			- `Remove-Variable` は変数の明示的な削除を試みますが、影響は限定的です。
	#>
        [CmdletBinding()]
        [OutputType([datetime])]
        Param ([Parameter(Mandatory = $true)][int64]$UnixTime)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	$EpochDate = Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0 -AsUTC
	return ($EpochDate.AddSeconds($UnixTime).ToLocalTime())
	Remove-Variable -Name UnixTime, EpochDate -ErrorAction SilentlyContinue
}

#----------------------------------------------------------------------
# DateTime型をUNIX時間に変換
#----------------------------------------------------------------------
function ConvertTo-UnixTime {
	<#
		.SYNOPSIS
			指定した日時を Unix タイムスタンプ (1970年1月1日 00:00:00 UTC からの経過秒数) に変換します。

		.DESCRIPTION
			この関数は、入力された `DateTime` 値を UTC に変換し、Unix エポック (1970-01-01 00:00:00 UTC) からの
			経過秒数として返します。Unix タイムスタンプは、システムログや API のタイムスタンプとして
			よく使用されます。

		.PARAMETER InputDate
			変換する日時 (DateTime 型)。ローカル時刻として渡された場合、自動的に UTC に変換されます。

		.INPUTS
			System.DateTime
			- 変換する日時。

		.OUTPUTS
			System.Int64
			- Unix タイムスタンプ (1970年1月1日 00:00:00 UTC からの経過秒数)。

		.EXAMPLE
			PS> ConvertTo-UnixTime -InputDate (Get-Date)
			1712050000

			現在の日時を Unix タイムスタンプに変換します。

		.EXAMPLE
			PS> ConvertTo-UnixTime -InputDate "2025-04-02 12:34:56"
			1743593696

			指定した日時を Unix タイムスタンプに変換します。

		.LINK
			https://learn.microsoft.com/en-us/dotnet/api/system.datetime

		.NOTES
			- Unix タイムスタンプは UTC を基準とするため、入力日時は `.ToUniversalTime()` で UTC に変換されます。
			- `New-TimeSpan` を使用して Unix エポック (1970-01-01 00:00:00 UTC) からの経過秒数を計算します。
			- `Math.Round()` を使用して、秒単位で切り捨てまたは四捨五入します。
	#>
	[CmdletBinding()]
	[OutputType([int64])]
	Param ([Parameter(Mandatory = $true)][DateTime]$InputDate)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	$unixTime = New-TimeSpan -Start '1970-01-01' -End $InputDate.ToUniversalTime()
	return [int64][math]::Round($unixTime.TotalSeconds)
	Remove-Variable -Name InputDate, unixTime -ErrorAction SilentlyContinue
}
#endregion タイムスタンプ

#region 文字列操作
#----------------------------------------------------------------------
# ファイル名・ディレクトリ名に禁止文字の削除
#----------------------------------------------------------------------
function Get-FileNameWoInvalidChar {
	<#
		.SYNOPSIS
			ファイル名に使用できない無効な文字を削除し、安全なファイル名を生成します。

		.DESCRIPTION
			この関数は、指定された文字列からファイル名として使用できない無効な文字を削除し、
			OS に依存せず適切なファイル名を生成します。
			Windows の `GetInvalidFileNameChars()` に加え、Linux/Mac で問題となる `*?<>|` などの記号や
			制御文字も削除します。

		.PARAMETER name
			ファイル名として使用したい文字列。デフォルトは空文字列 (`''`)。

		.INPUTS
			System.String
			- 無効な文字を除去する元のファイル名。

		.OUTPUTS
			System.String
			- 無効な文字を削除した後の安全なファイル名。

		.EXAMPLE
			PS> Get-FileNameWoInvalidChar -name "invalid:file*name?.txt"
			"invalid-filename-.txt"

			Windows のファイル名に使用できない `:` `*` `?` を削除または置換。

		.EXAMPLE
			PS> Get-FileNameWoInvalidChar -name "test/|<>file"
			"test-file"

			Linux/Mac で問題となる `/` `|` `<>` も削除。

		.EXAMPLE
			PS> Get-FileNameWoInvalidChar -name "file--name--test"
			"file-name-test"

			連続した `-` を一つに統一。

		.LINK
			https://learn.microsoft.com/en-us/dotnet/api/system.io.path.getinvalidfilenamechars

		.NOTES
			- `GetInvalidFileNameChars()` を使用して OS に応じた無効文字を取得。
			- `-replace` を使用して、追加の無効文字や制御文字も削除。
			- 連続する `-` を 1 つに統一し、より読みやすいファイル名を生成。
	#>
	[CmdletBinding()]
	[OutputType([String])]
	Param ([String]$name = '')
	Write-Debug ('{0} - {1}' -f $MyInvocation.MyCommand.Name, $name)
	# 使用する正規表現パターンを定義
	$invalidCharsPattern = '[{0}]' -f [RegEx]::Escape( [IO.Path]::GetInvalidFileNameChars() -Join '')
	$additionalReplaces = '[*\?<>|]'	# Linux/MacではGetInvalidFileNameChars()が不完全なため、ダメ押しで置換
	$nonPrintableChars = '[\x00-\x1F\x7F]'	# ASCII制御文字()
	# 無効な文字を削除
	$name = $name -replace $invalidCharsPattern, '' `
		-replace $additionalReplaces, '-' `
		-replace $nonPrintableChars, '' `
		-replace '-+', '-'
	return $name
	Remove-Variable -Name invalidCharsPattern, name, additionalReplaces, nonPrintableChars -ErrorAction SilentlyContinue
}

#----------------------------------------------------------------------
# 英数のみ全角→半角(カタカナは全角)
#----------------------------------------------------------------------
function Get-NarrowChar {
	<#
		.SYNOPSIS
			全角文字を半角に、半角カタカナを全角カタカナに変換します。

		.DESCRIPTION
			この関数は、以下の変換を行います:
			- 全角英数字を半角英数字に変換
			- 全角記号を半角記号に変換
			- 半角カタカナを全角カタカナに変換
			これにより、異なるフォーマットのテキストデータを統一し、検索や比較が容易になります。

		.PARAMETER text
			変換対象の文字列。デフォルトは空文字列 (`''`)。

		.INPUTS
			System.String
			- 変換前の文字列。

		.OUTPUTS
			System.String
			- 変換後の文字列。

		.EXAMPLE
			PS> Get-NarrowChar -text "Ｔｅｓｔ１２３"
			"Test123"

			全角英数字を半角に変換。

		.EXAMPLE
			PS> Get-NarrowChar -text "ｶﾀｶﾅ ﾃｽﾄ"
			"カタカナ テスト"

			半角カタカナを全角カタカナに変換。

		.EXAMPLE
			PS> Get-NarrowChar -text "＠＃＄％＾＆＊"
			"@#$%^&*"

			全角記号を半角記号に変換。

		.NOTES
			- 変換には `-replace` を使用せず `.Replace()` を用いて高速化。
			- `GetEnumerator()` を用いたループで各文字を効率的に変換。
	#>
	[CmdletBinding()]
	[OutputType([String])]
	Param ([String]$text = '')
	Write-Debug ('{0} - {1}' -f $MyInvocation.MyCommand.Name, $text)
	$replaceChars = @{
		'０１２３４５６７８９'                                           = '0123456789'
		'ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ' = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
		'＠＃＄％＾＆＊－＋＿／［］｛｝（）＜＞　￥＼"；：．，'                          = '@#$%^&*-+_/[]{}()<> \\";:.,'
	}
	foreach ($entry in $replaceChars.GetEnumerator()) {
		for ($i = 0 ; $i -lt $entry.Name.Length ; $i++) {
			$text = $text.Replace($entry.Name[$i], $entry.Value[$i])
		}
	}
	$replacements = @{
		'ｱ'  = 'ア'
		'ｲ'  = 'イ'
		'ｳ'  = 'ウ'
		'ｴ'  = 'エ'
		'ｵ'  = 'オ'
		'ｶ'  = 'カ'
		'ｷ'  = 'キ'
		'ｸ'  = 'ク'
		'ｹ'  = 'ケ'
		'ｺ'  = 'コ'
		'ｻ'  = 'サ'
		'ｼ'  = 'シ'
		'ｽ'  = 'ス'
		'ｾ'  = 'セ'
		'ｿ'  = 'ソ'
		'ﾀ'  = 'タ'
		'ﾁ'  = 'チ'
		'ﾂ'  = 'ツ'
		'ﾃ'  = 'テ'
		'ﾄ'  = 'ト'
		'ﾅ'  = 'ナ'
		'ﾆ'  = 'ニ'
		'ﾇ'  = 'ヌ'
		'ﾈ'  = 'ネ'
		'ﾉ'  = 'ノ'
		'ﾊ'  = 'ハ'
		'ﾋ'  = 'ヒ'
		'ﾌ'  = 'フ'
		'ﾍ'  = 'ヘ'
		'ﾎ'  = 'ホ'
		'ﾏ'  = 'マ'
		'ﾐ'  = 'ミ'
		'ﾑ'  = 'ム'
		'ﾒ'  = 'メ'
		'ﾓ'  = 'モ'
		'ﾔ'  = 'ヤ'
		'ﾕ'  = 'ユ'
		'ﾖ'  = 'ヨ'
		'ﾗ'  = 'ラ'
		'ﾘ'  = 'リ'
		'ﾙ'  = 'ル'
		'ﾚ'  = 'レ'
		'ﾛ'  = 'ロ'
		'ﾜ'  = 'ワ'
		'ｦ'  = 'ヲ'
		'ﾝ'  = 'ン'
		'ｧ'  = 'ァ'
		'ｨ'  = 'ィ'
		'ｩ'  = 'ゥ'
		'ｪ'  = 'ェ'
		'ｫ'  = 'ォ'
		'ｬ'  = 'ャ'
		'ｭ'  = 'ュ'
		'ｮ'  = 'ョ'
		'ｯ'  = 'ッ'
		'ｰ'  = 'ー'
		'ｳﾞ' = 'ヴ'
		'ｶﾞ' = 'ガ'
		'ｷﾞ' = 'ギ'
		'ｸﾞ' = 'グ'
		'ｹﾞ' = 'ゲ'
		'ｺﾞ' = 'ゴ'
		'ｻﾞ' = 'ザ'
		'ｼﾞ' = 'ジ'
		'ｽﾞ' = 'ズ'
		'ｾﾞ' = 'ゼ'
		'ｿﾞ' = 'ゾ'
		'ﾀﾞ' = 'ダ'
		'ﾁﾞ' = 'ヂ'
		'ﾂﾞ' = 'ヅ'
		'ﾃﾞ' = 'デ'
		'ﾄﾞ' = 'ド'
		'ﾊﾞ' = 'バ'
		'ﾋﾞ' = 'ビ'
		'ﾌﾞ' = 'ブ'
		'ﾍﾞ' = 'ベ'
		'ﾎﾞ' = 'ボ'
		'ﾊﾟ' = 'パ'
		'ﾋﾟ' = 'ピ'
		'ﾌﾟ' = 'プ'
		'ﾍﾟ' = 'ペ'
		'ﾎﾟ' = 'ポ'
	}
	foreach ($replacement in $replacements.GetEnumerator()) {
		$text = $text.Replace($replacement.Name, $replacement.Value)
	}
	return $text
	Remove-Variable -Name text, replaceChars, entry, i, replacements, replacement -ErrorAction SilentlyContinue
}

#----------------------------------------------------------------------
# いくつかの特殊文字を置換
#----------------------------------------------------------------------
function Remove-SpecialCharacter {
	<#
		.SYNOPSIS
			特殊文字を適切な文字に置換または削除する。

		.DESCRIPTION
			この関数は、以下の処理を行います:
			- `&amp;` を `&` に変換
			- 特定の特殊文字を全角に変換 (例: `*` → `＊`)
			- ダブルクォート (`"`) を削除
			- U+2018, U+2019 のシングルクォートを標準の `'` に変換

		.PARAMETER text
			変換対象の文字列。

		.INPUTS
			System.String
			- 変換前の文字列。

		.OUTPUTS
			System.String
			- 変換後の文字列。

		.EXAMPLE
			PS> Remove-SpecialCharacter -text "Test*File|Name:2024"
			"Test＊File｜Name：2024"

			アスタリスク `*`、パイプ `|`、コロン `:` を全角に変換。

		.EXAMPLE
			PS> Remove-SpecialCharacter -text "Hello"World""
			"HelloWorld"

			全角ダブルクォートを削除。

		.EXAMPLE
			PS> Remove-SpecialCharacter -text "Can't"
			"Can't"

			U+2019 のシングルクォートを標準の `'` に変換。

		.NOTES
			- 一部の特殊記号は削除されず全角に置き換え。
			- ダブルクォート (`"`) は削除。
	#>
	[CmdletBinding()]
	[OutputType([String])]
	Param ([String]$text)
	Write-Debug ('{0} - {1}' -f $MyInvocation.MyCommand.Name, $text)
	$text = $text.Replace('&amp;', '&')
	# * 下記一部がUnicode指定なので、VScodeなどのIDEで勝手に変換されないようにするため
	$replacements = @{
		'*'        = '＊' # 全角
		'|'        = '｜' # 全角
		':'        = '：' # 全角
		';'        = '；' # 全角
		"`u{2018}" = "'" # * U+2018をU+0027に変換
		"`u{2019}" = "'" # * U+2019をU+0027に変換
		'"'        = '' # 削除
		"`u{201C}" = ''  # * 全角でもダブルクォートとして認識されるようなので削除
		"`u{201D}" = ''  # * 全角でもダブルクォートとして認識されるようなので削除
		'?'        = '？' # 全角
		'!'        = '！' # 全角
		'/'        = '／' # 全角
		'\'        = '＼' # 全角
		'<'        = '＜' # 全角
		'>'        = '＞' # 全角
	}
	foreach ($replacement in $replacements.GetEnumerator()) { $text = $text.Replace($replacement.Name, $replacement.Value) }
	return $text
	Remove-Variable -Name text, replacements, replacement -ErrorAction SilentlyContinue
}

#----------------------------------------------------------------------
# タブとスペースを詰めて半角スペース1文字に
#----------------------------------------------------------------------
function Remove-TabSpace {
	<#
		.SYNOPSIS
			タブや連続したスペースを単一スペースに置換する。

		.DESCRIPTION
			この関数は、以下の処理を行います:
			- タブ (`\t`) をスペース (` `) に変換。
			- 連続したスペース (`\s+`) を単一のスペース (` `) に置換。

		.PARAMETER text
			変換対象の文字列。

		.INPUTS
			System.String
			- 変換前の文字列。

		.OUTPUTS
			System.String
			- 変換後の文字列。

		.EXAMPLE
			PS> Remove-TabSpace -text "Hello`tWorld"
			"Hello World"

			タブがスペースに変換される。

		.EXAMPLE
			PS> Remove-TabSpace -text "This   is   a  test"
			"This is a test"

			連続したスペースが単一スペースに変換される。

		.NOTES
			- タブ (`\t`) はすべてスペースに変換される。
			- 複数のスペースは単一のスペースにまとめられる。
	#>
	[CmdletBinding()]
	[OutputType([String])]
	Param ([String]$text)
	Write-Debug ('{0} - {1}' -f $MyInvocation.MyCommand.Name, $text)
	return $text.Replace("`t", ' ') -replace '\s+', ' '
	Remove-Variable -Name text -ErrorAction SilentlyContinue
}

#----------------------------------------------------------------------
# 設定ファイルの行末コメントを削除
#----------------------------------------------------------------------
function Get-ContentWoComment {
	<#
		.SYNOPSIS
			文字列からコメントや不要な空白を削除する。

		.DESCRIPTION
			この関数は、以下の処理を行います:
			- タブ (`\t`) で区切られた最初の要素を取得
			- スペース (` `) で区切られた最初の要素を取得
			- `#` 記号を含む場合、最初の `#` 以降の部分を削除

		.PARAMETER text
			変換対象の文字列。

		.INPUTS
			System.String
			- 変換前の文字列。

		.OUTPUTS
			System.String
			- コメントや不要な部分を削除した文字列。

		.EXAMPLE
			PS> Get-ContentWoComment -text "command # this is a comment"
			"command"

			`#` 以降のコメントを削除。

		.EXAMPLE
			PS> Get-ContentWoComment -text "command    argument    # comment"
			"command"

			スペースで区切られた最初の要素のみを取得。

		.EXAMPLE
			PS> Get-ContentWoComment -text "command`targument`tmore # comment"
			"command"

			タブで区切られた最初の要素のみを取得。

		.NOTES
			- `#` より前の文字列のみを取得する。
			- スペースやタブで区切られた最初の要素のみを保持する。
	#>
	[OutputType([String])]
	Param ([String]$text)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	return $text.Split("`t")[0].Split(' ')[0].Split('#')[0]
	Remove-Variable -Name text -ErrorAction SilentlyContinue
}
#endregion 文字列操作

#region ファイル操作
#----------------------------------------------------------------------
# 指定したPath配下の指定した条件でファイルを削除
#----------------------------------------------------------------------
function Remove-File {
	<#
		.SYNOPSIS
			指定した条件に基づいて古いファイルを削除します。

		.DESCRIPTION
			この関数は、以下の2つの方法でファイル削除を実行します：

			1. 条件指定による削除:
			- 指定したディレクトリ (`basePath`) 内のファイルを、指定した条件 (`conditions`) に基づいて検索
			- 指定した削除期間 (`delPeriod`) よりも古いファイルを削除

			2. パイプライン入力による削除:
			- パイプラインから直接ファイルオブジェクトを受け取り
			- 指定した削除期間よりも古いファイルを削除

			パフォーマンス最適化:
			- マルチスレッド処理をサポート (`$script:enableMultithread` が `$true` の場合)
			- 並列処理数は `$script:multithreadNum` で制御
			- メモリ効率を考慮した動的なファイルリスト管理
			- パイプライン処理の最適化

			進捗表示:
			- `Write-Information` を使用して処理状況を表示
			- 検索条件、削除対象ファイル、実際の削除操作を表示

		.PARAMETER basePath
			検索対象のディレクトリまたはファイルを指定します。
			パイプライン入力の場合は、FileInfo オブジェクトとして受け取ります。

		.PARAMETER conditions
			削除対象のファイル名パターン（ワイルドカード可）の配列。
			パイプライン入力の場合は不要です。

		.PARAMETER delPeriod
			削除対象となるファイルの最終更新日時の閾値（日数単位）。
			この日数よりも古いファイルが削除されます。

		.INPUTS
			System.IO.FileInfo
			- パイプラインからファイルオブジェクトを受け取ることができます。
			- ファイルの LastWriteTime プロパティを使用して経過日数を判定します。

		.OUTPUTS
			なし（[Void]）

		.EXAMPLE
			PS> Remove-File -basePath "C:\Logs" -conditions @("*.log", "*.tmp") -delPeriod 30

			`C:\Logs` 内の `*.log` および `*.tmp` ファイルのうち、
			最終更新日時が 30 日よりも古いファイルを削除します。

		.EXAMPLE
			PS> Get-ChildItem -Path "C:\Logs" -Recurse -File | Remove-File -delPeriod 7

			パイプラインを使用して、`C:\Logs` 内のすべてのファイルから
			7日以上経過したものを削除します。

		.NOTES
			- マルチスレッド処理を有効にする場合は、`$script:enableMultithread` を `$true` に設定
			- 並列処理数は `$script:multithreadNum` で調整可能
			- 処理状況は `Write-Information` で確認可能 (-InformationAction Continue を指定)
			- エラー発生時は Warning として記録
			- ShouldProcess をサポートしており、-WhatIf で削除前の確認が可能
	#>
	[CmdletBinding(SupportsShouldProcess = $true, SupportsPaging = $true)]
	[OutputType([Void])]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[System.IO.FileInfo]$basePath,

		[Parameter(Mandatory = $false)]
		[String[]]$conditions,

		[Parameter(Mandatory = $true)]
		[int32]$delPeriod
	)
	begin {
		Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
		$limitDateTime = (Get-Date).AddDays(-1 * $delPeriod)
		$targetFiles = [System.Collections.Generic.List[string]]::new()
	}

	process {
		if ($conditions) {
			# 条件指定がある場合の処理
			if ($script:enableMultithread) {
				Write-Debug ('Multithread Processing Enabled')
				try {
					# 並列処理で見つかったファイルを一時的に格納
					$parallelResults = $conditions | ForEach-Object -ThrottleLimit $script:multithreadNum -Parallel {
						Write-Debug ($script:msg.DeleteCondition -f $_)
						Get-ChildItem -LiteralPath $using:basePath -Recurse -File -Filter $_ -ErrorAction SilentlyContinue |
							Where-Object { $_.LastWriteTime -lt $using:limitDateTime } |
							ForEach-Object { Write-Debug ($script:msg.DeleteTarget -f $_.FullName) ; $_.FullName }
						}
						# 並列処理の結果をまとめてリストに追加
						if ($parallelResults) { $targetFiles.AddRange($parallelResults) }
					} catch { Write-Warning ($script:msg.FileCannotBeDeleted) }
				} else {
					try {
						foreach ($condition in $conditions) {
							Write-Debug ($script:msg.DeleteCondition -f $condition)
							$files = Get-ChildItem -LiteralPath $basePath -Recurse -File -Filter $condition -ErrorAction SilentlyContinue |
								Where-Object { $_.LastWriteTime -lt $limitDateTime } |
								ForEach-Object { Write-Debug ($script:msg.DeleteTarget -f $_.FullName) ; $_.FullName }
						if ($files) { $targetFiles.AddRange($files) }
					}
				} catch { Write-Warning ($script:msg.FileCannotBeDeleted) }
			}
		} else {
			# パイプライン入力の場合の処理
			if ($basePath.LastWriteTime -lt $limitDateTime) { Write-Debug ($script:msg.DeleteTarget -f $basePath.FullName) ; $targetFiles.Add($basePath.FullName) }
		}
	}

	end {
		# ファイル削除の実行
		$targetFiles | ForEach-Object {
			try {
				if ($PSCmdlet.ShouldProcess($_, 'Remove file')) { Write-Information ($script:msg.DeleteFile -f $_) ; Remove-Item -LiteralPath $_ -Force -ErrorAction SilentlyContinue }
			} catch { Write-Warning $script:msg.FileCannotBeDeleted }
		}

		Remove-Variable -Name basePath, conditions, delPeriod, limitDateTime, targetFiles, parallelResults -ErrorAction SilentlyContinue
	}
}

#----------------------------------------------------------------------
# Zipファイルを解凍
#----------------------------------------------------------------------
function Expand-Zip {
	<#
		.SYNOPSIS
			ZIPファイルを指定したディレクトリに展開する。

		.DESCRIPTION
			指定したZIPファイル (`path`) を、指定した展開先 (`destination`) に解凍する。
			すでに展開先に同名のファイルが存在する場合は、上書きする。

		.PARAMETER path
			展開するZIPファイルのパス。

		.PARAMETER destination
			ZIPファイルを展開するディレクトリのパス。

		.INPUTS
			System.String
			- ZIPファイルのパスと展開先ディレクトリ。

		.OUTPUTS
			なし（[Void]）

		.EXAMPLE
			PS> Expand-Zip -path "C:\Backup\data.zip" -destination "C:\ExtractedData"

			`C:\Backup\data.zip` を `C:\ExtractedData` に展開する。

		.EXAMPLE
			PS> Expand-Zip -path "/home/user/archive.zip" -destination "/home/user/unpacked"

			`/home/user/archive.zip` を `/home/user/unpacked` に展開する（Linux環境）。

		.NOTES
			- ZIPファイルが存在しない場合、エラーをスローする。
			- すでに展開先にファイルが存在する場合は上書きされる。
			- .NET の `[System.IO.Compression.ZipFile]::ExtractToDirectory` を利用して展開を実施。
	#>
	[CmdletBinding()]
	[OutputType([Void])]
	Param (
		[Parameter(Mandatory = $true)][String]$path,
		[Parameter(Mandatory = $true)][String]$destination
	)
	Write-Debug ('{0} - {1}' -f $MyInvocation.MyCommand.Name, $path)
	if (Test-Path -Path $path) {
		Write-Verbose ('Extracting {0} into {1}' -f $path, $destination)
		[System.IO.Compression.ZipFile]::ExtractToDirectory($path, $destination, $true)
		Write-Verbose ('Extracted {0}' -f $path)
	} else { throw ($script:msg.FileNotFound -f $path) }
	Remove-Variable -Name path, destination -ErrorAction SilentlyContinue
}
#endregion ファイル操作

#region ファイルロック
#----------------------------------------------------------------------
# ファイルのロック
#----------------------------------------------------------------------
function Lock-File {
	<#
		.SYNOPSIS
			指定したファイルをロックする。

		.DESCRIPTION
			指定したファイル (`path`) を開き、読み書きロックを設定することで、他のプロセスによるアクセスを防ぐ。

		.PARAMETER path
			ロックするファイルのパス。

		.INPUTS
			System.String
			- ロックするファイルのパス。

		.OUTPUTS
			PSCustomObject
			- `path` : 指定されたファイルパス
			- `result` : ロックの成否（`$true` または `$false`）

		.EXAMPLE
			PS> Lock-File -path "C:\Temp\test.txt"

			`C:\Temp\test.txt` をロックする。

		.EXAMPLE
			PS> $lockResult = Lock-File -path "/home/user/data.log"
			PS> $lockResult.result

			`/home/user/data.log` をロックし、結果 (`$true` または `$false`) を取得。

		.NOTES
			- `[System.IO.FileInfo]` を使用してファイル情報を取得し、`Open` メソッドでロックを確立。
			- `FileShare.None` を指定することで、他のプロセスがファイルにアクセスできないようにする。
			- ロックに失敗すると `$false` を返す。
	#>
	[CmdletBinding()]
	[OutputType([PSCustomObject])]
	Param ([parameter(Mandatory = $true)][String]$path)
	Write-Debug ('{0} - {1}' -f $MyInvocation.MyCommand.Name, $path)
	try {
		# ファイルを開こうとしファイルロックを検出
		$script:fileInfo[$path] = [System.IO.FileInfo]::new($path)
		$script:fileStream[$path] = $script:fileInfo[$path].Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
		$result = $true
	} catch { $result = $false }
	# 結果の返却
	return [PSCustomObject]@{
		path   = $path
		result = $result
	}
	Remove-Variable -Name path, result -ErrorAction SilentlyContinue
}

#----------------------------------------------------------------------
# ファイルのアンロック
#----------------------------------------------------------------------
function Unlock-File {
	<#
		.SYNOPSIS
			指定したファイルのロックを解除する。

		.DESCRIPTION
			`Lock-File` 関数でロックされたファイルを解放し、他のプロセスがアクセスできるようにする。

		.PARAMETER path
			ロックを解除するファイルのパス。

		.INPUTS
			System.String
			- ロックを解除するファイルのパス。

		.OUTPUTS
			PSCustomObject
			- `path` : 指定されたファイルパス
			- `result` : ロック解除の成否（`$true` または `$false`）

		.EXAMPLE
			PS> Unlock-File -path "C:\Temp\test.txt"

			`C:\Temp\test.txt` のロックを解除する。

		.EXAMPLE
			PS> $unlockResult = Unlock-File -path "/home/user/data.log"
			PS> $unlockResult.result

			`/home/user/data.log` のロックを解除し、結果 (`$true` または `$false`) を取得。

		.NOTES
			- `Lock-File` 関数でロックしたファイルを開放するために使用する。
			- `$script:fileStream` からエントリを削除し、リソースを解放する。
			- すでにロックが解除されている場合は何もしない。
	#>
	[CmdletBinding()]
	[OutputType([PSCustomObject])]
	Param ([parameter(Mandatory = $true)][String]$path)
	Write-Debug ('{0} - {1}' -f $MyInvocation.MyCommand.Name, $path)
	if (Test-Path $path) {
		if ($script:fileStream[$path]) {
			# ロックされていなければストリームを閉じる
			$script:fileStream[$path].Close()
			$script:fileStream[$path].Dispose()
			$script:fileStream[$path] = $null
			$script:fileStream.Remove($path)
		}
		$result = $true
	} else { $result = $false }
	# 結果の返却
	return [PSCustomObject]@{
		path   = $path
		result = $result
	}
	Remove-Variable -Name path, result -ErrorAction SilentlyContinue
}
#endregion ファイルロック

#region ディスク監視
#----------------------------------------------------------------------
# ディレクトリの空き容量確認(MB)
#----------------------------------------------------------------------
function Get-RemainingCapacity {
	<#
		.SYNOPSIS
			指定したディレクトリの空き容量を取得する。

		.DESCRIPTION
			指定したディレクトリのあるドライブやファイルシステムの空き容量をMB単位で返す。

		.PARAMETER targetDir
			空き容量を取得する対象ディレクトリ。

		.INPUTS
			System.String
			- チェックするディレクトリのパス。

		.OUTPUTS
			System.Int64
			- 指定したディレクトリのあるドライブの空き容量（MB単位）。

		.EXAMPLE
			PS> Get-RemainingCapacity -targetDir "C:\Users"

			`C:\Users` のあるドライブの空き容量を取得。

		.EXAMPLE
			PS> Get-RemainingCapacity -targetDir "/home/user"

			`/home/user` のあるファイルシステムの空き容量を取得。

		.NOTES
			- Windows では `Get-CimInstance` を使用。
			- Linux/macOS では `df` コマンドを実行。
			- UNC パス (`\\server\share`) の場合は `dir` コマンドを利用。
	#>
	[CmdletBinding()]
	[OutputType([int64])]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$targetDir
	)
	Write-Debug ('{0} - {1}' -f $MyInvocation.MyCommand.Name, $targetDir)
	if ($IsWindows) {
		try {
			switch -Regex ($targetDir) {
				'^[a-zA-Z]:' {
					# ローカルディスクまたはマウントされたネットワークドライブ (例: "C:\", "Z:\")
					$targetDrive = $targetDir.Substring(0, 2)  # "C:" or "Z:"
					$freeSpace = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$targetDrive'").FreeSpace
					break
				}
				'^\\\\' {
					# UNC パス (例: "\\server\share")
					$targetRoot = ($targetDir -replace '(^\\\\[^\\]+\\[^\\]+).*', '$1')  # \\server\share
					$freeSpace = (& cmd /c dir $targetRoot) | Select-Object -Last 1 | ForEach-Object { $_ -replace ',' -split '\s+' } | Select-Object -Index 3
					break
				}
				default { Write-Information ($script:msg.CapacityUnknown -f $targetDir) ; $freeSpace = 9999999999 }
			}
		} catch { Write-Information ($script:msg.CapacityUnknown -f $targetDir) ; $freeSpace = 9999999999 }
	} else {
		try {
			$dfCmd = "df -P `"$targetDir`""
			$freeSpace = [int64](((& sh -c $dfCmd) | Select-Object -Skip 1) -split '\s+')[3] * 1024
		} catch { Write-Information ($script:msg.CapacityUnknown -f $targetDir) ; $freeSpace = 9999999999 }
	}
	return [int64]($freeSpace / 1MB)
	Remove-Variable -Name targetDir, targetDrive, freeSpace, targetRoot -ErrorAction SilentlyContinue
}
#endregion ディスク監視

#region トースト通知
# モジュールのインポート
if ($IsWindows -and !$script:disableToastNotification -and (!('Microsoft.Toolkit.Uwp.Notifications.ToastContentBuilder' -as [Type]))) {
	Add-Type -LiteralPath (Join-Path $script:libDir 'win/core/Microsoft.Windows.SDK.NET.dll') | Out-Null
	Add-Type -LiteralPath (Join-Path $script:libDir 'win/core/WinRT.Runtime.dll') | Out-Null
	Add-Type -LiteralPath (Join-Path $script:libDir 'win/core/Microsoft.Toolkit.Uwp.Notifications.dll') | Out-Null
}

#----------------------------------------------------------------------
# トースト表示
#----------------------------------------------------------------------
function Show-GeneralToast {
	<#
		.SYNOPSIS
			カスタムテキストと期間を指定してトースト通知を表示します。

		.DESCRIPTION
			この関数は、Windows、Linux、macOS の各プラットフォームで指定された内容のトースト通知を表示します。
			ユーザーは通知のメッセージ、期間、および音が鳴るかどうかを制御できます。
			通知の期間は「短い」または「長い」を選択できます。

		.PARAMETER text1
			トースト通知のメインコンテンツとなるテキストです。通知に表示される主要なテキストを指定します。

		.PARAMETER text2
			オプションで、通知の副次的なテキストを指定します。追加の詳細情報などを表示するために使用できます。

		.PARAMETER duration
			通知の表示時間を指定します。「短い」または「長い」のいずれかを選択できます。デフォルトは「短い」です。

		.PARAMETER silent
			このパラメータが$trueの場合、通知の音が鳴りません。デフォルトは$falseで、音が鳴ります。

		.EXAMPLE
			Show-GeneralToast -text1 "タスク完了" -text2 "すべての処理が完了しました！" -duration "Long"

			「長い」期間のトースト通知を指定されたメッセージで表示します。

		.EXAMPLE
			Show-GeneralToast -text1 "エラーが発生しました" -silent $true

			音なしでトースト通知を表示します。
	#>
	[CmdletBinding()]
	[OutputType([Void])]
	Param (
		[Parameter(Mandatory = $true )][String]$text1,
		[Parameter(Mandatory = $false)][String]$text2 = '',
		[Parameter(Mandatory = $false)][ValidateSet('Short', 'Long')][String]$duration = 'Short',
		[Parameter(Mandatory = $false)][Boolean]$silent = $false
	)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	if (!$script:disableToastNotification) {
		switch ($true) {
			$IsWindows {
				$toastSoundElement = if ($silent) { '<audio silent="true" />' }
				else { '<audio src="ms-winsoundevent:Notification.Default" loop="false"/>' }
				$toastProgressContent = @"
<?xml version="1.0" encoding="utf-8"?>
<toast duration="$duration">
    <visual>
        <binding template="ToastGeneric">
            <text>$script:appName</text>
            <text>$text1</text>
            <text>$text2</text>
            <image placement="appLogoOverride" src="$script:toastAppLogo"/>
        </binding>
    </visual>
    $toastSoundElement
</toast>
"@
				$toastXML = [Windows.Data.Xml.Dom.XmlDocument]::new()
				$toastXML.LoadXml($toastProgressContent)
				$toastNotification = [Windows.UI.Notifications.ToastNotification]::new($toastXML)
				[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($script:appID).Show($toastNotification) | Out-Null
				break
			}
			$IsLinux {
				if (Get-Command notify-send -ErrorAction SilentlyContinue) { & notify-send -a $script:appName -t 5000 -i $script:toastAppLogo $text1 $text2 2> /dev/null }
				break
			}
			$IsMacOS {
				if (Get-Command osascript -ErrorAction SilentlyContinue) {
					$toastParams = ('display notification "{0}" with title "{1}" subtitle "{2}" sound name "Blow"' -f $text2, $script:appName, $text1)
					$toastParams | & osascript 2> /dev/null
				}
				break
			}
			default {}
		}
	}
	Remove-Variable -Name text1, text2, duration, silent, toastSoundElement, toastProgressContent, toastXML, toastNotification, toastParams -ErrorAction SilentlyContinue
}

#----------------------------------------------------------------------
# 進捗バー付きトースト表示
#----------------------------------------------------------------------
function Show-ProgressToast {
	<#
		.SYNOPSIS
			進行状況を示すトースト通知を表示します。

		.DESCRIPTION
			この関数は、Windows、Linux、macOS の各プラットフォームで進行状況を示すトースト通知を表示します。
			ユーザーは通知のメッセージ、進行状況の詳細、期間、および音の有無を制御できます。
			通知は「短い」または「長い」期間で表示できます。

		.PARAMETER text1
			トースト通知のメインテキストです。通常、処理が開始されたことや進行中のタスクに関する説明が表示されます。

		.PARAMETER text2
			オプションの副次的なテキストです。追加情報や補足的な説明を表示するために使用します。

		.PARAMETER workDetail
			進行中の作業の詳細情報です。進捗状況の説明を通知に追加するために使用します。

		.PARAMETER tag
			トースト通知のタグです。同じグループに属する通知を識別するために使用します。

		.PARAMETER group
			トースト通知のグループ名です。同じグループ内で通知を整理できます。

		.PARAMETER duration
			通知の表示時間を指定します。「短い」または「長い」のいずれかを選択できます。デフォルトは「短い」です。

		.PARAMETER silent
			音なしで通知を表示する場合は$trueを指定します。デフォルトは$falseで、音が鳴ります。

		.EXAMPLE
			Show-ProgressToast -text1 "処理中" -text2 "ファイルを読み込んでいます..." -workDetail "データのロード" -tag "fileLoad" -group "taskGroup" -duration "Long"

			長期間表示される進行状況を示すトースト通知を表示します。

		.EXAMPLE
			Show-ProgressToast -text1 "エラー発生" -silent $true -tag "errorTask" -group "errorGroup"

			音なしでエラー発生を通知する進行状況トーストを表示します。
	#>
	[CmdletBinding()]
	[OutputType([Void])]
	Param (
		[Parameter(Mandatory = $true )][String]$text1,
		[Parameter(Mandatory = $false)][String]$text2 = '',
		[Parameter(Mandatory = $false)][String]$workDetail = '',
		[Parameter(Mandatory = $true )][String]$tag,
		[Parameter(Mandatory = $true )][String]$group,
		[Parameter(Mandatory = $false)][ValidateSet('Short', 'Long')][String]$duration = 'Short',
		[Parameter(Mandatory = $false)][Boolean]$silent = $false
	)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	if (!$script:disableToastNotification) {
		switch ($true) {
			$IsWindows {
				$toastSoundElement = if ($silent) { '<audio silent="true" />' }
				else { '<audio src="ms-winsoundevent:Notification.Default" loop="false"/>' }
				$toastContent = @"
<?xml version="1.0" encoding="utf-8"?>
<toast duration="$duration">
    <visual>
        <binding template="ToastGeneric">
            <text>$script:appName</text>
            <text>$text1</text>
            <text>$text2</text>
            <image placement="appLogoOverride" src="$script:toastAppLogo"/>
            <progress value="{progressValue}" title="{progressTitle}" valueStringOverride="{progressValueString}" status="{progressStatus}" />
            <text placement="attribution"></text>
        </binding>
    </visual>
    $toastSoundElement
</toast>
"@
				$toastXML = [Windows.Data.Xml.Dom.XmlDocument]::new()
				$toastXML.LoadXml($toastContent)
				$toast = [Windows.UI.Notifications.ToastNotification]::new($toastXML)
				$toast.Tag = $tag
				$toast.Group = $group
				$toastData = [System.Collections.Generic.Dictionary[String, String]]::new()
				$toastData.Add('progressTitle', $workDetail) | Out-Null
				$toastData.Add('progressValue', '') | Out-Null
				$toastData.Add('progressValueString', '') | Out-Null
				$toastData.Add('progressStatus', '') | Out-Null
				$toast.Data = [Windows.UI.Notifications.NotificationData]::new($toastData)
				$toast.Data.SequenceNumber = 1
				[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($script:appID).Show($toast) | Out-Null
				break
			}
			$IsLinux {
				if (Get-Command notify-send -ErrorAction SilentlyContinue) { & notify-send -a $script:appName -t 5000 -i $script:toastAppLogo $text1 $text2 2> /dev/null }
				break
			}
			$IsMacOS {
				if (Get-Command osascript -ErrorAction SilentlyContinue) {
					$toastParams = ('display notification "{0}" with title "{1}" subtitle "{2}" sound name "Blow"' -f $text2, $script:appName, $text1)
					$toastParams | & osascript
				}
				break
			}
			default {}
		}
	}
	Remove-Variable -Name text1, text2, workDetail, tag, group, duration, silent, toastSoundElement, toastContent, toastXML, toast, toastData, toastParams -ErrorAction SilentlyContinue
}

#----------------------------------------------------------------------
# 進捗バー付きトースト更新
#----------------------------------------------------------------------
function Update-ProgressToast {
	<#
		.SYNOPSIS
			進行状況の更新を行うトースト通知を更新します。

		.DESCRIPTION
			この関数は、Windows プラットフォームで進行状況を更新するためのトースト通知を更新します。
			進行中の作業の進捗率や状態を動的に更新するために使用できます。

		.PARAMETER title
			トースト通知のタイトルテキストです。主に作業の種類を示します。

		.PARAMETER rate
			進行状況の進捗率を指定します。通常は0〜100の範囲で指定されます。

		.PARAMETER leftText
			進行状況の左側に表示されるテキストです。作業のステータスや詳細情報を記載します。

		.PARAMETER rightText
			進行状況の右側に表示されるテキストです。作業の進捗状況に関連する追加情報を表示します。

		.PARAMETER tag
			トースト通知のタグです。同じグループ内の通知を識別するために使用します。

		.PARAMETER group
			トースト通知のグループ名です。同じグループ内で通知を整理できます。

		.EXAMPLE
			Update-ProgressToast -rate "50" -leftText "データ処理中" -rightText "進捗: 50%" -tag "dataProcessing" -group "taskGroup"

			進行中のデータ処理の進捗を50%に更新するトースト通知を表示します。

		.EXAMPLE
			Update-ProgressToast -rate "75" -leftText "ファイルの書き込み" -rightText "進捗: 75%" -tag "fileWrite" -group "taskGroup"

			ファイルの書き込み進捗を75%に更新するトースト通知を表示します。
	#>
	[CmdletBinding()]
	[OutputType([Void])]
	Param (
		[Parameter(Mandatory = $false)][String]$title = '',
		[Parameter(Mandatory = $true )][String]$rate,
		[Parameter(Mandatory = $false)][String]$leftText = '',
		[Parameter(Mandatory = $false)][String]$rightText = '',
		[Parameter(Mandatory = $true )][String]$tag,
		[Parameter(Mandatory = $true )][String]$group
	)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	if (!$script:disableToastNotification) {
		switch ($true) {
			$IsWindows {
				$toastData = [System.Collections.Generic.Dictionary[String, String]]::new()
				$toastData.Add('progressTitle', $title) | Out-Null
				$toastData.Add('progressValue', $rate) | Out-Null
				$toastData.Add('progressValueString', $rightText) | Out-Null
				$toastData.Add('progressStatus', $leftText) | Out-Null
				$toastProgressData = [Windows.UI.Notifications.NotificationData]::new($toastData)
				$toastProgressData.SequenceNumber = 2
				[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($script:appID).Update($toastProgressData, $tag , $group) | Out-Null
				break
			}
			$IsLinux { break }
			$IsMacOS { break }
			default {}
		}
	}
	Remove-Variable -Name title, rate, leftText, rightText, tag, group, toastData, toastProgressData -ErrorAction SilentlyContinue
}

#----------------------------------------------------------------------
# 進捗表示(2行進捗バー)
#----------------------------------------------------------------------
function Show-ProgressToast2Row {
	<#
		.SYNOPSIS
			2行の進行状況を示すトースト通知を表示します。

		.DESCRIPTION
			この関数は、Windows、Linux、macOS プラットフォームで2行の進行状況を示すトースト通知を表示します。
			各行に異なる進行状況を表示でき、ユーザーは通知のメッセージ、進行状況の詳細、期間、および音の有無を制御できます。

		.PARAMETER text1
			トースト通知のメインテキストです。通常、処理が開始されたことや進行中のタスクに関する説明が表示されます。

		.PARAMETER text2
			オプションで、副次的なテキストです。追加の詳細情報などを表示するために使用します。

		.PARAMETER detail1
			1行目の進行状況の詳細情報です。進捗状況に関連する詳細な説明を表示します。

		.PARAMETER detail2
			2行目の進行状況の詳細情報です。進捗状況に関連する追加情報を表示します。

		.PARAMETER tag
			トースト通知のタグです。同じグループに属する通知を識別するために使用します。

		.PARAMETER duration
			通知の表示時間を指定します。「Short」または「Long」を選択できます。デフォルトは「Short」です。

		.PARAMETER silent
			音なしで通知を表示する場合は$trueを指定します。デフォルトは$falseで、音が鳴ります。

		.PARAMETER group
			トースト通知のグループ名です。同じグループ内で通知を整理できます。

		.EXAMPLE
			Show-ProgressToast2Row -text1 "処理中" -text2 "ファイルを読み込んでいます..." -detail1 "データのロード" -detail2 "進捗: 50%" -tag "fileLoad" -group "taskGroup" -duration "Long"

			長期間表示される2行の進行状況を示すトースト通知を表示します。

		.EXAMPLE
			Show-ProgressToast2Row -text1 "エラー発生" -silent $true -tag "errorTask" -group "errorGroup"

			音なしでエラー発生を通知する2行の進行状況トーストを表示します。
	#>
	[CmdletBinding()]
	[OutputType([Void])]
	Param (
		[Parameter(Mandatory = $true )][String]$text1,
		[Parameter(Mandatory = $false)][String]$text2 = '',
		[Parameter(Mandatory = $false)][String]$detail1 = '',
		[Parameter(Mandatory = $false)][String]$detail2 = '',
		[Parameter(Mandatory = $true )][String]$tag,
		[Parameter(Mandatory = $false)][ValidateSet('Short', 'Long')][String]$duration = 'Short',
		[Parameter(Mandatory = $false)][Boolean]$silent = $false,
		[Parameter(Mandatory = $true )][String]$group
	)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	if (!$script:disableToastNotification) {
		$text2 = $text2 ?? ''
		$detail1 = $detail1 ?? ''
		$detail2 = $detail2 ?? ''
		switch ($true) {
			$IsWindows {
				$toastSoundElement = if ($silent) { '<audio silent="true" />' } else { '<audio src="ms-winsoundevent:Notification.Default" loop="false"/>' }
				$duration = if (!$duration) { 'short' } else { $duration }
				$toastAttribution = ''
				$toastContent = @"
<?xml version="1.0" encoding="utf-8"?>
<toast duration="$duration">
	<visual>
		<binding template="ToastGeneric">
			<text>$script:appName</text>
			<text>$text1</text>
			<text>$text2</text>
			<image placement="appLogoOverride" src="$script:toastAppLogo"/>
			<progress value="{progressValue1}" title="{progressTitle1}" valueStringOverride="{progressValueString1}" status="{progressStatus1}" />
			<progress value="{progressValue2}" title="{progressTitle2}" valueStringOverride="{progressValueString2}" status="{progressStatus2}" />
			<text placement="attribution">$toastAttribution</text>
		</binding>
	</visual>
	$toastSoundElement
</toast>
"@
				$toastXML = [Windows.Data.Xml.Dom.XmlDocument]::new()
				$toastXML.LoadXml($toastContent)
				$toast = [Windows.UI.Notifications.ToastNotification]::new($toastXML)
				$toast.Tag = $tag
				$toast.Group = $group
				$toastData = [System.Collections.Generic.Dictionary[String, String]]::new()
				$toastData.Add('progressTitle1', $detail1) | Out-Null
				$toastData.Add('progressValue1', '') | Out-Null
				$toastData.Add('progressValueString1', '') | Out-Null
				$toastData.Add('progressStatus1', '') | Out-Null
				$toastData.Add('progressTitle2', $detail2) | Out-Null
				$toastData.Add('progressValue2', '') | Out-Null
				$toastData.Add('progressValueString2', '') | Out-Null
				$toastData.Add('progressStatus2', '') | Out-Null
				$toast.Data = [Windows.UI.Notifications.NotificationData]::new($toastData)
				$toast.Data.SequenceNumber = 1
				[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($script:appID).Show($toast) | Out-Null
				break
			}
			$IsLinux {
				if (Get-Command notify-send -ErrorAction SilentlyContinue) { & notify-send -a $script:appName -t 5000 -i $script:toastAppLogo $text1 $text2 2> /dev/null }
				break
			}
			$IsMacOS {
				if (Get-Command osascript -ErrorAction SilentlyContinue) {
					$toastParams = ('display notification "{0}" with title "{1}" subtitle "{2}" sound name "Blow"' -f $text2, $script:appName, $text1)
					$toastParams | & osascript
				}
				break
			}
			default {}
		}
	}
	Remove-Variable -Name text1, text2, detail1, detail2, tag, duration, silent, group, toastSoundElement, toastAttribution, toastContent, toastXML, toast, toastData, toastParams -ErrorAction SilentlyContinue
}

#----------------------------------------------------------------------
# 進捗更新(2行進捗バー)
#----------------------------------------------------------------------
function Update-ProgressToast2Row {
	<#
		.SYNOPSIS
			2行の進行状況を示すトースト通知を更新します。

		.DESCRIPTION
			この関数は、Windows プラットフォームで進行状況を更新するためのトースト通知を更新します。
			2行の進行状況を表示するトースト通知を動的に更新するために使用できます。進捗率や詳細情報を含めた通知を更新します。

		.PARAMETER title1
			1行目の進行状況のタイトルテキストです。進行中の作業のタイトルや説明を示します。

		.PARAMETER rate1
			1行目の進行状況の進捗率を指定します。通常は0〜100の範囲で指定されます。

		.PARAMETER leftText1
			1行目の進行状況の左側に表示されるテキストです。作業のステータスや詳細情報を記載します。

		.PARAMETER rightText1
			1行目の進行状況の右側に表示されるテキストです。進捗の詳細情報や完了までの残り時間を示します。

		.PARAMETER title2
			2行目の進行状況のタイトルテキストです。2番目の進行状況の作業や詳細を示します。

		.PARAMETER rate2
			2行目の進行状況の進捗率を指定します。通常は0〜100の範囲で指定されます。

		.PARAMETER leftText2
			2行目の進行状況の左側に表示されるテキストです。作業のステータスや詳細情報を記載します。

		.PARAMETER rightText2
			2行目の進行状況の右側に表示されるテキストです。進捗の詳細情報や完了までの残り時間を示します。

		.PARAMETER tag
			トースト通知のタグです。同じグループ内で通知を識別するために使用します。

		.PARAMETER group
			トースト通知のグループ名です。同じグループ内で通知を整理できます。

		.EXAMPLE
			Update-ProgressToast2Row -title1 "データ処理中" -rate1 "50" -leftText1 "処理中" -rightText1 "残り10分" -title2 "ファイル書き込み" -rate2 "75" -leftText2 "書き込み中" -rightText2 "残り5分" -tag "dataProcessing" -group "taskGroup"

			2行の進行状況を示すトースト通知を表示し、データ処理とファイル書き込みの進捗を更新します。

		.EXAMPLE
			Update-ProgressToast2Row -title1 "タスク1" -rate1 "25" -leftText1 "進行中" -rightText1 "残り15分" -title2 "タスク2" -rate2 "50" -leftText2 "進行中" -rightText2 "残り10分" -tag "taskGroup1" -group "group1"

			2つのタスクの進捗を更新するトースト通知を表示します。
	#>
	[CmdletBinding()]
	[OutputType([Void])]
	Param (
		[Parameter(Mandatory = $false)][String]$title1 = '',
		[Parameter(Mandatory = $true )][String]$rate1,
		[Parameter(Mandatory = $false)][String]$leftText1 = '',
		[Parameter(Mandatory = $false)][String]$rightText1 = '',
		[Parameter(Mandatory = $false)][String]$title2 = '',
		[Parameter(Mandatory = $true )][String]$rate2,
		[Parameter(Mandatory = $false)][String]$leftText2 = '',
		[Parameter(Mandatory = $false)][String]$rightText2 = '',
		[Parameter(Mandatory = $true )][String]$tag,
		[Parameter(Mandatory = $true )][String]$group
	)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	if (!($script:disableToastNotification)) {
		$rightText1 = switch ($rightText1 ) {
			'' { '' ; break }
			'0' { $script:msg.Completed ; break }
			default { ($script:msg.MinRemaining -f ([Int][Math]::Ceiling($rightText1 / 60))) }
		}
		$rightText2 = switch ($rightText2 ) {
			'' { '' ; break }
			'0' { $script:msg.Completed ; break }
			default { ($script:msg.MinRemaining -f ([Int][Math]::Ceiling($rightText2 / 60))) }
		}
		if (!$script:disableToastNotification) {
			switch ($true) {
				$IsWindows {
					$toastData = [System.Collections.Generic.Dictionary[String, String]]::new()
					$toastData.Add('progressTitle1', $title1) | Out-Null
					$toastData.Add('progressValue1', $rate1) | Out-Null
					$toastData.Add('progressValueString1', $rightText1) | Out-Null
					$toastData.Add('progressStatus1', $leftText1) | Out-Null
					$toastData.Add('progressTitle2', $title2) | Out-Null
					$toastData.Add('progressValue2', $rate2) | Out-Null
					$toastData.Add('progressValueString2', $rightText2) | Out-Null
					$toastData.Add('progressStatus2', $leftText2)
					$toastProgressData = [Windows.UI.Notifications.NotificationData]::new($toastData)
					$toastProgressData.SequenceNumber = 2
					[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($script:appID).Update($toastProgressData, $tag , $group) | Out-Null
					break
				}
				$IsLinux { break }
				$IsMacOS { break }
				default {}
			}
		}
	}
	Remove-Variable -Name title1, rate1, leftText1, rightText1, title2, rate2, leftText2, rightText2, tag, group, toastData, toastProgressData -ErrorAction SilentlyContinue
}
#endregion トースト通知

#----------------------------------------------------------------------
# Base64画像の展開
#----------------------------------------------------------------------
function ConvertFrom-Base64 {
	<#
		.SYNOPSIS
			Base64エンコードされた文字列を画像に変換します。

		.DESCRIPTION
			この関数は、Base64形式でエンコードされた文字列を受け取り、その文字列を画像オブジェクトに変換します。
			主に画像データをBase64でエンコードして保存し、後でそのデータを画像として表示したい場合に使用されます。

		.PARAMETER base64
			Base64形式でエンコードされた文字列です。この文字列は画像のデータを表しており、通常は長い文字列になります。

		.OUTPUTS
			この関数は、変換された画像オブジェクト（`System.Windows.Media.Imaging.BitmapImage`）を返します。

		.EXAMPLE
			$base64String = "iVBORw0KGgoAAAANSUhEUgAAA..."
			$image = ConvertFrom-Base64 -base64 $base64String
			$image  # 画像オブジェクトが返されます。

			Base64エンコードされた文字列を画像オブジェクトに変換して表示する例です。
	#>
	Param (
		[Parameter(Mandatory = $true)][String]$base64
	)
	Write-Debug ('{0}' -f $MyInvocation.MyCommand.Name)
	try {
		$img = [System.Windows.Media.Imaging.BitmapImage]::new()
		$img.BeginInit()
		$img.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($base64)
		$img.EndInit()
		$img.Freeze()
		return $img
	} catch { Write-Error "Base64文字列から画像を変換する際にエラーが発生しました: $_" ; return $null }
	finally { Remove-Variable -Name base64, img -ErrorAction SilentlyContinue }
}
