@echo off
setlocal EnableDelayedExpansion

:: ��������
set ServerName=NodeServerDfl3
:: Ҫ����ɷ���Ľű�
set file=run.bat

set root=%~dp0

echo ����ע�����%ServerName% 
%root%\instsrv.exe %ServerName% %root%srvany.exe


set basePath=HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%ServerName%

reg add %basePath%\Parameters /v Application /t reg_sz /d "%root%%file%" /f


echo ע�����ɹ�

set /p choice=�Ƿ�������(y,n)
if %choice%==n exit:
net start %ServerName%
pause