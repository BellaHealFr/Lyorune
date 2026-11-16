@echo off
rem Copie Lyorune dans le dossier AddOns de WoW Forever. Tapez /reload en jeu ensuite.
set "SRC=%~dp0.."
set "ADDONS=D:\Program Files\World of Warcraft\_forever_\Interface\AddOns"
set "DST=%ADDONS%\Lyorune"
if not exist "%DST%\Locales" mkdir "%DST%\Locales"
if not exist "%DST%\Media" mkdir "%DST%\Media"
del /q "%DST%\*.lua" "%DST%\*.toc" "%DST%\Locales\*.lua" "%DST%\Media\*.tga" 2>nul
copy /y "%SRC%\*.lua" "%DST%\" >nul
copy /y "%SRC%\Locales\*.lua" "%DST%\Locales\" >nul
copy /y "%SRC%\Media\*.tga" "%DST%\Media\" >nul
copy /y "%SRC%\Lyorune.toc" "%DST%\" >nul
echo Lyorune installe dans %DST%
pause
