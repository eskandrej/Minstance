
# Minstance
Minstance is a Godot plugin that enables running and debugging multiple instances. That makes it greate for developing multiplayer games.

# Adding instance
After enabling plugin there should be minstance run icon near play icon.
![tut](https://user-images.githubusercontent.com/122531384/216980845-7d87831c-781d-43fc-9824-39bf603ca68a.png)

Press right click on icon and then settings. In settings window, click on Add New Instance.
![image](https://user-images.githubusercontent.com/122531384/216983488-8140b736-5c04-4557-accd-f0d568f961d1.png)

## Instance properties
![instance-properties](https://user-images.githubusercontent.com/122531384/217018711-7cb05eaa-63bc-4d48-904a-1bb06e290abb.png)

### Title
Title of instance. For example you could name it with name of player.
### Arguments
Arguments can be retrieved by using get_minstance_value_from_args in MinstanceAutoload node. See [example](https://github.com/eskandrej/Minstance#example-using-arguments).
### Color identification
Color that will represent everything that is related to instance. Inspected object in inspector will have title in that color, output in [Minstance Outputs](https://github.com/eskandrej/Minstance#minstance-outputs) and window of instance.
### Window

You can manually add values for position or you could drag window in monitor widget.

![anim](https://user-images.githubusercontent.com/122531384/217220061-8d2fcaac-c68c-43dd-8961-451c7fa3653a.gif)
# Options
### Debugger port
Every new instance will have that number plus sequence number of the instance for debugging.
### Remember window position and size
If it's set on, instance will save position and size of window on exit.
### Save breakpoints
Breakpoints will be preserved for scripts that are opened in editor.
### Remove autoload on exit
When minstance is about to run it enables minstance autoload and on exit disables. That enabling and disabling triggers save project window on exiting editor. Sometimes it can be annoying.

# Example using arguments
In scenario where you need to have two instances with different accounts to login. For first instance add "--test-player Andrej" in arguments on settings window and for second "--test-player John"
```
if has_node("/root/MinstanceAutoload"): # check if Minstance autoload is present
  var minstance = get_node("/root/MinstanceAutoload") # get Minstance autoload node
  var test_player = minstance.get_minstance_value_from_args("--test-player") # retrieve value from instance arguments

  match test_player:
    "Andrej":
      email = "andrej@test.com"
      password = "reallybigpassword123"

      print("Using test player account Andrej")

    "John":
      email = "john@test.com"
      password = "reallybigpassword123"

      print("Using test player account John")
```
# Minstance Outputs
For every instance there is a output in Minstance Outputs that is located in bottom panel.

![image](https://user-images.githubusercontent.com/122531384/217034466-620f5243-1153-44cd-9f28-750d3c378ee5.png)
# Debug panel
Debug panel is slightly modified. From left, there is a list of instances and their statuses. Clicking on instance sets the active instance for the debug panel. Next is live scene tree view for active instance and rest is similar like in normal debug panel except two added buttons in upper right corner. "Bring to front instances" button brings instances to front and the lock icon next to him locks instances so that they stay in front, handy when changing values in the inspector. If a break occurs, the lock will be unlocked.

![image (1)](https://user-images.githubusercontent.com/122531384/217051196-6cc6e66e-4822-40ca-a9bb-0003ce51c658.png)


# Setting breakpoints
In the code editor in the upper right corner there is an option button (list) of instances to choose which the breakpoints refer to. If you place in default, that breakpoint will be for normal run.

![Animation](https://user-images.githubusercontent.com/122531384/217039726-33e784f2-75e3-4622-b512-d596cc90594a.gif)



