@echo off
:: Supabase DNS 优化 — 添加 hosts 条目绕过 DNS 污染
:: 右键 → 以管理员身份运行

set HOSTS_FILE=C:\Windows\System32\drivers\etc\hosts
set ENTRY=104.18.38.10 uqaggeaiqcmsxkikyfvl.supabase.co
set ENTRY2=172.64.149.246 uqaggeaiqcmsxkikyfvl.supabase.co

echo ========================================
echo   订单管理系统 — Supabase 网络优化
echo ========================================
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 请右键 → 以管理员身份运行此脚本
    pause
    exit /b 1
)

:: 备份原 hosts
echo [1/3] 备份 hosts 文件...
copy "%HOSTS_FILE%" "%HOSTS_FILE%.backup_%date:~0,10%" >nul

:: 移除旧条目
echo [2/3] 更新 hosts 条目...
powershell -Command "(Get-Content '%HOSTS_FILE%') -notmatch 'uqaggeaiqcmsxkikyfvl.supabase.co' | Set-Content '%HOSTS_FILE%'"

:: 添加新条目
echo.>> "%HOSTS_FILE%"
echo # order-manager: Supabase DNS fix>> "%HOSTS_FILE%"
echo %ENTRY%>> "%HOSTS_FILE%"
echo %ENTRY2%>> "%HOSTS_FILE%"

:: 刷新 DNS 缓存
echo [3/3] 刷新 DNS 缓存...
ipconfig /flushdns >nul

echo.
echo ========================================
echo   完成！Supabase 已通过 hosts 文件优化
echo   备份文件: %HOSTS_FILE%.backup
echo ========================================
echo.
pause
