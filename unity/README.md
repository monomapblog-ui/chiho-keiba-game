# Unity版 セットアップ手順

地方競馬ジョッキーアクションのUnity(3D)版です。VS BOAT( https://vsboat.app )のような
3D・セルシェーディングのレース表現を将来的に目指す前提で、まずは3Dの土台(カメラ・
操作・レースロジック)だけを動かす最初の一歩です。**見た目はまだ仮の直方体**で、
本物の3Dモデルへの差し替えは別工程です。

このフォルダには、Unityプロジェクトの `Assets/Scripts/` に入れるC#ファイルだけが
入っています(Unity本体のプロジェクトファイル一式はUnity Hubで作る必要があるため)。

## 1. Unity Hub / Unity Editorのインストール

1. [unity.com](https://unity.com/download) からUnity Hubをダウンロード・インストール
2. Unity Hubを起動し、Unityアカウントでログイン(無料のPersonalプランでOK)
3. Unity Hubの「インストール」タブから **Unity 6 LTS(6.3系)** をインストール

## 2. 新規プロジェクト作成

1. Unity Hubの「プロジェクト」タブ →「新規プロジェクト」
2. テンプレートは **「3D (URP)」** を選択(セルシェーディング等を将来やりやすくするため)
3. プロジェクト名は自由(例: `ChihoKeibaGame3D`)、保存場所も自由(どこでもよい)
4. 作成してエディタが開くまで待つ

## 3. スクリプトを配置

1. Unityエディタ左下の「Project」ウィンドウで `Assets` フォルダを右クリック →
   「Create」→「Folder」で `Scripts` フォルダを作成
2. このリポジトリの `unity/Scripts/` フォルダの中身(`.cs`ファイル6個)を、
   Finderから `Assets/Scripts/` フォルダへドラッグ&ドロップでコピー
   (Unityエディタが自動的に取り込みます)

## 4. シーンを組み立てる

1. 「Hierarchy」ウィンドウで右クリック →「Create Empty」で空のGameObjectを作成
2. 名前を `RaceBootstrap` などに変更
3. それを選択した状態で「Inspector」ウィンドウの「Add Component」→
   `RaceBootstrap` を検索して追加
4. 画面上部の再生ボタン(▶)を押す

これで、ダート色の地面の上を色付きの箱(プレイヤー=赤)が走るはずです。
操作は ↑/W(押す)、↓/S(抑える)、←→ or A/D(レーン変更) です。

## 既知の注意点

- **見た目は仮**: 直方体のプレースホルダーです。本物の3Dモデル(馬・騎手)への
  差し替えは別途行います。無料の3Dモデル素材の候補として
  [Quaternius Ultimate Animated Animal Pack](https://quaternius.com/packs/ultimateanimatedanimals.html)
  (CC0、商用利用可)を調査済みです。ダウンロードがGoogleドライブ経由のため、
  お手数ですがご自身でダウンロードしてプロジェクトにドラッグ&ドロップしてみてください。
- **マテリアルがピンク色になる場合**: URPプロジェクトでBuilt-inシェーダーを使うと
  ピンク色(エラー表示)になることがあります。`RaceBootstrap.cs`内の
  `MakeColorMaterial()`でURP用シェーダーを優先的に探すようにしていますが、
  もしピンクになる場合は教えてください。
- **日本語が表示されない場合**: UnityのデフォルトGUIフォントは日本語(CJK)に
  対応していないことがあります。文字が四角や空白になる場合は、Unity側の
  フォント設定の問題なので、教えてください。
- **キー入力が効かない場合**: 「Edit」→「Project Settings」→「Player」→
  「Active Input Handling」が `Input Manager (Old)` または `Both` に
  なっているか確認してください(`Input System Package (New)` のみだと動きません)。

## 動いたら

一度動作確認できたら、このUnityプロジェクトのフォルダ全体(`Assets`、
`ProjectSettings`、`Packages` など)をこのgitリポジトリに追加してコミット・
プッシュしてください(方法が分からなければ聞いてください)。それ以降はgit経由で
やり取りしながら進められます。
