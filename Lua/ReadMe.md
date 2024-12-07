# Datalink lua script for moonloader
Script have 2 versions:
1. For [RakSAMP Lite](Raksamp/dlink.lua) - can be used with [RakSAMP Lite Bot](https://www.blast.hk/threads/108052/). This [script](Raksamp/dlink.lua) laying in [Raksamp](Raksamp) folder;
2. For [GTA](gtasamp/dlink.lua) - can be used in PC version of [San Andreas Multiplayer](https://www.sa-mp.mp/downloads/) with [moonloader](https://www.blast.hk/threads/13305/) and [sampfuncs](https://www.blast.hk/threads/17/) installed. This version of script is laying in [gtasamp](gtasamp) folder.

## Script commands
Are the same for both versions. You can use this commands via sampfuncs console in gta like `dlink start` or as chat command like `/dlink start`. Console commands in RakSAMP Lite have format like `!dlink start`

----------------------------------------
| Command | Description |
|--------------------|-------------------|
| `start` `stop` | enable or disable data transmition |
|  `sendSelf` | send myself as ally |
|  `sendEnemy` | send enemy players |
| `tickTime`  |  delay between data transmition to the remote host |
|  `maxPlayers` |  maximum players to transmit per time (markers and enemies) |
| `serverHost` | set remote host url (default: `datalink.sampmap.ru`) |
| `serverName` | set current active room (what map `Server Host` will receive this data) |
| `serverPassword` | set password if needed (on public servers this value doesn't affect anything) |
-----------------------------------------

Example of use:
- In sampfuncs console - `dlink serverName MainServer`
- In samp chat - `/dlink serverName MainServer`
- In RakSAMP console - `!dlink serverName MainServer`
