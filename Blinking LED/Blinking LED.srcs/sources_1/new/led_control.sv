`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/01/2026 08:24:55 PM
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


module led_control(input sysclk, output led);

// indices 21 to 0 (both inclusive) 
reg [21:0] count = 0;
// MSB drives LED
assign led = count[21];
// ~4 million pos edge on-off period
// 12 Mhz clock
// 1/3 of a second on-off cycle, I think
always @ (posedge(sysclk)) count <= count + 1;

endmodule
