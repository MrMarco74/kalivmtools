# kalivmtools
---
## Introduction

kalivmtools is a Powershell script, which uses [vmxtoolkit](https://github.com/bottkars/vmxtoolkit) and provides the following features:
- download of latest kali version for VMWare Workstation
- Extracting the VM Image
- Changing VM Config
- Starting VM
- Deploying custom scripts into the VM
- invoking them
- Repacking into new archiv with renaming of the old version
- Generating sha256 checksums

---
## Future plans

The following features may be implemented in the near future:
- Configurable VMWare Config file changing
- Addition for running deployed scripts un a defined order

Maybe these features will be included on top:
- Defragmention of VMDK Files
- Resizing of VMDK Files
- Exporting as OVA Version

---
## Requirements

- [vmxtoolkit](https://github.com/bottkars/vmxtoolkit)
- [VMware Workstation Pro](https://customerconnect.vmware.com/de/downloads/info/slug/desktop_end_user_computing/vmware_workstation_pro/17_0)

---
## Famous last words

There is no rocket science involved and it was only build with my needs in scope.
I know it could be done better and it will be improved from me.
If I am to slow for you, simply generate a fork!
