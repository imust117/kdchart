@echo off
set PRODUCT_CAP=KDCHART
set product_low=kdchart
set Product_mix=KDChart
set Product_Space="KD Chart"

set VERSION=2.6.0

set SOURCE_DIR=%~dp0
set PACKSCRIPTS_DIR=../admin/packscripts

set shared=yes
set debug=no
set release=yes
set debug_and_release=no
set prefix=
set unittests=no
set static_qt=no

if exist %PACKSCRIPTS_DIR% (
    set unittests=yes
    goto :CheckLicenseComplete
)

if exist .license.accepted goto :CheckLicenseComplete

set license_file=

if exist %SOURCE_DIR%\LICENSE.GPL.txt (
    if exist %SOURCE_DIR%\LICENSE.US.txt (
        if exist %SOURCE_DIR%\LICENSE.txt (
            echo.
            echo Please choose your license.
            echo.
            echo Type 1 for the GNU General Public License ^(GPL^).
            echo Type 2 for the %Product_Space% Commercial License for USA/Canada.
            echo Type 3 for the %Product_Space% Commercial License for anywhere outside USA/Canada.
            echo Anything else cancels.
            echo.
            set /p license=Select:
	)
    ) else (
        license=1
    )
) else (
    if exist %SOURCE_DIR%\LICENSE.US.txt (
        license=2
    ) else (
        if exist %SOURCE_DIR%\LICENSE.txt (
            license=3
        ) else (
            echo "Couldn't find license file, aborting"
            exit /B 1
        )
    )
)

if "%license%" == "1" (
    set license_name="GNU General Public License (GPL)"
    set license_file=LICENSE.GPL.txt
	goto :CheckLicense
) else (
    if "%license%" == "2" (
        set license_name="%Product_Space% USA/Canada Commercial License"
        set license_file=LICENSE.US.txt
        goto :CheckLicense
    ) else (
        if "%license%" == "3" (
            set license_name="%Product_Space% Commercial License"
            set license_file=LICENSE.txt
            goto :CheckLicense
        ) else (
            exit /B 1
        )
    )
)

:CheckLicense
echo.
echo License Agreement
echo.
echo You are licensed to use this software under the terms of
echo the %license_name%.
echo.
echo Type '?' to view the %license_name%.
echo Type 'yes' to accept this license offer.
echo Type 'no' to decline this license offer.
echo.
set /p answer=Do you accept the terms of this license?

if "%answer%" == "no" goto :CheckLicenseFailed
if "%answer%" == "yes" (
    echo. > .license.accepted
    goto :CheckLicenseComplete
)
if "%answer%" == "?" more %license_file%
goto :CheckLicense

:CheckLicenseFailed
echo You are not licensed to use this software.
exit /B 1

:CheckLicenseComplete

rem This is the batch equivalent of KDAB_QT_PATH=`qmake -query QT_INSTALL_PREFIX`...
for /f "tokens=*" %%V in ('qmake -query QT_INSTALL_PREFIX') do set KDAB_QT_PATH=%%V

if "%KDAB_QT_PATH%" == "" (
  echo You need to add qmake to the PATH
  exit /B 1
)

echo Qt found: %KDAB_QT_PATH%

del /Q /S Makefile* 2> NUL
del /Q /S debug 2> NUL
del /Q /S release 2> NUL
if exist src\src.pro (
    del /Q lib 2> NUL
    del /Q bin 2> NUL
)
:Options
if "%1" == ""          goto :EndOfOptions

if "%1" == "-prefix"   goto :Prefix
if "%1" == "/prefix"   goto :Prefix

if "%1" == "-override-version"  goto :OverrideVersion
if "%1" == "/override-version"  goto :OverrideVersion

if "%1" == "-unittests"    goto :Unittests
if "%1" == "/unittests"    goto :Unittests

if "%1" == "-no-unittests" goto :NoUnittests
if "%1" == "/no-unittests" goto :NoUnittests

if "%1" == "-shared"   goto :Shared
if "%1" == "/shared"   goto :Shared

if "%1" == "-static"   goto :Static
if "%1" == "/static"   goto :Static

if "%1" == "-qt_static"   goto :QT_Static
if "%1" == "/qt_static"   goto :QT_Static

if "%1" == "-release"  goto :Release
if "%1" == "/release"  goto :Release

if "%1" == "-debug_and_release"  goto :Debug_And_Release
if "%1" == "/debug_and_release"  goto :Debug_And_Release

if "%1" == "-debug"    goto :Debug
if "%1" == "/debug"    goto :Debug

if "%1" == "-hostqmake"    goto :HostQMake
if "%1" == "/hostqmake"    goto :HostQMake

if "%1" == "-qmake"    goto :QMake
if "%1" == "/qmake"    goto :QMake

if "%1" == "-help"     goto :Help
if "%1" == "/help"     goto :Help
if "%1" == "--help"    goto :Help
if "%1" == "/?"        goto :Help

echo Unknown option: %1
goto :usage

:OptionWithArg
shift
:OptionNoArg
shift
goto :Options

:Prefix
      set prefix="%2"
      goto :OptionWithArg
      echo Installation not supported, -prefix option ignored
      goto :OptionWithArg
rem   goto :usage
:OverrideVersion
    set VERSION=%2
    goto :OptionWithArg
:Unittests
    set unittests=yes
    goto :OptionNoArg
:NoUnittests
    set unittests=no
    goto :OptionNoArg
:Shared
    set shared=yes
    goto :OptionNoArg
:Static
    set shared=no
    goto :OptionNoArg
:Release
    set release=yes
    set debug=no
	set debug_and_release=no
    goto :OptionNoArg

:Debug_And_Release
	set release=no
    set debug=no
	set debug_and_release=yes
    goto :OptionNoArg
:Debug
    set debug=yes
    set release=no
	set debug_and_release=no
    goto :OptionNoArg
:QT_Static
if "%STATIC_BUILD_SUPPORTED%" == "true" (
    set qt_static=yes
    goto :OptionNoArg
) else (
  echo Static build not supported, -static option not allowed
  goto :usage
)
:HostQMake
    set host_qmake=%2
    goto :OptionWithArg
:QMake
    set target_qmake=%2
    goto :OptionWithArg
:Unittests
:Help
    goto :usage

:EndOfOptions

if "%debug_and_release%" == "yes" (
	set QMAKE_ARGS=%QMAKE_ARGS% CONFIG+=debug_and_release CONFIG-=build_all
	goto :END_BUILDTYPE
)

if "%release%" == "yes" (
    if "%debug%" == "yes" (
		set QMAKE_ARGS=%QMAKE_ARGS% CONFIG+=debug_and_release CONFIG+=build_all
	set release="yes (combined)"
	set debug="yes (combined)"
    ) else (
		set QMAKE_ARGS=%QMAKE_ARGS% CONFIG+=release CONFIG-=debug CONFIG-=debug_and_release
    )
) else (
    if "%debug%" == "yes" (
        set QMAKE_ARGS=%QMAKE_ARGS% CONFIG-=release CONFIG+=debug CONFIG-=debug_and_release
    ) else (
	echo "Internal error. At least one of debug and release must be set"
	goto :CleanEnd
    )
)
:END_BUILDTYPE

if "%shared%" == "yes" (
    set QMAKE_ARGS=%QMAKE_ARGS% CONFIG+=shared
) else (
    set QMAKE_ARGS=%QMAKE_ARGS% CONFIG+=static
    rem This is needed too, when Qt is static, otherwise it sets -DQT_DLL and linking fails.
    if "%qt_static%" == "yes" (
      set QMAKE_ARGS=%QMAKE_ARGS% CONFIG+=qt_static
    )
)

if "%unittests%" == "yes" (
    set QMAKE_ARGS=%QMAKE_ARGS% CONFIG+=unittests
)

set default_prefix=C:\\KDAB\\%Product_mix%-%VERSION%

if "%prefix%" == "" (
    set prefix="%default_prefix%"
)
set QMAKE_ARGS=%QMAKE_ARGS% %PRODUCT_CAP%_INSTALL_PREFIX=%prefix%

set QMAKE_ARGS=%QMAKE_ARGS% VERSION=%VERSION%
set QMAKE_ARGS=%QMAKE_ARGS% CONFIG+=%product_low%_target

if exist "%KDAB_QT_PATH%\include\Qt\private" (
    set QMAKE_ARGS=%QMAKE_ARGS% CONFIG+=have_private_qt_headers
    set QMAKE_ARGS=%QMAKE_ARGS% INCLUDEPATH+=%KDAB_QT_PATH%/include/Qt/private
) else (
    rem echo KDAB_QT_PATH must point to an installation that has private headers installed.
    rem echo Some features will not be available.
)

if not "%host_qmake%" == "" (
    set HOST_QMAKE_ARGS=%QMAKE_ARGS%
    set QMAKE_ARGS=%QMAKE_ARGS% CONFIG+=crosscompiling CONFIG+=win32crosscompiling
}

echo %Product_mix% v%VERSION% configuration:
echo.
echo   Debug...................: %debug% (default: no)
echo   Release.................: %release% (default: yes)
echo   Shared build............: %shared% (default: yes)
echo   Compiled-In Unit Tests..: %unittests% (default: no)
echo.

if "%target_qmake%" == "" set target_qmake=%KDAB_QT_PATH%\bin\qmake

%target_qmake% %SOURCE_DIR%\%product_low%.pro -recursive %QMAKE_ARGS% "%PRODUCT_CAP%_BASE=%CD%"

if errorlevel 1 (
    echo qmake failed
    goto :CleanEnd
)

if not "%host_qmake%" == "" (
    mkdir kdwsdl2cpp
    cd kdwsdl2cpp
    %host_qmake% %SOURCE_DIR%\kdwsdl2cpp -recursive %HOST_QMAKE_ARGS%
)

echo Ok, now run nmake (for Visual Studio) or mingw32-make (for mingw) to build the framework.
goto :end

:usage
IF "%1" NEQ "" echo %0: unknown option "%1"
echo usage: %0 [options]
echo where options include:
echo.
echo   -prefix ^<dir^>
echo       set installation prefix to ^<dir^>, used by make install
echo.
echo   -release / -debug
echo       build in debug/release mode (default is release)
echo.
echo   -static / -shared
echo       build static/shared libraries (default shared)
echo.
echo   -unittests / -no-unittests
echo       enable/disable compiled-in unittests (default is disabled)
echo
echo   -qmake ^<path^>
echo       explicitly sets the qmake location, instead of using the
echo       qmake in the path.
echo.
echo   -hostqmake ^<path^>
echo       when cross-compiling, the qmake in the path will be used for
echo       compiling the product's code, but the host qmake will be used
echo       to compile the host tools (code generators).
echo.

:CleanEnd

:end
