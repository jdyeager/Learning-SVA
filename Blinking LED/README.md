# Blinking LED

To me, this is the equivalent of the Hello World program.
The goal of this is mostly just to ensure that everything (Vivado) is installed properly,
and that I am able to understand the pipeline.

To the extent that I learned something new about SystemVerilog,
it was probably learning to explicitly think about the clock speed and timing.
I had to actually do math based on my FPGA's clock speed (Cmod A7-35t, 12 MHz)
in order to get a quick blinking frequency that felt fast but parsable.
So that was a little novel.
