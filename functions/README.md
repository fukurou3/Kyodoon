# Kyodoon Cloud Functions

## 概要
KyodoonアプリケーションのCloud Functions実装です。セキュアな通知システムと管理者機能を提供します。

## 機能

### 1. 通知システム
- **createNotification**: セキュアなクロスユーザー通知作成
- **cleanupOldNotifications**: 古い通知の自動削除（毎日実行）
- **updateNotificationStats**: 通知統計の自動更新
- **onNotificationRead**: 既読時の統計更新

### 2. 管理者機能
- **createSystemNotification**: システム通知の作成
- **deleteNotificationsByAdmin**: 管理者による通知削除

## セキュリティ機能

### 権限検証
- リソースベースの権限確認（投稿、いいね、コメント等）
- ブロック関係の確認
- レート制限（1分間に10通知まで）

### 監査ログ
- セキュリティ違反の記録
- 管理者操作の監査
- エラーログの詳細記録

## セットアップ

### 1. 依存関係のインストール
```bash
cd functions
npm install
```

### 2. ビルド
```bash
npm run build
```

### 3. ローカル開発
```bash
# エミュレータ起動
npm run serve

# 関数シェル
npm run shell
```

### 4. デプロイ
```bash
npm run deploy
```

### 5. リンティング
```bash
npm run lint
```

## テスト

### セキュリティテスト実行
```bash
npm run test:security
```

### 全テスト実行
```bash
npm test
```

## エミュレータ設定

Firebase Emulator Suiteを使用したローカル開発：

```bash
firebase emulators:start --only functions,firestore,auth
```

## 環境変数

以下の環境変数が必要です：
- Firebase Admin SDK設定（自動設定）
- プロジェクト固有の設定（firebase.json経由）

## ディレクトリ構造

```
functions/
├── src/
│   ├── index.ts          # メイン関数
│   └── admin_functions.ts # 管理者専用関数
├── lib/                  # ビルド済みファイル（git無視）
├── package.json          # 依存関係
├── tsconfig.json         # TypeScript設定
├── .eslintrc.js         # ESLint設定
└── README.md            # このファイル
```

## セキュリティ考慮事項

1. **認証**: 全ての関数で認証必須
2. **権限**: リソースベースの厳格な権限確認
3. **レート制限**: スパム防止機能
4. **監査**: 全操作の詳細ログ記録
5. **エラー処理**: セキュアなエラーハンドリング

## トラブルシューティング

### よくある問題

1. **TypeScriptコンパイルエラー**
   ```bash
   npm run build
   ```

2. **ESLintエラー**
   ```bash
   npm run lint
   ```

3. **Firebase権限エラー**
   - Firebase CLIでログイン確認
   - プロジェクト設定確認

### ログの確認
```bash
npm run logs
```

## 開発ガイドライン

1. **セキュリティファースト**: 全ての機能でセキュリティを最優先
2. **監査ログ**: 重要な操作は必ずログ記録
3. **エラーハンドリング**: 適切なエラーメッセージとログ
4. **テスト**: セキュリティテストを含む包括的なテスト
5. **ドキュメント**: 機能変更時は必ずドキュメント更新