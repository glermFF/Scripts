@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

mode con: cols=115 lines=40
title IPv4 Config Panel
color 07

:: ============================================================
:: Verifica se o script está sendo executado como administrador
:: ============================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [ADMIN] Este programa precisa ser executado como administrador.
    echo.
    echo Clique com o botao direito no arquivo e selecione: "Executar como administrador".
    echo.
    pause
    exit /b 1
)

:MENU
cls

echo ===============================================
echo       	     IPv4 CONFIG PANEL v0.4.5
echo ===============================================
echo.
echo Interfaces de rede disponíveis:
echo.

set "count=0"

for /L %%i in (3,1,4) do (
    :: O netsh valida se a placa Ethernet existe e está ativa
    netsh interface ipv4 show config name="Ethernet %%i" 
    
    :: Se a placa existir (errorlevel 0), buscamos o Gateway dela
    if !errorlevel! equ 0 (
        
        :: roda o ipconfig e captura diretamente a linha do Gateway
        for /f "tokens=2 delims=:" %%g in ('ipconfig ^| findstr /i "Gateway"') do (
            set "gw_clean=%%g"
            :: Remove os espaços em branco
            set "gateway=!gw_clean: =!"
            
            :: Se o IP não estiver vazio guarda no array
            if not "!gateway!"=="" (
                call set "elem[!count!]=!gateway!"
                set /a count+=1
            )
        )
    )
)

::echo Testando saida array: !elem[1]! ^|^| !elem[2]! ^|^|

echo.
echo 1 - Escolher Interface
echo 2 - Acessar Coonfiguração Web da Interface
echo 3 - Reset 
echo.

choice /C 1234 /N /M Opção:
if errorlevel 4 goto FECHAR
if errorlevel 3 goto MENU
if errorlevel 2 goto LINK
if errorlevel 1 goto NET_INTERFACE

:: ============================================================

:LINK
echo.
echo Conectar em: 
echo 1 - !elem[1]!
echo 2 - !elem[2]!
echo.

choice /C 12 /N /M "Escolha o link: "
set "escolha=%errorlevel%"

:: =======================
:: ACESSO A INTERFACE WEB 
:: =======================
:CONNECT_INTERFACE
if "%escolha%" == "1" (start http://!elem[1]!) else if "%escolha%" == "2" (start http://!elem[2]!)
goto MENU

:: ============================================================

:NET_INTERFACE
set "INTERFACE="
set /p INTERFACE=Nome da Interface: 

if "%INTERFACE%"=="" (
    goto NET_INTERFACE
)

:: =======================
:: Selecionar configuração
:: =======================

echo.
echo =========================================
echo 		Tipo de configuração
echo =========================================
echo.
echo 1 - IP automático (DHCP)
echo 2 - IP fixo (manual)
echo 3 - Desativar interface
echo 4 - Ativar interface
echo 5 - Voltar
echo.

choice /C 12345 /N /M Opção: 

if errorlevel 5 goto MENU
if errorlevel 4 goto INTERFACE_ON
if errorlevel 3 goto INTERFACE_OFF
if errorlevel 2 goto FIXO
if errorlevel 1 goto DHCP

echo.
echo [INPUT ERRO] Opção invalida.
pause
goto MENU

:: ========================
:: DESATIVAR INTERFACE
:: ========================
:INTERFACE_OFF
netsh interface set interface "%INTERFACE%" disable
goto MENU

:: ========================
:: ATIVAR INTERFACE
:: ========================
:INTERFACE_ON
netsh interface set interface "%INTERFACE%" enable
goto MENU

:: =======================
:: IP AUTOMATICO
:: =======================
:DHCP

cls

echo =============================================
echo       	APLICANDO IP AUTOMATICO
echo =============================================
echo.
echo Interface: %INTERFACE%
echo.

netsh interface ipv4 set address name="%INTERFACE%" source=dhcp

if %errorlevel% neq 0 (
    echo.
    echo [ERRO] IP automático não aplicado.
    echo Verifique: 
    echo --> se já está definido como DHCP
    echo --> se o nome da interface esta correto
    echo.
    pause
    goto MENU
)

echo.
echo [OK] IP configurado para DHCP.
echo.

pause
goto MENU

:: =======================
:: IP FIXO
:: =======================
:FIXO

cls

echo =============================================
echo           CONFIGURACAO DE IP FIXO
echo =============================================
echo.
echo Interface: %INTERFACE%
echo.

set /p IP=Endereço IPv4 do computador: 

set /p MASK=Máscara de sub-rede (5 - Mascara padrão):
if "%MASK%"=="5" (set MASK=255.255.255.0)

set /p GATEWAY=Endereço do gateway: 

set /p USE_DNS=Definir DNS? (Enter - pular): 
if /I "%USE_DNS%"=="S" (
    set /p DNS=DNS Primário: 
)
goto INFO

:INFO
echo.
echo -----------------------------------------
echo Configuração informada:
echo.
echo Interface    : %INTERFACE%
echo IPv4         : %IP%
echo Máscara      : %MASK%
echo Gateway      : %GATEWAY%
if not "%DNS%" == "" (echo DNS Definido   : %DNS%) else (echo DNS       : %DNS%)
echo -----------------------------------------
echo.

set /p CONFIRMA=Confirmar alterações?(S/N): 

if /I "%CONFIRMA%"=="S" goto APLICAR_MUDANCAS

:ALTERAR_CAMPOS
echo.
set /p ALTERA=Alterar um dos campos?(S/N): 

if /I not "%ALTERA%"=="S" ( 
    pause
    goto MENU
)

echo.
echo 1 - IPv4
echo 2 - Máscara
echo 3 - Gateway
echo 4 - DNS
echo.
 
choice /C 123 /N /M Opção: 
if errorlevel 4 goto DOMAINNAME
if errorlevel 3 goto GATEWAY
if errorlevel 2 goto MASCARA
if errorlevel 1 goto IPV4


:APLICAR_MUDANCAS
echo.
echo Aplicando alteração...
echo.

netsh interface ipv4 set address name="%INTERFACE%" source=static address=%IP% mask=%MASK% gateway=%GATEWAY%

if "%DNS%" NEQ "" (netsh interface ipv4 set dns name="%INTERFACE%" static %DNS% validate=no)

if %errorlevel% neq 0 (
    echo.
    echo [ERRO] Nao foi possível aplicar a configuracao.
    echo Verifique os valores informados.
    echo.
    pause
    goto MENU
)

echo.
echo =============================================
echo       	CONFIGURAÇÃO APLICADA 
echo =============================================
echo.
echo Interface : %INTERFACE%
echo IPv4      : %IP%
echo Mascara   : %MASK%
echo Gateway   : %GATEWAY%
echo DNS 1º    : %DNS%
echo.

pause
goto MENU

:IPV4
set /p IP=Endereço IPv4 do computador:  
goto INFO

:MASCARA
set /p MASK=Máscara de sub-rede (5 - Mascara padrao):
if "%MASK%"=="5" (set MASK=255.255.255.0)
goto INFO

:GATEWAY
set /p GATEWAY=Endereço do gateway:
goto INFO

:DOMAINNAME
set /p USE_DNS=Definir DNS?: 
if /I "%USE_DNS%"=="S" (
    set /p DNS=DNS Primário: 
) else (
    set "DNS="
)
goto INFO
