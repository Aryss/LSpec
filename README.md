A spectating mutator for UT2004 Duel events. Provides a modern interface for streaming, with extra data that original game does not have on the client. 

Demo from a v1.0 version:

[![PREVIEW](https://img.youtube.com/vi/JJ0yZVjTUEE/0.jpg)](https://www.youtube.com/watch?v=JJ0yZVjTUEE&rel=0)

### Proper readme to follow, but a few pointers for now:
- On the server you'll need to make the following changes to your server.ini:
this line to the end of the ServerPackages list under [Engine.GameEngine]:
```
ServerPackages=LSpec_v108
```
This block to the very end of the ini file:
```
[LSpec_v108.MutSpecPlus]
Pass=your_password
```
Also, while connecting you need to provide a password via console like this:
```
open 127.0.0.1?SpectatorOnly=1?Key=your_password
```
**Without this overlay won't be displayed. This is done to prevent someone else just joining as a spec and "coaching" one of the players with all the extra data readily available. I'd also recommend to set at least a 30s delay when streaming with that tool.**
While it makes joining a server more complex, you can work around this by making a text file in your client's System folder, paste the command there and save it as "join" without extension. You can then just use command console "exec join" to run this.
- This mod makes an assumption that a map has one of each item: Supershield, Keg O'Health, Healthpack, UDamage. This will probably cause problems on the maps where there's more than one 50 armor, but off the top of my head, the most common maps of UT2004 1-on-1 pool usually have one item and I didn't want to spend too much time on item tracking.
- Item times may still be off slightly, roughly by 1s from what I've seen. This is just replication, so unavoidable.
- Since this mod also has a client component you do need to have it added to ServerPackages
- To compile the mod yourself: you will need to have Jost font from GoogleFonts installed in your system, it's used for some of the lines. Or, of course, you can edit the import lines in the DuelSpecOverlay to use something else.
- The render code in the DuelSpecOverlay.uc uses a lot of local up front caching at the start of the frame. This is done to avoid client crashes as this code is prone to do exactly that if you access a reference to an objected that was removed. This doesn't solve the issue 100% but vastly reduces the chance of it happening. However during normal gameplay the chances of that are minimal
- Controller code can be safely ignored right now, this is an attempt (so far futile) to make the existing Attract mode cameras to work online. Class is not currently used in any way.

### Controls
Y - Swaps left and right player (to keep positions the same between matches), of course swaps all the data as well

I - Show extra stats: Kills, Suicides, Ping, Packet Loss

< - Increases/resets left player score. Score is saved locally on the client and persists between matches/sessions

\> - Increases/resets right player score. Score is saved locally on the client and persists between matches/sessions

? - Cycles through BO format: off > 3  > 5 > 7. Also saved locally on the client and persists between matches/sessions

P - hides weapon data. Press O to re-enable

O - Cycles players' weapon info to pickup/damage stats, to other data (last not implemented yet), back to weapon info. 

### Troubleshooting
**Overlay doesn't appear. Mutator is loaded and server log says spectator is cleared for access.**
Make sure the mutator is added to the ServerPackages, otherwise it won't be loaded on the client.

**Overlay doesn't appear. Mutator is loaded but server log says spectator is not cleared for access.**
This may be caused by some weird symbols in the player name, in one of my test cases player with "|" symbol in the name was failing the key check. Try removing special characters from the spec's Player name.







