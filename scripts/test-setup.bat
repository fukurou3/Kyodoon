@echo off
REM Kyodoon セキュリティテスト セットアップスクリプト (Windows)

echo 🔧 Kyodoon セキュリティテスト環境のセットアップを開始します...

REM プロジェクトルートに移動
cd /d "%~dp0\.."

echo 📦 Cloud Functions の依存関係をインストール中...
cd functions
call npm install
cd ..

echo 🏗️ Cloud Functions をビルド中...
cd functions
call npm run build
cd ..

echo 🔍 リンティングチェック実行中...
cd functions
call npm run lint
cd ..

echo 🚀 Firebase Emulators について...
echo 注意: エミュレータは別のコマンドプロンプトで起動してください:
echo firebase emulators:start --only functions,firestore,auth,storage

echo.
echo ⏳ エミュレータが起動したら、以下のコマンドでテストを実行してください:
echo.
echo 📋 テストコマンド:
echo   - 全てのテスト実行: cd functions ^&^& npm test
echo   - セキュリティテストのみ: cd functions ^&^& npm run test:security
echo   - エミュレータUI: http://localhost:4000
echo.
echo ✅ セットアップが完了しました！

pause