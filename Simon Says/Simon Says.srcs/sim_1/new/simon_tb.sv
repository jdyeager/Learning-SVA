`timescale 10ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/05/2026 06:15:06 PM
// Design Name: 
// Module Name: simon_tb
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


module simon_tb;

reg clk;
reg [1:0] btns;
wire [1:0] leds;
wire [0:2] rgb_led;

simon game (.clk (clk),.btns (btns),.leds (leds),.rgb_led (rgb_led));

//always
initial begin
    clk <= 0;
    btns <= 2'b0;
    #10 btns <= 2'b01;
    #10 btns <= 2'b10;
    #10 btns <= 2'b11;
    #10 btns <= 2'b00;
end

always #4 clk <= ~clk;

endmodule
