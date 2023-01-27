@echo off
if %COMPUTERNAME% NEQ MINWINPC GOTO protect:
set image=%1
set index=%2
set idisk=%3
set wsize=%4
set noskip=%5

rem Verify parameters
IF NOT DEFINED image (
    echo = FATAL ERROR ==========================================================================
    echo ^(x^) No image file name defined! This is needed to specify the source of the installation
    echo     image to install Windows from. Refer to the readme on Github for more info.
    echo ========================================================================================
    set myexitcode=1
    echo:
    goto usage
)

rem Check for help prompt to print usage
IF %image% EQU --help (
    set myexitcode=0
    goto usage
)

rem Check if the image file actually exists
IF NOT EXIST %image% goto errim

rem Check the index parameter
IF NOT DEFINED index (
    echo = FATAL ERROR =======================================================================
    echo ^(x^) No image index defined. This is important for selecting the Windows edition. Like
    echo     Home, Pro, etc. Use the "List" option to list the indexes for each edition.
    echo =====================================================================================
    set myexitcode=1
    echo:
    goto usage
)

rem Show image index list
IF %index% EQU --list (
    DISM /get-wiminfo /wimfile:%image%
    EXIT /B 0
)

rem Verify the rest of the parameters
IF NOT DEFINED idisk (
    echo = FATAL ERROR ===================================================================
    echo ^(x^) No disk index from diskpart specified. Use diskpart and enter "list disk" to
    echo     determine the disk you want to install Windows and the EFI boot partition on.
    echo =================================================================================
    set myexitcode=1
    echo:
    goto usage
)
IF NOT DEFINED wsize (
    echo = FATAL ERROR =======================================================================
    echo ^(x^) No partition size specified. If you'd like to have your Windows partition to fill
    echo     the whole disk, enter 0, otherwise enter the size in MiB.
    echo =====================================================================================
    set myexitcode=1
    echo:
    goto usage
)
IF NOT DEFINED noskip (
    set noskip=a
)

rem Determine Windows partition size
IF %wsize% EQU 0 (
    set wsize=
    set strsize=filling the entire disk drive
) ELSE (
    set wsize=size %4
    set strsize=sized %4 MiB, rest unpartitioned
)

echo install.cmd - A script that allows you to install Windows 11 by skipping OOBE and other pain
echo:
echo ^(i^) THE FOLLOWING WILL BE DONE -------------------------------------------------------------
echo ^/^!^\ WARNING - POTENTIALLY DATA DESTRUCTIVE^! MAKE SURE THE DISK IS CLEAN (NO PARTITIONS)^!^!
echo:
echo ^=^> Disk %idisk% will be partitioned and formatted as follows:
echo      1. A 512 MiB sized EFI partition, formatted as FAT32 will be created (boot partition)
echo      2. The Windows partition will be created,
echo         ^-^> %strsize%
echo         ^-^> formatted with NTFS.
echo:
echo ^=^> Windows is being installed by extracting the contents of
echo    %image%
echo    to the Windows partition created above
echo:
IF /i %noskip% EQU a (
    echo ^=^> By copying unateended XML file into \Windows\Panther, OOBE will be skipped
    echo:
)
IF /i %noskip% EQU --noskip-oobe echo ^=^> OOBE will NOT be skipped.
echo ----------------------------------------------------------------------------------------------
echo:
echo You can cancel this operation using CTRL+C, then confirming with y, or you can
pause

rem LET'S GO!!
echo ^=^> Partitioning disk %idisk% using diskpart

rem Partitioning, formatting and letter assignment
(echo sel dis %idisk%
echo conv gpt
echo cre par efi size 512
echo form fs fat32 quick
echo ass letter w
echo cre par pri %wsize%
echo form quick
echo ass letter z
) | diskpart
echo:
echo:
echo z: has been assigned to the Windows partition
echo w: has been assigned to the EFI partition
echo:

rem Installing Windows and boot environment
echo ^=^> Installing Windows from install image %image% with index %index% onto z:
dism /apply-image /imagefile:%image% /index:%index% /applydir:z:\
IF %ERRORLEVEL% NEQ 0 goto errdism
echo:
echo ^=^> Installing boot environment
z:\windows\system32\bcdboot.exe z:\windows /s w:
echo:

rem Copy XML to skip OOBE
IF /i %noskip% NEQ --noskip-oobe (
    echo ^=^> Modifying the extracted image to enable unattended mode to skip OOBE
    echo - Creating "Panther" directory under z:\Windows
    mkdir z:\Windows\Panther
    echo - Copying the answer file into the previously created Panther directory
    copy %~dp0\skip_oobe.xml z:\Windows\Panther\unattend.xml
)

echo Before we reboot, check the backlog for errors, then either cancel the reboot using CTRL+C or
pause
echo ^=^> Rebooting
wpeutil reboot
exit /B 0

rem Error handling
:errim
echo = FATAL ERROR ===============================================================
echo ^(x^) Cannot find the file given! Make sure the file path and name are correct.
echo =============================================================================
exit /B 5

:errdism
echo:
echo = FATAL ERROR ======================================================================
echo ^(x^) There has been an error trying to extract the image^! Please the check DISM logs.
echo ====================================================================================
exit /B 15

:protect
echo = FATAL ERROR ==============================================================
echo ^/^!^\ This script is only intended to run in the Windows PE Setup environment^!
echo ============================================================================
exit /B 30

:usage
echo install.cmd - A script that allows you to install Windows 11 by skipping OOBE and other pain
echo:
echo Usage ------------
echo:
echo This script is intended to be used on a clean disk drive! Use diskpart, list disk to determine
echo the drive you want to install Windows on and then "sel disk <disk>" to select the disk and
echo enter "clean" to DELETE ALL FILES AND PARTITIONS ON IT.
echo:
echo ^/^!^\ There is no check if the disk is clean. Use at your own risk!
echo:
echo -- List available indexes / Windows editions available --
echo install ^<path to install.esd or install.wim^> --list
echo:
echo -- Install Windows --
echo Parameters (order is important!):
echo 1: path to install.esd or install.wim
echo 2: image index
echo 3: destination disk index from diskpart
echo 4: partition size for Windows in MB - 0 = fill disk
echo 5: --noskip-oobe - use this to NOT use unattended install
echo:
echo Examples:
echo Install Windows from g:\sources\install.esd to disk 0 with index 6 (Win11 Pro for example)
echo and limit the Windows partition size to 512 GiB:
echo install g:\sources\install.esd 6 0 524288
echo:
echo Install Windows from g:\sources\install.esd to disk 0 with index 6 (Win11 Pro for example)
echo and let the Windows partition fill the disk:
echo install g:\sources\install.est 6 0 0
echo:
echo Install Windows from g:\sources\install.esd to disk 0 with index 6 (Win11 Pro for example)
echo and limit the Windows partition size to 512 GiB but do not skip OOBE:
echo install g:\sources\install.est 6 0 524288 --noskip-oobe
exit /B %myexitcode%