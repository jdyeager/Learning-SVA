# Simon Says

This was my first "can I make something non-trivial" type of project.

Given the FPGA has 2 buttons and 2 lights.
I decided to go for a crude, binary version of Simon Says;
the RGB LED could be used to indicate information
about the state of the game.
The idea with to have 64 "levels" (the aim being to get a high score, not "win"),
with each one adding another blink in the sequence that needs to be correctly
echoed with button presses.
The first level has 3 blinks,
so an initial pseudo-random true sequence of 66 blinks must be established for a new game.
Each level has a unique 3-blink level code before it begins, to track a "best".
Upon any mistake, the game resets (after a unique game-over blink sequence).
Upon theoretical victory, the game resets (after a unique victory blink sequence).
The game can be reset by pressing both buttons at the same time and releasing them.

## Growing Pains

When I first learned Java all the way back in high school,
I tried to make a game in Java.
In my inexperience, I made an inter-connected and tangled mess.
I didn't yet have a good command of organisation/structuring
or idiomatic behaviour.

It's been interesting to re-experience that feeling so vividly.
Naturally, just watching videos on the syntax and looking up
various features as necessary can give one the ability to make
something, but not necessarily make it **well** or idiomatically
(as deeper intuition, principals,
and lore are often not relayed as clearly or at all).

In this case, the biggest code smell to me is that all the logic is
in one, giant `always @(posedge clk)` block.
I originally did try to build things out with logical bits in their
own blocks, but ran into issues with multiple drivers for the LEDs
preventing synthesis.
This is a classic case of "a novice doesn't know the elegant solution,
so just experiments until it works";
putting everything in one block worked.
(This is an example of what I mean by deeper knowledge being lost.
the resources I found on SystemVerilog did not reveal
anything about how the language connects to actual circuit
manifestations in hardware. And so issues rooted in that are opaque
and get solved ultimately by wanton finagling.)
In hindsight, I could have had discrete blocks send information
to wires that fed into some sort of "LED driver" that was the
sole source of the the LEDs should do.
But that hindsight comes from wisdom from the knowledge/experience
gained by this more unpleasant path taken.

Another things that feels a little janky,
is the long list of strategically arranged light timings.
Some of these are very redundant or formulaic,
and so could presumably be done better.
There are also some magic numbers involved.
But maybe, at the hardware level,
that just is what it is.

Finally, the lack of randomness was an interesting challenge to deal with.
But looking up ways to do decent-enough pseudo-randomness was a fun experience.

## Test Benches (TODO)

I think a failed and a successful run through the game should be sufficient.

## Assertions (TODO)

Figuring out what I can represent how easily will
itself be a valuable learning experience.

A have a few ideas for things to prove:
- bad press leads to failure and reset
- no bad presses eventually leads to success and reset
- internal states are mutually exclusive
  - sub-states are mutually exclusive
  - sub-state are only active for their respective state
- all the "state X can only followed by states Y, Z, etc"
  - including sub-state analogues
- level n (0 to 63 inc) has a sequence of n+3 lights to echo
  - doesn't change throughout the level?
- correct presses on level n (for all but last) leads to lv n+1
  - correct final level leads to victory
- reset resets everything that it should
- maybe something about how once both buttons are pressed reset is inevitable
  (as long as play eventually releases both buttons, but state-wise only reset can follow)
- sequence can not change until a reset
- always eventually gets to a state waiting on the user input
  - given always eventually user input, eventually wins or loses
- never try to look up light index beyond the 66
- maybe all level codes are unique
