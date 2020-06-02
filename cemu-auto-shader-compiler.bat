@echo off 
pushd "%~dp0"
set "cemuPath=%~dp0"
set /p gamesPath= Enter full path to Cemu games directory (excluding trailing backslash) then press Enter: 

cls
echo Games Path: %gamesPath%
echo;

REM create cemu-shader-watcher.bat (initiated seperately to allow shader compilation and watcher tasks to run parallel)
    REM waits for cemu to start compiling shaders
    REM this listens to cemu while shaders are being compiled
    REM initiates timer to allow some pipeline cache to be compiled
echo Creating cemu-shader-watcher ...
>cemu-shader-watcher.bat (
    echo @echo off
    echo setlocal
    echo :cemuWaitLoop
    echo for /f "tokens=* skip=9 delims= " %%%%g in ('tasklist /v /fo list /fi "imagename eq cemu*"'^) do (
        echo set "wTitle=%%%%g" 
        echo if not "%%wTitle%%"=="%%wTitle:Loading=%%" (
            echo goto cemuInitialised
        echo ^)
        echo ping 127.0.0.1 -n 1 -w 500 ^>nul 2^>^&1
    echo ^) 
    echo goto cemuWaitLoop
    echo :cemuInitialised
    echo echo Shaders compiling ...  
    echo :cemuWatcherloop
    echo for /f "tokens=* skip=9 delims= " %%%%g in ('tasklist /v /fo list /fi "imagename eq cemu*"'^) do (
        echo set "wTitle=%%%%g" 
        echo if not "%%wTitle%%"=="%%wTitle:Cemu=%%" (
            echo if not "%%wTitle%%"=="%%wTitle:OpenGL=%%" (
                echo echo Shaders compiled ...
                echo goto cemuPostCompiled              
            echo ^)
            echo if not "%%wTitle%%"=="%%wTitle:Vulkan=%%" (
                echo echo Shaders compiled ...
                echo goto cemuPostCompiled              
            echo ^)          
        echo ^)
        echo ping 127.0.0.1 -n 1 -w 500 ^>nul 2^>^&1
    echo ^) 
    echo goto cemuWatcherLoop
    echo :cemuPostCompiled
    echo echo Closing Cemu after 60 seconds to allow some pipeline cache to build ...
    echo timeout /t 60 /nobreak ^>nul 2^>^&1
    echo taskkill /im "cemu.exe" /f ^>nul 2^>^&1
    echo endlocal
    echo exit /b 0
)

REM delete old shader cache folders
echo Deleting old Cemu ShaderCache folders ...
rmdir /s /q "%cemuPath%\shaderCache\driver\nvidia" >nul 2>&1
rmdir /s /q "%localappdata%\NVIDIA\GLCache" >nul 2>&1

REM get all .rpx files inside %gamesPath%
    REM run the game 
    REM allow cemu-shader-watcher to run beside to analyse when shaders have compiled 
    REM once compiled kill cemu & wait 3 seconds before running next game 
echo Running each game detected ...
cd /d %gamesPath%
for /r %%a in (*.rpx) do (
    start "Cemu Shader Watcher" cmd /c "%cemuPath%\cemu-shader-watcher.bat" 
    "%cemuPath%\cemu.exe" -g "%%a"
    timeout /t 03 /nobreak >nul 2>&1
)

echo Cleaning up ...
del /f /s /q "%cemuPath%\cemu-shader-watcher.bat" >nul 2>&1
popd
echo Done! Press any key to exit ...
pause >nul 2>&1 