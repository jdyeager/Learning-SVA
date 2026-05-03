# Strobe Alarm

This is more of a silly program.
(This will probably be one of the more daft things some potential
employer has read.)

As context: I am trying to learn how to do a planche.
As it stands, I can only do something approximating a tucked planche
(I bet my form leaves a lot to be desired).
The thing I have found about such exercises,
is that they burn through so much of my strength,
that I have maybe one or two reps in me before I am shot for quite a while.
However, in order to actually encourage growth,
I need more practice and volume.
My current plan is one rep/attempt every 10-15 minutes,
hopefully giving plenty of cool-down time,
while still getting a good total volume.

Now, a *reasonable* person would just set an alarm.
I find the noise rather annoying, and also I need random SystemVerilog projects.
So instead I will program my FPGA to strobe out every 10 minutes,
with one button as a snooze/reset button.
The other button, will actually cycle through 4 possible timer lengths.
I choose 4 because I can have the 2 binary leds display which of the 4 it currently is.

As a verilog project, this is a good chance to try breaking things up
into
more always blocks
(as opposed my Simon Says project where everything was in one giant block).
I think I am finally internalising the intuition of blocks driving certain registers 
or wires.
