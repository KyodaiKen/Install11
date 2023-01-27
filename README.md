# Install11
A script that allows you to install Windows 11 by skipping OOBE and other pain

## Why?
It allows you to install Windows and the boot files onto a specific drive, which the typical Windows installation GUI fails to do! It tends to install the boot partition and files onto the first drive it can find in the system, which is usually a SATA drive.

When you remove said drive from your system at a later date and the you have installed Windows on your faster NVMe SSD but the boot files landed onto the drive you want to remove, Windows won't boot anymore because the boot partition is then missing!

Additionally it has been increasingly difficult to bypass Windows Setup to force you to enter a Microsoft Account. Using this script it's very easy to skip.

The script modifies the setup image just after Windows was copied onto your destination drive! No need to fiddle with ISOs or WIM or ESD files!

The skip_oobe.xml file will be copied to \Windows\Panther\unattend.xml, so Windows uses it to install Windows without you having to input anything into the out of the box experience UI (OOBE)!

## Tutorial
1. First open the example skip_oobe.xml file and edit the info as you desire.
You can find more info about the options [here](https://www.tenforums.com/tutorials/131765-apply-unattended-answer-file-windows-10-install-media.html).

2. You then need to boot a Windows 11 installation media, then press `SHIFT+F10` to open the terminal. Do this BEFORE clicking on `Next` in the GUI, just completely ignore the GUI.

3. Enter `diskpart` and press enter.

4. Enter `list disk` to see which drives you have in your system. Identify the drive you want to install Windows on. Unfortunately this can be difficult if you have multiple drives with the exact same size.

    You can also use
    ```cmd
    wmic diskdrive get Name, Manufacturer, Model, InterfaceType, MediaType, SerialNumber /format:list
    ```
    to try to identify it further.

    The number at the end of `\\.\PHYSICALDRIVE` (ie. `\\.\PHYSICALDRIVE0`) **SHOULD** be the number to use in diskpart.

    | :point_up:    | In a case where you have multiple drives with the same manufacturer, size, and more it is advised to only install the drive you want to install Windows on. |
    |---------------|:-------------------------|

    In this example, we will use 0.

5. If the drive was used before, make sure you have backed up ALL important data, because in the next step, we will delete EVERYTHING from the drive and make it as if it was just purchased new.

    To wipe the disk, you need to first select the disk drive you have determined in step 4 using:

    ```
    sel disk x
    ```

    `x` is the disk number you have determined in step 4.

6. We will now wipe the disk. 

    | :exclamation: WARNING      |
    |:---------------------------|
    | Use at your own risk! This will delete ALL data on the disk you have selcted!  |

    Just enter `clean` and press enter. It can take a while, this is normal.

    After diskpart has finished its job, enter `exit` to get out of diskpart itself.

7. Now we check the drive letter of the Windows setup drive

    Just enter
    ```cmd
    wmic logicaldisk get Name, VolumeName
    ```

    You should see something like this:

    ```
    Name   VolumeName
    C:
    D:     VentoyULTRA
    F:
    G:     ESD-ISO
    X:     Boot
    ```

    You want to use the drive letter that has something like `ESD` or the typical Windows 11 volume label. Note that letter down.

    If you use Ventoy, you should note the Ventoy drive so you can access the install.cmd script. If you don't it will be on the same drive letter like the Windows 11 install USB.

    In this tutorial we'll use it's g:.

8. Now we can check which index we need to use for installing the correct Windows 11 edition.

    For this, just navigate to the path of this install.cmd script and then run
    `install g:\sources\install` and then press the `TAB` key. If nothing happens, then Microsoft changed the location of the installation image. Navigate using dir to find it and enter the correct path.

    If you got it, continue entering: space and then `--list`

    Alright, it should  look like something like this, either with `esd` or `wim`:

    ```
    install g:\sources\install.esd --list
    ```

    After pressing enter, you should see a list with a list of the Windows editions and indexes.
    Pick your index for your edition and note it.

    For this tutorial we assume it's number 6.

9. Finally we can start the installation!

    We just need to collect all the information and write it down into a one-liner.

    ### Parameters (order is important!):
    1. path to install.esd or install.wim
    2. image index
    3. destination disk index from diskpart
    4. partition size for Windows in MB - 0 = fill disk

    ` `

    Enter the following into the terminal:

    ```
    install g:\sources\install.esd 6 0 0
    ```

    This will now show you a summary of what is being done. Follow the steps on screen.

    | :bulb:        | If you want to know more, just run install.cmd without any parameter or type `install --help`! |
    |---------------|:------------------------|

10. Done. After you have confirmed the steps, the system will reboot multiple times until you are being greeted either with your desktop or with the prompt to change the user's password.

    Enjoy!

## Known issues
Somehow I didn't find a way to catch diskpart errors, so you have to check if all commands were successful before continuing to reboot.