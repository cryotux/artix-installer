# artix-installer

![](https://img.shields.io/badge/OS-Artix%20Linux-blue?logo=Artix+Linux)

A simple installer for Artix Linux. Supports OpenRC and dinit.

## Credits & Attribution

This project is based on the original artix-installer by Maxwell Anderson (Zaechus).

**Original project:** https://github.com/Zaechus/artix-installer

The original project and its source code are licensed under the GNU General Public License v3.0 (GPL-3.0).

This version contains modifications and adjustments made for personal use. AI assistance was used to help understand, review, improve, and restructure parts of the installer.

The original copyright notices and GPL license have been retained in the source files.

## Usage

1. Boot into the Artix live disk (the login and password are both `artix`).
2. Connect to the internet. Ethernet is setup automatically, and wifi is done with something like:
```
sudo rfkill unblock wifi
sudo ip link set wlan0 up
connmanctl
```
In Connman, use: `agent on`, `scan wifi`, `services`, `connect wifi_NAME`, `quit`

3. Acquire the install scripts:
```
git clone https://github.com/cryotux/artix-installer.git
cd artix-installer

```
4. Run `./install.sh`.
5. When everything finishes, `poweroff`, remove the installation media, and boot into Artix. Post-installation networking is done with Connman.

### Preinstallation

* ISO downloads can be found at [artixlinux.org](https://artixlinux.org/download.php)
* ISO files can be burned to drives with `dd` or something like Etcher.
* `sudo dd bs=4M if=/path/to/artix.iso of=/dev/sd[drive letter] status=progress`
* A better method these days is to use [Ventoy](https://www.ventoy.net/en/index.html).