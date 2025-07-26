#!/bin/bash

# Kyodoon セキュリティテスト セットアップスクリプト

set -e

echo "🔧 Kyodoon セキュリティテスト環境のセットアップを開始します..."

# プロジェクトルートに移動
cd "$(dirname "$0")/.."

echo "📦 Cloud Functions の依存関係をインストール中..."
cd functions
npm install
cd ..

echo "🏗️ Cloud Functions をビルド中..."
cd functions
npm run build
cd ..

echo "🔍 リンティングチェック実行中..."
cd functions
npm run lint
cd ..

echo "🚀 Firebase Emulators を起動中..."
echo "注意: エミュレータは別のターミナルで起動してください:"
echo "firebase emulators:start --only functions,firestore,auth,storage"

echo "⏳ エミュレータの起動を待機中... (10秒)"
sleep 10

echo "🧪 セキュリティテストを実行中..."
cd functions
npm run test:security
cd ..

echo "✅ セットアップとテストが完了しました！"
echo ""
echo "📋 追加のテストコマンド:"
echo "  - 全てのテスト実行: cd functions && npm test"
echo "  - セキュリティテストのみ: cd functions && npm run test:security"
echo "  - エミュレータUI: http://localhost:4000"
echo ""
echo "🔐 セキュリティ機能が正常に動作しています。"