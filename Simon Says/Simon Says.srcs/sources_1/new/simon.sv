`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/05/2026 05:09:32 PM
// Design Name: 
// Module Name: simon
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

// Links with global advice to refer back to
// https://www.reddit.com/r/FPGA/comments/1f372ju/mixing_blocking_and_nonblocking_assignments_in/

module simon(input clk, input [1:0] btns, output [1:0] leds, output [0:2] rgb_led);

reg [0:2] anti_colour = 3'b000;
assign rgb_led = anti_colour;

reg [0:1] proxy_leds = 2'b00;
assign leds = proxy_leds;

typedef enum {FREEZE, DISPLAY, LISTEN, LISTEN_DELAY} game_state;
typedef enum {NA_DISPLAY, LEVEL, SEQ, RESULT} display_state;
typedef enum {NA_LISTEN, IDLE, INP, VICTORY} listen_state;

// Constants so I stop messing up the inverted colours
localparam ABLACK = 3'b111;
localparam ARED = 3'b011;
localparam AGREEN = 3'b101;
localparam ABLUE = 3'b110;
localparam AWHITE = 3'b000;

// Timing parameters
parameter LV_CODE_ON_DUR = 24'h500000;
parameter LV_CODE_OFF_DUR = 24'h200000;
parameter RES_ON_DUR = 24'h280000;
parameter RES_OFF_DUR = 24'h100000;
parameter RES_FINAL_OFF_DUR = 24'h500000;
parameter SOLN_ON_DUR = 24'h600000;
parameter SOLN_OFF_DUR = 24'h1C0000;
parameter ECHO_DUR = 24'h180000;
parameter IDLE_DELAY_DUR = 24'h400000;
parameter INITIAL_SEQ = 66'b0;

typedef struct {
    reg [0:2] acol;
    reg [1:0] led_on;
    reg [23:0] on_dur;
    reg [23:0] off_dur;
} rgbt;

game_state state = LISTEN;
display_state display = NA_DISPLAY;
listen_state listen = VICTORY;

reg [5:0] level;
reg [6:0] seq_len;
assign seq_len = level + 3;
reg [6:0] streak = 0;

reg [65:0] lfsr = INITIAL_SEQ;
reg [0:65] simon_seq;
reg inp;
logic correct;

rgbt light_coms [0:(3+4+66)-1];

genvar i;
generate
// Level Sequence
for (i = 0; i < 3; i = i + 1) begin
    assign light_coms[i].led_on = 2'b00;
    assign light_coms[i].on_dur = LV_CODE_ON_DUR;
    assign light_coms[i].off_dur = LV_CODE_OFF_DUR;
end

for (i = 4; i < 7; i = i + 1)
    assign light_coms[i].led_on = 2'b00;

assign light_coms[3].on_dur = ECHO_DUR;
assign light_coms[4].on_dur = RES_ON_DUR - ECHO_DUR;
for (i = 5; i < 7; i = i + 1)
    assign light_coms[i].on_dur = RES_ON_DUR;

assign light_coms[3].off_dur = 24'h000000;
for (i = 4; i < 6; i = i + 1)
    assign light_coms[i].off_dur = RES_OFF_DUR;
assign light_coms[6].off_dur = RES_FINAL_OFF_DUR;

// Solution Sequence
for (i = 7; i < 73; i = i + 1) begin
    assign light_coms[i].acol = ABLACK;
    assign light_coms[i].led_on = 2'b01 << simon_seq[i-7];
    assign light_coms[i].on_dur = SOLN_ON_DUR;
    assign light_coms[i].off_dur = SOLN_OFF_DUR;
end
endgenerate

logic freeze_trigger;
assign freeze_trigger = btns[0] & btns[1];

integer light_idx, light_end;
reg [23:0] counter;

reg [1:0] btns_old;
reg [1:0] fall_edges;
assign fall_edges = btns_old & ~btns;

logic echo;
reg [23:0] echo_counter;

function void update_level;
    input reg [5:0] nlv;
    level = nlv;
    for (int j = 0; j < 3; j++) begin
        light_coms[j].acol = 3'b001 << ((nlv >> (4 - 2*j)) % 4);
    end
endfunction

// inclusive start index
function integer get_start_idx;
    input display_state dsp;
    case (dsp)
        LEVEL: return 0;
        SEQ: return 7;
        RESULT: return 3;
        default: return -1; // shouldn't happen
    endcase
endfunction

// inclusive end index
function integer get_end_idx;
    input display_state dsp;
    case (dsp)
        LEVEL: return 2;
        SEQ: return 6 + seq_len;
        RESULT: return 6;
        default: return -1; // shouldn't happen
    endcase
endfunction

function void set_display;
    input integer idx;
    anti_colour <= light_coms[idx].acol;
    proxy_leds <= light_coms[idx].led_on;
    counter <= light_coms[idx].on_dur + light_coms[idx].off_dur - 1;
endfunction

// ### Prepare Light Pattern ###
function void display_setup;
    input display_state dsp;
    light_idx = get_start_idx(dsp);
    set_display(light_idx);
    state <= DISPLAY;
    display <= dsp;
    listen <= NA_LISTEN;
    light_end <= get_end_idx(dsp);
endfunction

// ### Set Waiting Colour ###
function void listen_setup;
    input listen_state lst;
    btns_old <= btns;
    state <= LISTEN;
    listen <= lst;
    display <= NA_DISPLAY;
    case (lst)
        IDLE: anti_colour <= ABLUE;
        INP: anti_colour <= ABLACK;
        VICTORY: anti_colour <= AWHITE;
        default: anti_colour <= ABLACK; // shouldn't happen
    endcase
endfunction

// ### Reset Game ###
function void reset;
    update_level(6'b000000);
    display_setup(LEVEL); // uses level, also starts w/ =
    proxy_leds <= 2'b00;
    simon_seq <= lfsr;
    streak <= 7'b0000000;
    echo <= 1'b0;
    echo_counter <= 24'h000000;
endfunction

// ### Check Input ###
function void check;
    correct = (fall_edges == (simon_seq[streak] ? 2'b10 : 2'b01));
    if (correct && streak < seq_len - 1) begin
        streak <= streak + 1;
        echo <= 1'b1;
        echo_counter <= ECHO_DUR - 1;
        proxy_leds <= fall_edges;
        listen_setup(INP);
    end else begin
        light_coms[3].led_on = fall_edges;
        for (int j = 3; j < 7; j++)
            light_coms[j].acol = correct ? AGREEN : ARED;
        display_setup(RESULT);
        echo <= 1'b0;
        echo_counter <= 0;
    end
endfunction

// TODO: carve up more into functions?

// TODO: handle debouncing?

always @(posedge clk) begin
    // ### Capture Reset Command ###
    if (state != FREEZE && freeze_trigger) begin
        // On reset, freeze the game until both buttons are released
        state <= FREEZE;
        display <= NA_DISPLAY;
        listen <= NA_LISTEN;
        proxy_leds <= 2'b00;
        anti_colour <= ABLUE;
    // Freeze -> Reset on botton releases
    end else if (state == FREEZE && !btns[0] && !btns[1]) begin
        reset();
    end else if (state == DISPLAY && !freeze_trigger) begin
        if (counter == 0) begin
            if (light_idx < light_end) begin // more lights
                // blocking resolves before non-blocking
                light_idx = light_idx + 1;
                set_display(light_idx);
            // ### Transition After Display ###
            end else begin // no more lights
                if (display == LEVEL) begin
                    listen_setup(IDLE);
                end else if (display == SEQ) begin
                    listen_setup(INP);
                end else if (display == RESULT) begin
                    // ### Transition After Round ###
                    if (!correct) begin //fail
                        reset();
                    end else if (level == 6'b111111) begin //last level
                        listen_setup(VICTORY);
                    end else begin
                        update_level(level + 1);
                        display_setup(LEVEL);
                    end
                    streak <= 0;
                end
            end
        end else if (counter == light_coms[light_idx].off_dur) begin
            anti_colour <= ABLACK;
            proxy_leds <= 2'b00;
            counter <= counter - 1;
        end else
            counter <= counter - 1;
    // ### Wait For Input ###
    end else if (state == LISTEN && !freeze_trigger) begin
        btns_old <= btns;
        if (fall_edges != 2'b00) begin
            if (listen == IDLE || listen == VICTORY) begin
                state <= LISTEN_DELAY;
                anti_colour <= ABLACK;
                counter <= IDLE_DELAY_DUR - 1;
            end else if (listen == INP) begin
                check();
            end
        end else if (echo)
            if (echo_counter == 0) begin
                proxy_leds <= 2'b00;
                echo <= 1'b0;
            end else
                echo_counter <= echo_counter - 1;
    // ### Stall After Input ###
    end else if (state == LISTEN_DELAY && !freeze_trigger) begin
        if (counter > 0)
            counter <= counter -1;
        else
            if (listen == IDLE) begin
                display_setup(SEQ);
            end else if (listen == VICTORY) begin
                reset();
            end
    end
    // https://electronics.stackexchange.com/questions/30521/random-bit-sequence-using-verilog
    // https://docs.amd.com/v/u/en-US/xapp052
    lfsr <= {lfsr[64:0], ~(lfsr[65] ^ lfsr[64] ^ lfsr[56] ^ lfsr[55])};
end

endmodule
