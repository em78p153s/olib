::@echo off & setlocal EnableDelayedExpansion
@echo off
set SCRIPT_ROOT=%~dp0
cd %SCRIPT_ROOT%


:MAIN_LOOP
echo "==============option start====================================================="
echo "args = [0] - [ install dependence ]"
echo "args = [1] - [ 1 = build] "
echo "==============option end======================================================="

set /p option=
if "%option%"=="0" (
::安装相关依赖
rm Gemfile.lock
bundle install
)
if "%option%"=="1" (
::生成静态网页
bundle exec jekyll serve
)
goto MAIN_LOOP






