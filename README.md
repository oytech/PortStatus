# PortStatus (WIP)

PoC macOS menu bar app showing status of installed MacPorts packages.

TODO:
- [x] read installed ports using shell command
- [x] fetch latest versions from https://ports.macports.org API
- [x] polling API in the background for version changes
- [x] watch filesystem for macports dir changes and reread installed ports
- [ ] fix TODOs
- [ ] package app and publish to MacPorts

Limitations:
- `/api/v1/ports/?name=MacPorts` does not support querying by multiple names
- fetch only installed and requested ports (witout dependencies) to lower number of API requests
