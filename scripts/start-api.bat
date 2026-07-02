@echo off
cd /d %~dp0..
set PYTHONPATH=%CD%\services\api
if exist .venv\Scripts\activate.bat call .venv\Scripts\activate.bat
cd services\api
python main.py
