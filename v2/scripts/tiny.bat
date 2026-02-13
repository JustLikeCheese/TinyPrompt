@echo off
setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0.."
set "BASE_DIR=%ROOT_DIR%\hidden\inbox"
set "INDEX_FILE=%BASE_DIR%\index.txt"
set "MESSAGE_FILE=%BASE_DIR%\message.json"
set "INDEXES_DIR=%BASE_DIR%\indexes"

if not exist "%BASE_DIR%" mkdir "%BASE_DIR%"
if not exist "%INDEXES_DIR%" mkdir "%INDEXES_DIR%"
if not exist "%INDEX_FILE%" (>"%INDEX_FILE%" echo 0)
if not exist "%MESSAGE_FILE%" (
    >"%MESSAGE_FILE%" echo [
    >>"%MESSAGE_FILE%" echo ]
)

if "%~1"=="new" (
    for /f "delims=" %%i in ('type "%INDEX_FILE%"') do (
        set "CURRENT_ID=%%i"
        set /a NEW_ID=CURRENT_ID + 1
>"%INDEX_FILE%" echo !NEW_ID!
echo Your employee id is !CURRENT_ID!!
    )
) else if "%~1"=="fetch" (
    if "%~2"=="" (
        echo Error: Employee ID is required for fetch command
        goto end
    )
    set "EMP_ID=%~2"
    set "EMP_INDEX_FILE=%INDEXES_DIR%\!EMP_ID!.txt"
    if not exist "!EMP_INDEX_FILE!" (
        >"!EMP_INDEX_FILE!" echo 0
    )
    for /f "delims=" %%i in ('type "!EMP_INDEX_FILE!"') do set "LAST_READ=%%i"
    
    set "SHOW_NEW=false"
    set "MSG_INDEX=0"
    
    for /f "delims=" %%a in ('type "%MESSAGE_FILE%"') do (
        set "LINE=%%a"
        if not "!LINE!"=="[" if not "!LINE!"=="]" if not "!LINE!"=="" (
            set "MSG=!LINE!"
            set "MSG=!MSG:    =!"
            if "!MSG:~-1!"=="," set "MSG=!MSG:~0,-1!"
            set "MSG=!MSG:~1,-1!"
            if not "!MSG!"=="" (
                set /a MSG_INDEX+=1
                if !MSG_INDEX! gtr !LAST_READ! (
                    if "!SHOW_NEW!"=="false" (
                        echo New Message:
                        set "SHOW_NEW=true"
                    )
                    echo !MSG!
                )
            )
        )
    )
    
    if "!SHOW_NEW!"=="false" (
        echo No new messages for now. Please try again later.
    ) else (
        >"!EMP_INDEX_FILE!" echo !MSG_INDEX!
    )
) else if "%~1"=="post" (
    if "%~2"=="" (
        echo Error: Employee ID is required for post command
        goto end
    )
    if "%~3"=="" (
        echo Error: Employee ID and Message are required for post command
        goto end
    )
    set "EMP_ID=%~2"
    set "MSG_CONTENT=%~3"
    set "NEW_MESSAGE=!EMP_ID!: !MSG_CONTENT!"
    set "TEMP_FILE=%BASE_DIR%\message.tmp"
    >"!TEMP_FILE!" echo [
    set "PREV="
    for /f "delims=" %%a in ('type "%MESSAGE_FILE%"') do (
        set "L=%%a"
        if "!L!"=="]" (
            if defined PREV (
                if "!PREV:~-1!"=="," (>>"!TEMP_FILE!" echo !PREV!) else (>>"!TEMP_FILE!" echo !PREV!,)
            )
            >>"!TEMP_FILE!" echo     "!NEW_MESSAGE!"
            >>"!TEMP_FILE!" echo ]
        ) else if not "!L!"=="[" (
            if defined PREV (
                if "!PREV:~-1!"=="," (>>"!TEMP_FILE!" echo !PREV!) else (>>"!TEMP_FILE!" echo !PREV!,)
            )
            set "PREV=!L!"
        )
    )
    move /y "!TEMP_FILE!" "%MESSAGE_FILE%" >nul
) else (
    echo Error: Invalid command. Available commands: new, fetch, post
)

:end
endlocal