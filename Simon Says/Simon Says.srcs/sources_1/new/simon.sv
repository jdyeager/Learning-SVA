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

reg [0:2] anti_colour = 3'b111;
assign rgb_led = anti_colour;

reg [0:1] proxy_leds = 2'b00;
assign leds = proxy_leds;

typedef enum {FREEZE, RESET, DISPLAY_SETUP, DISPLAY, LISTEN_SETUP, LISTEN, LISTEN_DELAY, CHECK} game_state;
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

game_state state = LISTEN_SETUP;
display_state display = NA_DISPLAY;
listen_state listen = VICTORY;

reg [5:0] level;
reg [6:0] seq_len;
assign seq_len = level + 3;
reg [6:0] streak;

reg [65:0] lfsr = INITIAL_SEQ;
reg [0:65] simon_seq;
reg inp;
logic correct;
assign correct = (simon_seq[streak] == inp);

rgbt light_coms [0:(3+4+66)-1];

genvar i;
generate
// Level Sequence
for (i = 0; i < 3; i = i + 1) begin
    assign light_coms[i].acol = 3'b001 << ((level >> (4 - 2*i)) % 4);
    assign light_coms[i].led_on = 2'b00;
    assign light_coms[i].on_dur = LV_CODE_ON_DUR;
    assign light_coms[i].off_dur = LV_CODE_OFF_DUR;
end

// Result Sequence
//   First "on" needs to have a baked in last-input echo
for (i = 3; i < 7; i = i + 1)
    assign light_coms[i].acol = correct ? AGREEN : ARED;

assign light_coms[3].led_on = 2'b01 << inp;
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

// TODO: rework display and display setup to timer is established during setup
//       colour will be SET during setup and be ACTIVE on display

// inclusive start index
function integer get_start_idx;
    if (display == LEVEL) begin
        return 0;
    end else if (display == SEQ) begin
        return 7;
    end else if (display == RESULT) begin
        return 3;
    end
endfunction

// inclusive end index
function integer get_end_idx;
    if (display == LEVEL) begin
        return 2;
    end else if (display == SEQ) begin
        return 6 + seq_len;
    end else if (display == RESULT) begin
        return 6;
    end
endfunction

function void set_display;
    input integer idx;
    anti_colour <= light_coms[idx].acol;
    proxy_leds <= light_coms[idx].led_on;
    counter <= light_coms[idx].on_dur + light_coms[idx].off_dur - 1;
endfunction



// TODO: get rid of setup phases? ditto reset PHASE? ditto check PHASE?
//       Any one-cycle phase seems suspect
//       have setup/segue functions?

// TODO: carve up move into functions?

// TODO: handle debouncing?

always @(posedge clk) begin
    // https://electronics.stackexchange.com/questions/30521/random-bit-sequence-using-verilog
    // https://docs.amd.com/v/u/en-US/xapp052
    lfsr <= {lfsr[64:0], ~(lfsr[65] ^ lfsr[64] ^ lfsr[56] ^ lfsr[55])};
    // ### Capture Reset Command ###
    if (state != FREEZE && state != RESET && freeze_trigger) begin
        // On reset, freeze the game until both buttons are released
        state <= FREEZE;
        display <= NA_DISPLAY;
        listen <= NA_LISTEN;
        proxy_leds <= 2'b00;
        anti_colour <= ABLUE;
    // Freeze -> Reset on botton releases
    end else if (state == FREEZE && !btns[0] && !btns[1]) begin
        state <= RESET;
    // ### Reset Game ###
    end else if (state == RESET) begin
        proxy_leds <= 2'b00;
        anti_colour <= ABLACK;
        state <= DISPLAY_SETUP;
        display <= LEVEL;
        listen <= NA_LISTEN;
        simon_seq <= lfsr;
        level <= 6'b000000;
        counter <= 24'h000000;
        streak <= 7'b0000000;
        echo <= 1'b0;
        echo_counter <= 24'h000000;
    // ### Prepare Light Pattern ###
    end else if (state == DISPLAY_SETUP && !freeze_trigger) begin
        // exclusive to inclusive ...
        //    because that somehow ended up working nicely
        light_idx = get_start_idx();
        set_display(light_idx);
//        counter <= 0;
        state <= DISPLAY;
        light_end <= get_end_idx();
//        if (display == LEVEL) begin
//            light_idx <= -1;
//            light_end <= 2;
//        end else if (display == SEQ) begin
//            light_idx <= 6;
//            light_end <= 6 + seq_len;
//        end else if (display == RESULT) begin
//            light_idx <= 2;
//            light_end <= 6;
//        end
    // ### Display Light Pattern ###
    end else if (state == DISPLAY && !freeze_trigger) begin
        if (counter == 0) begin
            if (light_idx < light_end) begin // more lights
                // blocking resolves before non-blocking
                light_idx = light_idx + 1;
                set_display(light_idx);
//                anti_colour <= light_coms[light_idx + 1].acol;
//                proxy_leds <= light_coms[light_idx + 1].led_on;
//                counter <= light_coms[light_idx + 1].on_dur + light_coms[light_idx + 1].off_dur - 1;
//                light_idx <= light_idx + 1;
            // ### Transition After Display ###
            end else begin // no more lights
                if (display == LEVEL) begin
                    state <= LISTEN_SETUP;
                    display <= NA_DISPLAY;
                    listen <= IDLE;
                end else if (display == SEQ) begin
                    state <= LISTEN_SETUP;
                    display <= NA_DISPLAY;
                    listen <= INP;
                end else if (display == RESULT) begin
                    // ### Transition After Round ###
                    if (!correct) begin
                        state <= RESET;
                        display <= NA_DISPLAY;
                    end else if (level == 6'b111111) begin
                        state <= LISTEN_SETUP;
                        listen <= VICTORY;
                        display <= NA_DISPLAY;
                    end else begin
                        state <= DISPLAY_SETUP;
                        display <= LEVEL;
                        level <= level + 1;
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
    // ### Set Waiting Colour ###
    end else if (state == LISTEN_SETUP && !freeze_trigger) begin
        btns_old <= btns;
        state <= LISTEN;
        if (echo_counter != 0) echo_counter <= echo_counter - 1;
        if (listen == IDLE) anti_colour <= ABLUE;
        else if (listen == INP) anti_colour <= ABLACK;
        else if (listen == VICTORY) anti_colour <= AWHITE;
    // ### Wait For Input ###
    end else if (state == LISTEN && !freeze_trigger) begin
        btns_old <= btns;
        if (fall_edges != 2'b00) begin
            if (listen == IDLE || listen == VICTORY) begin
                state <= LISTEN_DELAY;
                anti_colour <= ABLACK;
                counter <= IDLE_DELAY_DUR - 1;
            end else if (listen == INP) begin
                state <= CHECK;
                inp <= (fall_edges == 2'b01) ? 1'b0 : 1'b1;
                if (echo) begin
                    proxy_leds <= 2'b00;
                    echo <= 1'b0;
                    // stop current echo if somehow that fast
                    echo_counter <= 24'h000000;
                end
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
                state <= DISPLAY_SETUP;
                display <= SEQ;
                listen <= NA_LISTEN;
            end else if (listen == VICTORY) begin
                state <= RESET;
                listen <= NA_LISTEN;
            end
    // ### Check Input ###
    end else if (state == CHECK && !freeze_trigger) begin
        if (correct && streak < seq_len - 1) begin
            streak <= streak + 1;
            state <= LISTEN_SETUP;
            echo <= 1'b1;
            echo_counter <= ECHO_DUR - 1;
            proxy_leds <= 2'b01 << inp;
        end else begin
            state <= DISPLAY_SETUP;
            display <= RESULT;
            listen <= NA_LISTEN;
        end
    end
end

endmodule
