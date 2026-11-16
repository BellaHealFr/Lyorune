@echo off
rem Copie Zenith dans le dossier AddOns de WoW Forever. Tapez /reload en jeu ensuite.
set "SRC=%~dp0.."
set "DST=D:\Program Files\World of Warcraft\_forever_\Interface\AddOns\Zenith"
if not exist "%DST%\Locales" mkdir "%DST%\Locales"
del /q "%DST%\*.lua" "%DST%\*.toc" "%DST%\Locales\*.lua" 2>nul
copy /y "%SRC%\*.lua" "%DST%\" >nul
copy /y "%SRC%\Locales\*.lua" "%DST%\Locales\" >nul
copy /y "%SRC%\Zenith.toc" "%DST%\" >nul
echo Zenith installe dans %DST%
pause
