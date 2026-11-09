#!/usr/bin/env bash
# 本番DB(primary)をダンプして、S3のDeep Archiveへアップロードする。
#
# 必須の環境変数(DRY_RUN=1 のときは不要):
#   S3_BUCKET        アップロード先のバケット名
#   HEALTHCHECK_URL  成功を知らせるhealthchecks.ioのPing URL
# 任意の環境変数:
#   DB_CONTAINER     DBのコンテナ名 (既定: illustration-portal-db)
#   DB_NAME          DB名 (既定: illustration_portal_production)
#   DB_USER          DBユーザー (既定: illustration_portal)
#   BACKUP_TMP_DIR   ダンプの一時置き場 (既定: /var/tmp)
#   DRY_RUN          1 ならダンプの確認までで止める(アップロードと通知はしない)
set -euo pipefail

DB_CONTAINER="${DB_CONTAINER:-illustration-portal-db}"
DB_NAME="${DB_NAME:-illustration_portal_production}"
DB_USER="${DB_USER:-illustration_portal}"
BACKUP_TMP_DIR="${BACKUP_TMP_DIR:-/var/tmp}"
DRY_RUN="${DRY_RUN:-0}"

# 設定漏れは、ダンプを作る前に止める
if [[ "$DRY_RUN" != "1" ]]; then
  : "${S3_BUCKET:?S3_BUCKET を設定してください}"
  : "${HEALTHCHECK_URL:?HEALTHCHECK_URL を設定してください}"
fi

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
dump_file="$(mktemp "${BACKUP_TMP_DIR}/${DB_NAME}.XXXXXX")"
# 成功・失敗どちらでも、ダンプの一時ファイルを必ず消す
trap 'rm -f "$dump_file"' EXIT

echo "ダンプを作成します: ${DB_NAME} (コンテナ: ${DB_CONTAINER})"
docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" -Fc "$DB_NAME" > "$dump_file"

# ダンプが壊れていないかを、コンテナ内の pg_restore で中身の一覧を読んで確認する
docker exec -i "$DB_CONTAINER" pg_restore --list < "$dump_file" > /dev/null
echo "ダンプの検証に成功しました ($(wc -c < "$dump_file") bytes)"

if [[ "$DRY_RUN" == "1" ]]; then
  echo "DRY_RUN=1 のため、アップロードと通知をスキップしました"
  exit 0
fi

object_key="db/${DB_NAME}-${timestamp}.dump"
echo "アップロードします: s3://${S3_BUCKET}/${object_key}"
aws s3 cp "$dump_file" "s3://${S3_BUCKET}/${object_key}" \
  --storage-class DEEP_ARCHIVE --sse AES256 --only-show-errors

# 成功の連絡が途切れたら、healthchecks.io がメールで知らせてくれる
curl -fsS -m 10 --retry 3 -o /dev/null "$HEALTHCHECK_URL"
echo "完了しました"
