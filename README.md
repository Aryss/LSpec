A server side spectating mutator for UT2004 Duel events. Provides a modern interface for streaming, with extra data that original game does not provide. 

Demo from a slightly earlier version:
<iframe width="560" height="315" src="https://www.youtube.com/embed/JJ0yZVjTUEE?rel=0" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

Proper readme to follow, but a few pointers for now:
- On the server you'll need to add the following to your server.ini:
```[LSpec.MutSpecPlus]
Pass=your_password```
Also, while connecting you need to provide a password via console like this:
```open 127.0.0.1?SpectatorOnly=1?Key=your_password```
Without this overlay won't be displayed. This is done to prevent someone else just joining as a spec and "coaching" one of the players with all the extra data readily available. I'd also recommend to set at least a 30s delay when streaming with that tool.
While it makes joining a server more complex, you can work around this by making a text file in your client's System folder, paste the command there and save it as "join" without extension. You can then just use command console "exec join" to run this.

- To compile the mod yourself: you will need to have Jost font from GoogleFonts installed in your system, it's used for some of the lines. Or, of course, you can edit the import lines in the DuelSpecOverlay to use something else.
- The render code in the DuelSpecOverlay.uc uses a lot of local up front caching at the start of the frame. This is done to avoid client crashes as this code is prone to do exactly that if you access a reference to an objected that was removed. This doesn't solve the issue 100% but vastly reduces the chance of it happening. However during normal gameplay the chances of that are minimal
- Controller code can be safely ignored right now, this is an attempt (so far futile) to make the existing Attract mode cameras to work online.





