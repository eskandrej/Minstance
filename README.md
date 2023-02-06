
# Minstance
Minstance is a Godot plugin that enables running and debugging multiple instances. That makes it greate for developing multiplayer games.

# Adding instance
After enabling plugin there should be minstance run icon near play icon.
![tut](https://user-images.githubusercontent.com/122531384/216980845-7d87831c-781d-43fc-9824-39bf603ca68a.png)

Press right click on icon and then settings. In settings window, click on Add New Instance.
![image](https://user-images.githubusercontent.com/122531384/216983488-8140b736-5c04-4557-accd-f0d568f961d1.png)

# Options
### Debugger port
Every new instance will have that number plus one for debugging.
### Remember window position and size
If it's set on instance will save position and size of window on exit.
### Save breakpoints
Breakpoints will be preserved for scripts that are opened in editor.
### Remove autoload on exit
When minstance is about to run it enables minstance autoload and on exit disables. That enabling and disabling triggers save project window on exiting editor. Sometimes it can be annoying.
