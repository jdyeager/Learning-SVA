`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/02/2026 10:22:06 AM
// Design Name: 
// Module Name: strobe
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


module strobe(input clk, input [1:0] btns, output [1:0] leds, output [0:2] rgb_led);

//1 sec:      12_000_000;    B71B00
//5 sec:      60_000_000;   3938700
//1 min:     720_000_000;  2AEA5400
//5 min:   3_600_000_000;  D693A400
//10 min:  7_200_000_000; 1AD274800
//15 min: 10_800_000_000; 283BAEC00
//30 min: 21_600_000_000; 50775D800
//1 hour: 43_200_000_000; A0EEBB000
reg [35:0] counter = 0;
reg [35:0] threshs [0:3];
initial begin
    threshs[0] = 36'd3_600_000_000;
    threshs[1] = 36'd7_200_000_000;
    threshs[2] = 36'd10_800_000_000;
    threshs[3] = 36'd21_600_000_000;
end

reg [23:0] strobe_counter = 0;

wire snooze;
reg old_snooze = 0;
assign snooze = btns[1];

wire toggle;
reg old_toggle = 0;
assign toggle = btns[0];

reg [1:0] mode = 0;
assign leds = mode;

wire strobe_on;
assign strobe_on = counter > threshs[mode];

reg [0:2] strobe_col = 3'b111;
assign rgb_led = strobe_on ? ~strobe_col : ~3'b000;

always @ (posedge clk) begin
    old_toggle <= toggle;
    if (!toggle && old_toggle) //falling edge
        mode <= mode + 1;
end

always @ (posedge clk) begin
    old_snooze <= snooze;
end

always @ (posedge clk)
    counter <= (!snooze && old_snooze) ? 0 : counter + (counter == 36'hFFFFFFFFF ? 0 : 1);

always @ (posedge clk) begin
    if (strobe_counter == 24'd2_000_000) begin
        strobe_counter <= 0;
        strobe_col <= {strobe_col[1] ^ strobe_col[2], strobe_col[0:1]};
        // 111 -> 011 -> 001 -> 100 -> 010 -> 101 -> 110 --> 111
    end else begin
        strobe_counter <= strobe_counter + 1;
    end
end

endmodule
