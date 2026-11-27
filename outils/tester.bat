@echo off
rem Lance les tests de Lyorune hors du jeu. Chaque ligne doit commencer par OK.
set PYTHONIOENCODING=utf-8
python "%~dp0..\tests\run.py" "%~dp0.."
if errorlevel 1 goto fin
rem Le site de présentation : les deux cibles fabriquées et vérifiées
python "%~dp0..\tests\site.py"
:fin
if errorlevel 1 (echo. & echo DES TESTS ONT ECHOUE) else (echo. & echo TOUS LES TESTS PASSENT)
pause
