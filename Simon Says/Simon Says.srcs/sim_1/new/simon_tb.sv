`timescale 1ns / 100ps
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

typedef enum {NONE, RIGHT, LEFT, BOTH} lr;
typedef enum {WHITE, YELLOW, MAGENTA, RED, CYAN, GREEN, BLUE, BLACK} acol;

reg clk;
reg [1:0] btns;
wire [1:0] leds;
wire [0:2] rgb_led;

simon game (.clk (clk),.btns (btns),.leds (leds),.rgb_led (rgb_led));
always #2 clk <= ~clk;

// Something is wrong with direct enum asignment to an enum,
//   even when all options are in range.
//   (lr btns_en = 0; was illegal for instance)
// Actually, the typedef enum [n:m] seems illegal (based on an error log I got)
// So bootleg it with a function
function lr get_lr;
    input reg [1:0] vals;
    case (vals)
        2'b00: return NONE;
        2'b01: return RIGHT;
        2'b10: return LEFT;
        2'b11: return BOTH;
    endcase
endfunction

lr btns_en;
assign btns_en = get_lr(btns);

lr leds_en;
assign leds_en = get_lr(leds);

function acol get_acol;
    input reg [0:2] vals;
    case (vals)
        3'b000: return WHITE;
        3'b001: return YELLOW;
        3'b010: return MAGENTA;
        3'b011: return RED;
        3'b100: return CYAN;
        3'b101: return GREEN;
        3'b110: return BLUE;
        3'b111: return BLACK;
    endcase
endfunction

acol rgb_en;
assign rgb_en = get_acol(rgb_led);

// Set timing parameters
defparam  game.LV_CODE_ON_DUR = 24'h5; // 24'h500000;
defparam  game.LV_CODE_OFF_DUR = 24'h3; // 24'h200000;
defparam  game.RES_ON_DUR = 24'h5; // 24'h280000;
defparam  game.RES_OFF_DUR = 24'h3; // 24'h100000;
defparam  game.RES_FINAL_OFF_DUR = 24'h4; // 24'h500000;
defparam  game.SOLN_ON_DUR = 24'h3; // 24'h600000;
defparam  game.SOLN_OFF_DUR = 24'h3; // 24'h1C0000;
defparam  game.ECHO_DUR = 24'h2; // 24'h180000;
defparam  game.IDLE_DELAY_DUR = 24'h3; // 24'h400000;
defparam game.INITIAL_SEQ = 66'b110001111101011010100001100110001011101010110010000111010101101100;

function void check_leds;
    input lr exp_leds;
    input acol exp_rgb_led;
    input string extra;
    // TODO: string formatting for better info
    assert (exp_leds == get_lr(leds)) else $error({"LED check failed: ",extra});
    assert (exp_rgb_led == get_acol(rgb_led)) else $error({"LED check failed: ",extra});
endfunction
    
reg [0:65] soln;
integer i;
integer j;

// YELLOW, MAGENTA, CYAN, WHITE

//always
initial begin
    clk <= 0;
    btns <= 2'b00;
    
    // White on start (checks after rising edge)
    #3 check_leds(NONE, WHITE, "Boot Victory");
    
    // Check freeze trigger
    #2 btns <= 2'b11;
    #2 check_leds(NONE, BLUE, "Freeze");
    assert (game.state == game.FREEZE) else $error("Not frozen");
    
    // Check the reset requires both releases
    #2 btns <= 2'b10;
    #2 check_leds(NONE, BLUE, "Freeze (cont)");
    assert (game.state == game.FREEZE) else $error("Premature unfreeze");
    #2 btns <= 2'b01;
    #2 check_leds(NONE, BLUE, "Freeze (cont)");
    assert (game.state == game.FREEZE) else $error("Premature unfreeze");
    
    // Enter reset state
    #2 btns <= 2'b00;
    #2 check_leds(NONE, BLUE, "Reset");
    assert (game.state == game.RESET) else $error("Reset not triggered");
    
    #4;
    
    // ------ START ------ 
    
    for (i = 0; i < 64; i = i + 1) begin
        
        check_leds(NONE, BLACK, "Display Setup (Level)");
        assert (game.state == game.DISPLAY_SETUP) else $error("Reset not complete");
        assert (game.display == game.LEVEL) else $error("Reset not complete ()");
        assert (game.level == i) else $error("Reset not complete (level)");
        assert (game.streak == 0) else $error("Reset not complete (streak)");
        soln <= game.simon_seq;
        
        #4;
        
        for (j = 0; j < 3; j = j + 1) begin
            
            check_leds(NONE, get_acol(3'b1 << ((game.level & (6'h3 << 2*(2-j))) >> 2*(2-j))), "Display On");
            assert (game.state == game.DISPLAY) else $error("Not in display mode");
            assert (game.display == game.LEVEL) else $error("Not in level display mode");
            assert (game.counter == game.LV_CODE_ON_DUR + game.LV_CODE_OFF_DUR - 1) else $error("Display counter misbehaving");
            
            #(4*game.LV_CODE_ON_DUR);
            
            check_leds(NONE, BLACK, "Display Off");
            assert (game.state == game.DISPLAY) else $error("Not in display mode");
            assert (game.display == game.LEVEL) else $error("Not in level display mode");
            assert (game.counter == game.LV_CODE_OFF_DUR - 1) else $error("Display counter misbehaving");
            
            #(4*game.LV_CODE_OFF_DUR);
            
        end
        
        check_leds(NONE, BLACK, "Listen Setup (Idle)");
        assert (game.state == game.LISTEN_SETUP) else $error("Not entering idle");
        assert (game.listen == game.IDLE) else $error("Not entering idle");
        
        #4 check_leds(NONE, BLUE, "Listen (Idle)");
        assert (game.state == game.LISTEN) else $error("Not idle");
        assert (game.listen == game.IDLE) else $error("Not idle");
        
        #2 btns <= 2'b10;
        #4 btns <= 2'b00;
        #2 check_leds(NONE, BLACK, "Listen (Idle)");
        assert (game.state == game.LISTEN_DELAY) else $error("Idle not over");
        assert (game.counter == game.IDLE_DELAY_DUR - 1) else $error("Display counter misbehaving");
        
        #(4*game.IDLE_DELAY_DUR);
        
        check_leds(NONE, BLACK, "Display Setup (Seq)");
        assert (game.state == game.DISPLAY_SETUP) else $error("Not moving onto sequence display");
        assert (game.display == game.SEQ) else $error("Not moving onto sequence display");
        
        #4;
        
        for (j = 0; j < game.level + 3; j = j + 1) begin
            
            check_leds(get_lr(2'b01+soln[j]), BLACK, "Display (Seq) On");
            assert (game.state == game.DISPLAY) else $error("Not displaying sequence");
            assert (game.display == game.SEQ) else $error("Not displaying sequence");
            
            #(4*game.SOLN_ON_DUR);
            
            check_leds(NONE, BLACK, "Display (Seq) Off");
            assert (game.state == game.DISPLAY) else $error("Not displaying sequence");
            assert (game.display == game.SEQ) else $error("Not displaying sequence");
            
            #(4*game.SOLN_OFF_DUR);
            
        end
        
        check_leds(NONE, BLACK, "Listen Setup (Inp)");
        assert (game.state == game.LISTEN_SETUP) else $error("Not starting to listen to input");
        assert (game.listen == game.INP) else $error("Not starting to listen to input");
        
        #4 check_leds(NONE, BLACK, "Listen (Inp)");
        assert (game.state == game.LISTEN) else $error("Not starting to listen to input");
        assert (game.listen == game.INP) else $error("Not starting to listen to input");
        
        #4;
        
        // TODO: faster, interupting inputs once 1-cylce phases are cut out
        // TODO: check streak
        for (j = 0; j < game.level + 3; j = j + 1) begin
            
            #2 btns <= 2'b01 + soln[j];
            #2;btns <= 2'b00;
            
            #4 check_leds(NONE, BLACK, "Check");
            assert (game.state == game.CHECK) else $error("Not checking input");
            
            if (j < game.level + 2) begin
                #4 check_leds(get_lr(2'b01+soln[j]), BLACK, "Echoing Input");
                
                #(4*(game.ECHO_DUR-1));
            end
        end
        
        #4 check_leds(NONE, BLACK, "Display Setup (Result)");
        assert (game.state == game.DISPLAY_SETUP) else $error("Not moving onto result display");
        assert (game.display == game.RESULT) else $error("Not moving onto result display");
            
        #4;
        
        for (j = 0; j < 3; j = j + 1) begin
            
            if (j == 0) begin
                check_leds(get_lr(2'b01+soln[i+2]), GREEN, "Display (Result + Echo)");
                assert (game.state == game.DISPLAY) else $error("Not displaying echo and result");
                assert (game.display == game.RESULT) else $error("Not displaying echo and result");
                
                #(4*game.ECHO_DUR);
                check_leds(NONE, GREEN, "Display (Result)");
                #(4*(game.RES_ON_DUR-game.ECHO_DUR));
            end else begin
                check_leds(NONE, GREEN, "Display (Result)");
                #(4*game.RES_ON_DUR);
            end
            
            check_leds(NONE, BLACK, "Display (Result) Off");
            
            if (j < 2) #(4*game.RES_OFF_DUR);
            else #(4*game.RES_FINAL_OFF_DUR);
        
        end
        
    end
        
    check_leds(NONE, BLACK, "Listen Setup (Victory)");
    assert (game.state == game.LISTEN_SETUP) else $error("Not entering idle");
    assert (game.listen == game.VICTORY) else $error("Not entering idle");
    
    #4 check_leds(NONE, WHITE, "Listen (Victory)");
    assert (game.state == game.LISTEN) else $error("Not idle");
    assert (game.listen == game.VICTORY) else $error("Not idle");
    
    #9 $finish;
end

endmodule
