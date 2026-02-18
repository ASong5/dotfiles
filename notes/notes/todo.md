- [x] integrate lock screen
- [ ] consider making lua snippets in neovim and adding them to the completion engine
- [ ] add dictionary feature to rofi (consider: https://github.com/kev-cao/rofi-dictionary)
- [ ] figure out situation with xembedproxy and the black windows that spawn
    - might have to make an issue about it; best to just not use it for the time being?
- [ ] continue working on the runelite potions storage app
    - find out how to view the contents of the widget to see how we can manipulate it (might need to use the debugger)
- [ ] re-sync and add all new important configs to .dotfiles via stow
- [ ] figure out how to add background blur to niri (https://github.com/YaLTeR/niri/pull/1634)
- [ ] figure out why kakaotalk videos dont work
- [ ] figure out why steam webhelper crashes on startup sometimes.

-------------------------------------------

- [ ]  get nvim-dap-python to work
- [ ]  actually configure waybar to look better
- [ ]  finish adding more autostart apps (add as we go, and consider moving all apps from autostart to niri config for sake of having one place to manage it all)

ideas:
- [ ]  runelite plugin to allow changing position of potions within potion storage
    - [x] trim doses from text when saving to file so that dose count does not affect positioning  
    - [ ] change access modifiers of some methods and fields to be appropriate based on context 
    - [ ] set anti drag settings based on what is already used in bank/inventory
    - [ ] implement sort button
    - [ ] implement search (i think it would be better to just highlight a potion when it is fuzzily matched rather than overlaying a new panel over the section to show only the matched results)
    - [x] make compatible with potion storage bars plugin 
- [ ]  runelite plugin to prevent minimap rotation
- [ ] runelite plugin to tell you what specific kc you got each clog at (maybe as a tooltip when you hover over it in collection log, or a text command, or both)
