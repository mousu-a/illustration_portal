# illustration_portal
絵師ぽ！

## Googleログインの設定（ローカル開発）

1. プロジェクト直下に `.env` を作り、次の2つのキーを書く（`.env` は git 管理されない）

   ```
   GOOGLE_CLIENT_ID=
   GOOGLE_CLIENT_SECRET=
   ```

2. Google Cloud Console で OAuth クライアントIDを作成し、1 の `=` の右側に値を入れる
   - 承認済みのリダイレクトURIには `http://localhost:3000/auth/google_oauth2/callback` を登録する
3. `bin/dev` でアプリを起動する

未設定のまま起動すると、開発環境では警告が表示され、本番環境では起動に失敗します。
