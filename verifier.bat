@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

REM ============================================================
REM  VERIFIER LE MANOIR
REM  Double-clique ce fichier. Il rejoue tous les controles du
REM  projet et dit, a la fin, si quelque chose a casse.
REM  Le detail complet part dans verification.log
REM ============================================================

set GODOT=
if defined GODOT_EXE if exist "%GODOT_EXE%" set "GODOT=%GODOT_EXE%"
if not defined GODOT if exist "%USERPROFILE%\Desktop\Godot_v4.7.1-stable_win64_console.exe" set "GODOT=%USERPROFILE%\Desktop\Godot_v4.7.1-stable_win64_console.exe"
if not defined GODOT for %%F in ("%USERPROFILE%\Desktop\Godot*console.exe") do set "GODOT=%%~fF"
if not defined GODOT (
  echo.
  echo   GODOT INTROUVABLE.
  echo   Pose le raccourci Godot ... console.exe sur ton Bureau,
  echo   ou definis la variable GODOT_EXE avec son chemin complet.
  echo.
  pause
  exit /b 1
)

echo.
echo   Verification du manoir en cours...
echo   Compte quelques minutes : le jeu est relance des dizaines de fois.
echo.

if exist verification.log del verification.log

echo === BANC PRINCIPAL === >> verification.log
echo   - banc principal
"%GODOT%" --headless --path . res://verification/banc.tscn >> verification.log 2>&1

for %%S in (audit depart regles_etage chaine coffre_fort etage escalier aile mur incarne demarches deux_rodeurs descente battue direction allure glissement) do (
  echo   - %%S
  echo.>> verification.log
  echo === %%S === >> verification.log
  "%GODOT%" --headless --path . --script res://verification/%%S.gd >> verification.log 2>&1
)

set RATES=0
for /f %%N in ('findstr /C:"RATE " verification.log ^| find /c /v ""') do set RATES=%%N
set GLISSE=0
for /f %%N in ('findstr /C:"GLISSEMENT essai" verification.log ^| find /c /v ""') do set GLISSE=%%N
set /a TOTAL=RATES+GLISSE

echo.
echo ============================================================
if %TOTAL% GTR 0 findstr /C:"RATE " /C:"GLISSEMENT essai" verification.log
echo ============================================================
echo.
if %TOTAL%==0 (
  echo   TOUT EST VERT. Aucun controle n'a rate.
) else (
  echo   %TOTAL% CONTROLE^(S^) ONT RATE. Les lignes sont ci-dessus.
  echo   Le detail complet est dans verification.log
)
echo.
pause
