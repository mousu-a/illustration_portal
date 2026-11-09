# DBバックアップ手順書 (S3 Glacier Deep Archive)

本番DB(PostgreSQL 18)を毎日ダンプして、S3の Deep Archive(一番安い長期保管)に置く仕組みの設置・確認・復元の手順書です。

```
[Lightsail VPS]                                      [AWS]
 systemd timer (毎日 日本時間3:00)
   -> /usr/local/bin/backup_db.sh
        1. docker exec ... pg_dump -Fc   -> /var/tmp に .dump ができる
        2. docker exec ... pg_restore --list  -> ダンプが壊れていないか確認
        3. aws s3 cp --storage-class DEEP_ARCHIVE -> S3バケットの db/ へ
        4. 一時ファイルを削除
        5. healthchecks.io に成功を連絡
                                                     S3ライフサイクル: db/ 配下を180日で削除
```

## このフォルダのファイル

| ファイル | 役割 | 置き場所 |
|---|---|---|
| `backup_db.sh` | バックアップ本体 | VPSの `/usr/local/bin/backup_db.sh` |
| `systemd/db-backup.service` | スクリプトを1回動かす設定 | VPSの `/etc/systemd/system/` |
| `systemd/db-backup.timer` | 毎日 日本時間3:00 に動かす設定 | VPSの `/etc/systemd/system/` |
| `s3/backup-iam-policy.json` | アップロード専用IAMポリシー | AWSコンソールで貼り付け |
| `s3/lifecycle.json` | 180日で削除するルール | S3バケットに設定 |

## 1. AWS側の準備 (管理者権限でAWSコンソールを操作)

### 1-1. S3バケットを作る
- 名前空間: アカウントリージョナル(Account regional namespace)を選び、接頭辞に `illustration-portal-db-backup` を入力する(画面の表記は変わることがあります)
  - 自分のAWSアカウント専用の名前の領域です。AWS公式が「セキュリティのベストプラクティス」としている方法で、他のアカウントに同じ名前を取られたり、削除後に取られたりしません([公式ドキュメント](https://docs.aws.amazon.com/AmazonS3/latest/userguide/gpbucketnamespaces.html))。
  - 後半は自動でつきます: `-<12桁のAWSアカウントID>-ap-northeast-1-an`
  - 完成する名前の例: `illustration-portal-db-backup-123456789012-ap-northeast-1-an`
  - 以下の `<バケット名>` は、後半まで含めた**完成した名前**のことです(作成後にバケット一覧で確認できます)。
- リージョン: アジアパシフィック(東京) `ap-northeast-1`
- 「パブリックアクセスをすべてブロック」をオンのままにする
- バージョニングは無効のままにする(有効にすると、180日で消したはずのファイルが残ってしまいます)
- デフォルトの暗号化は SSE-S3(初期値のまま)

### 1-2. ライフサイクルルールを設定する (180日で削除)
`s3/lifecycle.json` の内容を設定します。AWS CLIを管理者権限で使える場合は、次の1行です。

```bash
aws s3api put-bucket-lifecycle-configuration --bucket <バケット名> --lifecycle-configuration file://script/s3/lifecycle.json
```

- `db/` 配下のファイルを、作成から180日で削除します。
- 180日にした理由: Deep Archive には最低保管期間180日があり、それより早く消しても180日分の料金がかかる(短くしても安くならない)ためです。
- 「7日たった未完了のアップロードを削除」も入っています。大きいファイルは分割してアップロードされ、途中で失敗すると残骸が残るためです。アップロード専用の鍵には掃除の権限(`s3:AbortMultipartUpload`)を付けないので、S3側で自動で掃除します。

### 1-3. アップロード専用のIAMポリシーを作る
1. `s3/backup-iam-policy.json` を開き、`YOUR_BUCKET_NAME` を `<バケット名>` に書き換えた内容を、IAMの「ポリシーを作成」(JSONタブ)に貼ります(このファイル自体は書き換えず、コンソールに貼る内容だけ書き換えます)。
2. ポリシー名は `illustration-portal-db-backup-upload`。

このポリシーは `db/` 配下への書き込み(`s3:PutObject`)だけを許可します。VPSが乗っ取られても、過去のバックアップは読めないし消せません。

### 1-4. IAMユーザーとアクセスキーを作る
1. IAMユーザー `illustration-portal-db-backup` を作る(コンソールへのアクセスは不要)
2. 1-3のポリシーをアタッチする
3. 「アクセスキーを作成」(ユースケース: AWS外で実行されるアプリケーション)
4. **シークレットアクセスキーはこの画面でしか見られません。** `/etc/db-backup.env`(3-2)に貼るまで画面を閉じないでください。

## 2. healthchecks.io の準備

1. アカウントを作り、チェックを1つ作る(名前: `illustration-portal-db-backup`)
2. Period(期間)を `1 day`、Grace Time(猶予)を `2 hours` にする
3. 通知先にメールを設定する
4. 表示される Ping URL(`https://hc-ping.com/...`)を控える

毎日の成功連絡が、期間+猶予を過ぎても届かないとメールが来ます。

## 3. VPSへの設置

VPSには `ssh ubuntu@52.196.110.227` で入ります。

### 3-1. AWS CLIを入れる (VPS)
```bash
sudo snap install aws-cli --classic
aws --version
```

### 3-2. 設定ファイルを作る (VPS)
鍵が入るので、自分(root)だけが読める権限で作ります。

```bash
sudo install -m 600 /dev/null /etc/db-backup.env
sudo nano /etc/db-backup.env
```

中身(`<...>` を実際の値に置き換える。`=` の前後に空白や引用符をつけない):

```
S3_BUCKET=<バケット名>
HEALTHCHECK_URL=<healthchecks.ioのPing URL>
AWS_ACCESS_KEY_ID=<1-4のアクセスキーID>
AWS_SECRET_ACCESS_KEY=<1-4のシークレットアクセスキー>
AWS_DEFAULT_REGION=ap-northeast-1
```

### 3-3. ファイルをVPSに置く
手元のMacで、リポジトリのルートから:

```bash
scp script/backup_db.sh script/systemd/db-backup.service script/systemd/db-backup.timer ubuntu@52.196.110.227:/tmp/
```

VPSで:

```bash
sudo install -m 755 /tmp/backup_db.sh /usr/local/bin/backup_db.sh
sudo install -m 644 /tmp/db-backup.service /tmp/db-backup.timer /etc/systemd/system/
sudo systemctl daemon-reload
```

### 3-4. まず安全なお試し (VPS)
アップロードも通知もせず、ダンプが作れて検証できるところまでを確認します。

```bash
sudo env DRY_RUN=1 /usr/local/bin/backup_db.sh
```

「ダンプの検証に成功しました」と出れば成功です。

### 3-5. 本番の手動実行 (VPS)
```bash
sudo systemctl start db-backup.service
sudo journalctl -u db-backup -n 30 --no-pager
```

「完了しました」が出て、`systemctl start` がエラーにならなければ成功です。

### 3-6. タイマーを有効にする (VPS)
```bash
sudo systemctl enable --now db-backup.timer
systemctl list-timers db-backup.timer
```

`NEXT` に、次の UTC 18:00(日本時間 3:00)が出ていることを確認します。

## 4. 動作確認のチェックリスト

- [ ] `journalctl -u db-backup` に「完了しました」が出ている
- [ ] S3にファイルがあり、保管クラスが `DEEP_ARCHIVE` (管理者権限で):
  ```bash
  aws s3api list-objects-v2 --bucket <バケット名> --prefix db/ --query 'Contents[].[Key,Size,StorageClass]' --output table
  ```
- [ ] healthchecks.io のチェックが緑(Up)になった
- [ ] アップロード専用になっている。VPSで次の2つがどちらも `AccessDenied` になること:
  ```bash
  sudo bash -c 'set -a; source /etc/db-backup.env; set +a; aws s3 ls "s3://$S3_BUCKET/"'
  sudo bash -c 'set -a; source /etc/db-backup.env; set +a; aws s3 rm "s3://$S3_BUCKET/db/(実在するファイル名)"'
  ```

## 5. 復元手順 (本番DBが壊れたとき)

Deep Archive のファイルは、すぐには読めません。先に「取り出し依頼」を出して、待つ必要があります。

### 5-1. 取り出し依頼 (管理者権限)
戻したい日付のファイル名を `aws s3 ls s3://<バケット名>/db/` で探して、依頼します。

```bash
aws s3api restore-object --bucket <バケット名> --key db/<ファイル名>.dump \
  --restore-request '{"Days":7,"GlacierJobParameters":{"Tier":"Bulk"}}'
```

- `Bulk`: 約48時間、安い。`Standard`: 約12時間、少し高い。急ぐときは `Standard`。
- `Days`: 取り出したファイルを読める日数。

### 5-2. 取り出し完了を確認する
次の結果に `ongoing-request="false"` が出れば、ダウンロードできます。

```bash
aws s3api head-object --bucket <バケット名> --key db/<ファイル名>.dump
```

### 5-3. ダウンロードしてVPSに送る
```bash
aws s3 cp s3://<バケット名>/db/<ファイル名>.dump .
scp <ファイル名>.dump ubuntu@52.196.110.227:~/
```

### 5-4. DBに戻す
次の順番で進めます。どこかでエラーが出たら、そこで止めて、次へ進まないでください。

**1. アプリを止める** (手元のMac、リポジトリのルート)

```bash
bin/kamal app stop
```

**2. バックアップのタイマーを止める** (VPS)

復元の途中でバックアップが走ると、半分しか戻っていないDBを「成功」として保存してしまいます。先にタイマーを止めて、バックアップが動いていないことを確かめます。

```bash
sudo systemctl stop db-backup.timer

# inactive と表示されればOK (activating のときはバックアップ中なので、終わるまで待つ)
systemctl is-active db-backup.service
```

**3. 今のDBを退避する** (VPS)

アプリを止めた後に取るので、最後に書き込まれたデータまで入ります。

```bash
docker exec illustration-portal-db pg_dump -U illustration_portal -Fc illustration_portal_production > ~/before_restore.dump
```

**4. DBを作り直す** (VPS)

今のDBの上に重ねて戻すと、バックアップの後に増えたテーブルが残り、新旧のデータが混ざることがあります。空のDBに戻すために、いったん消して作り直します。

```bash
docker exec illustration-portal-db dropdb -U illustration_portal illustration_portal_production
docker exec illustration-portal-db createdb -U illustration_portal illustration_portal_production
```

**5. バックアップを戻す** (VPS)

```bash
docker exec -i illustration-portal-db pg_restore -U illustration_portal -d illustration_portal_production --no-owner --exit-on-error < ~/<ファイル名>.dump && echo "復元OK"
```

- `--exit-on-error`: 最初のエラーで止まります (付けないと、エラーが出ても最後まで進みます)
- `復元OK` と表示されなければ失敗です。手順6へ進まないでください。手順4〜5を `~/<ファイル名>.dump` の代わりに `~/before_restore.dump` で行えば、復元前の状態に戻せます

**6. 中身を確認して、タイマーを戻し、アプリを起動する**

```bash
# VPS
docker exec illustration-portal-db psql -U illustration_portal -d illustration_portal_production -c 'select count(*) from users'
sudo systemctl start db-backup.timer

# 手元のMac
bin/kamal app boot
```

タイマーを止めている間に3:00を過ぎていた場合は、`start` の直後にバックアップが1回走ります。

`_cache` / `_queue` のDBは作り直せるので、バックアップの対象外です。

## 6. 復元訓練 (数か月に1回)

バックアップは「戻せて」はじめて意味があります。取り出し依頼(5-1〜5-3)をして、手元のDockerで中身を確認します。

```bash
docker run -d --name restore-check \
  -e POSTGRES_USER=illustration_portal -e POSTGRES_DB=illustration_portal_production -e POSTGRES_PASSWORD=pw \
  postgres:18

# 起動に数秒かかるので、少し待ってから
docker exec -i restore-check pg_restore -U illustration_portal -d illustration_portal_production --no-owner < <ファイル名>.dump
docker exec restore-check psql -U illustration_portal -d illustration_portal_production -c 'select count(*) from users'

docker rm -f restore-check
```

## 7. 費用の目安

東京リージョンで、毎日・180日保管した場合の月額の目安です(1ドル=160円)。

| 想定 | 1回のダンプ | 月額 |
|---|---|---|
| 100人 x 500件 | 約22MB | 約2円 |
| 1,000人 x 1,000件 | 約435MB | 約25円 |

ダンプは圧縮されるので、実際はこれより小さくなります。取り出し(復元)の費用は、22MBなら1円未満です。

## 8. うまくいかないとき

- ログを見る: `sudo journalctl -u db-backup -n 100 --no-pager`
- `aws: command not found`: `db-backup.service` の `Environment=PATH=...` に `/snap/bin` が入っているか確認する
- `docker: permission denied`: このサービスは root で動くので、`sudo` で手動実行して切り分ける
- healthchecks.io からメールが来た: まず手動で `sudo systemctl start db-backup.service` を実行し、ログを見る
