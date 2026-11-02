@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ============================================
echo   FishCRM 一键上传 GitHub 工具
echo ============================================

:: 1. 检查 Git
where git >nul 2>&1
if errorlevel 1 (
    echo [错误] 未检测到 Git，请先安装 Git for Windows
    pause
    exit /b 1
)

:: 2. 自动生成防爆仓 .gitignore
(
echo node_modules/
echo dist/
echo .jdk/
echo android/.gradle/
echo android/.kotlin/
echo android/app/build/
echo android/build/
echo android/local.properties
echo android/app/src/main/assets/public
echo android/capacitor-cordova-android-plugins
echo *.apk
echo *.aab
echo .screenshots/
echo .trae-html-share-packages/
) > .gitignore

:: 3. 初始化仓库并补齐首次提交身份
if not exist ".git" (
    git init
    git branch -M main
)
set GIT_USER=
for /f "delims=" %%i in ('git config user.name 2^>nul') do set GIT_USER=%%i
if not defined GIT_USER (
    git config user.name "FishCRM-Developer"
    git config user.email "fishcrm@users.noreply.github.com"
)

:: 4. 把可能误加的巨型目录移出暂存区
git rm -r --cached node_modules .jdk dist android/.gradle android/app/build >nul 2>&1

:: 5. 检查是否已绑定 GitHub 仓库
set REMOTE_URL=
for /f "delims=" %%i in ('git remote get-url origin 2^>nul') do set REMOTE_URL=%%i
if defined REMOTE_URL goto remote_ok
echo.
set /p INPUT_URL=请粘贴 GitHub 仓库地址（例如 https://github.com/xxx/FishCRM.git）: 
if not defined INPUT_URL goto no_url
git remote add origin "%INPUT_URL%"
if errorlevel 1 goto remote_fail
:remote_ok

:: 6. 打包源码并提交
echo.
echo 正在扫描并打包源码（已自动过滤 node_modules 与 .jdk）...
git add -A >nul 2>&1
if errorlevel 1 goto add_fail
git branch -M main
git commit -m "backup: FishCRM 自动同步备份 (%date% %time%)" >nul 2>&1

:: 7. 推送到 GitHub
echo.
echo 正在上传到 GitHub（若弹出登录窗口请完成授权）...
git push -u origin main
if not errorlevel 1 goto push_ok

echo.
echo [提示] 直接推送失败，尝试合并远端已有内容后重试...
git pull origin main --allow-unrelated-histories --no-edit
git push -u origin main
if not errorlevel 1 goto push_ok

echo.
echo [失败] 上传未完成，常见原因：
echo   1. 未登录 GitHub 或授权被取消
echo   2. 仓库地址错误或没有写入权限
echo   3. 远端存在冲突内容，需要先手动 git pull
echo 请把上方报错信息发给开发者。
pause
exit /b 1

:push_ok
echo.
echo [完成] 已成功上传到 GitHub
pause
exit /b 0

:no_url
echo [错误] 未填写仓库地址，已退出。
pause
exit /b 1

:remote_fail
echo [错误] 仓库地址无效，添加远端失败。
pause
exit /b 1

:add_fail
echo [错误] 暂存文件失败，请检查文件权限。
pause
exit /b 1
