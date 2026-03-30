`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/02/2026 12:18:18 PM
// Design Name: 
// Module Name: led_control
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


module led_control(input [1:0] btns, output [1:0] leds, output rgb_led_r, output rgb_led_g, output rgb_led_b);
    
assign leds = btns;
assign rgb_led_r = ~(~btns[1] & btns[0]);
assign rgb_led_g = ~(btns[1] & ~btns[0]);
assign rgb_led_b = ~(btns[1] & btns[0]);
    
endmodule
