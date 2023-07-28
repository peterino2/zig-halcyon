# Halcyon

Hello! This project is WIP. Temporarily on hold while I'm tackling other tasks.
But it has been used in a game already.

Halcyon is a text based scripting language intended for scripting interactive content.

Featuring a simple syntax for writing branching dialogue and sprinkling in interactivity.
Meant to be similar to renpy or Inkle but not needing a C# runtime.

have a sneak peek of the syntax here:

```
[start] # labels can be assigned to a node
$: Hello! I am the narrator.
$: You can use the dollar sign to signify a line of dialogue.
    You can tab-in with 4 spaces to signify a longer piece of dialogue.

[decision]
$: Do you like cats or dogs?
    # decisions and sublines can be added by tabbing once over.
    > Cats: 
        $ Guess we can't be friends
        @goto leave_disgusted
    > Dogs: 
        @goto dogs # inline comments can be done this way 
    > Both: 
        $: That's incredibly silly. You can't pick both!
        @goto decision

[dogs] 
    $: They taste delicious! # segments of the script can be decorated with tags
    $chong: You take that back! # $$ is the narrator or default voice, $<name> will specify a specific character
```

An actual real world example is located [here](https://github.com/peterino2/NeonWood/blob/cognesia-final/engine/content/story.halc)
