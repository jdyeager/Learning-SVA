# Buttons

This project was a sort of minimal "incorporating input" type of project.

The FPGA that I bought (Cmod A7-35t) has 2 buttons, 2 green LEDS, and 1 RGB LED.
My idea was to have each button drive their own basic LED,
and the state of the two of them combined drive the RGB LED.

The most interesting thing to me here was connecting arrays to arrays,
and the fact that an LED colour can be setting to components to the negation of what I might have expected (gotta check the specs).

## Testbench (TODO)

I haven't done this yet,
but I think something that just assesses that the outputs are correct
for each of the button input combinations seems reasonable.

## Assertions (TODO)

As above, asserting the outputs are as desired seems reasonable.
Moreover, I could assert that the RGB colours yellow, cyan, magenta,
and white are impossible.