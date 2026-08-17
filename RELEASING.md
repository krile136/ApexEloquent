# Releasing ApexEloquent (メンテナ向け)

unlocked package のリリース手順。DevHub は **developer-dist** (krile136cm+ossdevhub@... 個人 Gmail 紐付け)。

1. `sfdx-project.json` の `versionNumber` を上げる (git タグと同じ semver + `.NEXT`)
2. バージョン作成 (**必ず edition 抜きの def を使う** — 下記の罠):
   ```bash
   sf package version create -p ApexEloquent --installation-key-bypass --code-coverage \
     --definition-file config/no-edition-def.json --wait 60 -v developer-dist
   ```
3. promote (取り消し不可。これが正式リリース):
   ```bash
   sf package version promote -p <04t...> -v developer-dist --no-prompt
   ```
4. 同じ semver で git tag を打ち、GitHub Release を作成。**Release ノートに install コマンドと
   login/test 両方の install URL を記載する**
5. README の Current version と 04t ID を更新
6. krileworks.com のインストールページのバージョン表を更新

## ⚠️ 罠

- **config/no-edition-def.json に edition を書かない**。orgfarm 製 (Agentforce) DevHub では検証ビルド org が
  シェイプコピーで作られるため、edition を書くと「シェイプ + edition 二重指定」で失敗する
  (エラー: You can't specify an edition when copying an org shape)
- 逆に手動の `sf org create scratch` は edition **必須** (`config/project-scratch-def.json` を使う)
- 検証付き version create は **失敗しても日次6回の枠を消費する**。実験は `--skip-validation` (500/日) で
- `sf package create` は sfdx-project.json の packageDirectories を上書きするので、実行後に要復元
