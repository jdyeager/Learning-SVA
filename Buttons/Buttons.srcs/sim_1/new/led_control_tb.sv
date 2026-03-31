`timescale 10ns / 1ns
// 1 clock cycle is #8.33 

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/31/2026 11:11:37 AM
// Design Name: 
// Module Name: led_control_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module led_control_tb();

reg [1:0] btns;

wire [1:0] leds;
wire rgb_led_r;
wire rgb_led_g;
wire rgb_led_b;

led_control uut (
    .btns (btns),
    .leds (leds),
    .rgb_led_r (rgb_led_r),
    .rgb_led_g (rgb_led_g),
    .rgb_led_b (rgb_led_b)
);

initial begin

// The test would idaelly be in a for loop.
// But in this case by having everything be hard-coded
//   and explicit, I don't double-up on the formulas
//   from the implementation.
// Having test code differ from the code being tested
//   helps the sanity checking of it all.

#1
btns[1] <= 1'b0;
btns[0] <= 1'b0;
#1
assert (leds[1] == 1'b0) else $error("Bad led[1] for btns 2'b00");
assert (leds[0] == 1'b0) else $error("Bad led[0] for btns 2'b00");
assert (~rgb_led_r == 1'b0) else $error("Bad rgb_led_r for btns 2'b00");
assert (~rgb_led_g == 1'b0) else $error("Bad rgb_led_g for btns 2'b00");
assert (~rgb_led_b == 1'b0) else $error("Bad rgb_led_b for btns 2'b00");

#1
btns[1] = 1'b0;
btns[0] = 1'b1;
#1
assert (leds[1] == 1'b0) else $error("Bad led[1] for btns 2'b01");
assert (leds[0] == 1'b1) else $error("Bad led[0] for btns 2'b01");
assert (~rgb_led_r == 1'b1) else $error("Bad rgb_led_r for btns 2'b01");
assert (~rgb_led_g == 1'b0) else $error("Bad rgb_led_g for btns 2'b01");
assert (~rgb_led_b == 1'b0) else $error("Bad rgb_led_b for btns 2'b01");

#1
btns[1] = 1'b1;
btns[0] = 1'b0;
#1
assert (leds[1] == 1'b1) else $error("Bad led[1] for btns 2'b10");
assert (leds[0] == 1'b0) else $error("Bad led[0] for btns 2'b10");
assert (~rgb_led_r == 1'b0) else $error("Bad rgb_led_r for btns 2'b10");
assert (~rgb_led_g == 1'b1) else $error("Bad rgb_led_g for btns 2'b10");
assert (~rgb_led_b == 1'b0) else $error("Bad rgb_led_b for btns 2'b10");

#1
btns[1] = 1'b1;
btns[0] = 1'b1;
#1
assert (leds[1] == 1'b1) else $error("Bad led[1] for btns 2'b11");
assert (leds[0] == 1'b1) else $error("Bad led[0] for btns 2'b11");
assert (~rgb_led_r == 1'b0) else $error("Bad rgb_led_r for btns 2'b11");
assert (~rgb_led_g == 1'b0) else $error("Bad rgb_led_g for btns 2'b11");
assert (~rgb_led_b == 1'b1) else $error("Bad rgb_led_b for btns 2'b11");

#1 $finish;

end

endmodule
