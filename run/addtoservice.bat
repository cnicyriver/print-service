@echo off
setlocal EnableDelayedExpansion

:: 服务名称
set ServerName=NodeServerDfl3
:: 要定义成服务的脚本
set file=run.bat

set root=%~dp0

echo 正在注册服务：%ServerName% 
%root%\instsrv.exe %ServerName% %root%srvany.exe


set basePath=HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%ServerName%

reg add %basePath%\Parameters /v Application /t reg_sz /d "%root%%file%" /f


echo 注册服务成功

set /p choice=是否开启服务？(y,n)
if %choice%==n exit:
net start %ServerName%
pause