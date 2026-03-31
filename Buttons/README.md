# Buttons

This project was a sort of minimal "incorporating input" type of project.

The FPGA that I bought (Cmod A7-35t) has 2 buttons, 2 green LEDS, and 1 RGB LED.
My idea was to have each button drive their own basic LED,
and the state of the two of them combined drive the RGB LED.

The most interesting thing to me here was connecting arrays to arrays,
and the fact that an LED colour can be setting to components to the negation of what I might have expected (gotta check the specs).

## Testbench

Manually and explicitly checks the leds values for
each possible button input combination.

I chose the laborious testing parting for the repetition practice,
and parting because the efficient for-loop would just regurgitate the
main module's code; making it not really useful a test.

## Assertions (TODO)

As above, asserting the outputs are as desired seems reasonable.
Moreover, I could assert that the RGB colours yellow, cyan, magenta,
and white are impossible.