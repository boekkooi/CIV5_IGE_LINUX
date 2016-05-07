# [Civilication - Ingame Editor (IGE) Mod](http://forums.civfanatics.com/showthread.php?t=436912) for Linux

This repo is a modified version of the [original mod](http://forums.civfanatics.com/showthread.php?t=436912) made by [DonQuiche](http://forums.civfanatics.com/member.php?u=210491), which works for Linux versions of Civilization 5.

This repo itself is a fork of [boekkooi/CIV5_IGE_LINUX](https://github.com/boekkooi/CIV5_IGE_LINUX), which was last touched in November 2014, and as of May 2016 does not appear to still work.

The code currently here was based on Version 39 of the IGE mod, and tested under Steam "March 31, 2016 at 19:19:09" build, Steam API v017, Steam package version 1459463254 and Civilization V version 1.0.3.279(130961).

It was tesed on Arch Linux, with Steam originally installed from package version 1.0.0.51-1.

The fixes herein are thanks to [this post on steamcommunity.com](https://steamcommunity.com/workshop/filedetails/discussion/77002777/540744935724734348/#c35219681712681401) from [koraytaylan](https://steamcommunity.com/id/koraytaylan).

## Install

1. I didn't need to do any of this, but some people may need to enable mods; see [[TUTORIAL] Getting Mods to work in Linux](http://forums.civfanatics.com/showthread.php?t=528742).
2. Clone this repository (or download the archive of it) at a suitable location.
3. Find your Civ V mods directory. Under Linux, this seems to be located at ``~/.local/share/Aspyr/Sid Meier's Civilization 5/MODS`` (yes, the path has spaces and punctuation).
4. If you have an existing version of IGE (most likely a ``ingame editor (v 39)`` directory), remove it.
5. Symlink the ``ingame editor (v 39)`` directory of the git clone/archvie into the MODS directory. If you're in the root of the git repo/archive: ``cd ingame\ editor\ \(v\ 39\)/ && ln -s "$(pwd)" ~/.local/share/Aspyr/Sid\ Meier\'s\ Civilization\ 5/MODS/ingame\ editor\ \(v\ 39\)``
6. Start the game and click mods and enable IGE. Be sure to click the little circle (turns to a green check) to enable it. If all works well, when you start a game, you'll see the "* IGE *" button at the right of the top bar.
