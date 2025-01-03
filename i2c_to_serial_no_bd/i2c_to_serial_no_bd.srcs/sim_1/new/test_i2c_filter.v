`timescale 1ns / 1ps


module test_i2c_filter;

    localparam HALF_CYCLE = 5;
    localparam FULL_CYCLE = HALF_CYCLE * 2;

    reg clk = 0;
    reg reset = 0;
    reg sda = 1;
    reg scl = 1;
    wire sda_filt;
    wire scl_filt;

    i2c_filter i_i2c_filter
    (
        .clk(clk),
        .sda(sda),
        .scl(scl),
        .reset(reset),
        .sda_filt(sda_filt),
        .scl_filt(scl_filt)
    );
    
    initial 
    begin 
        reset = 1;
        // get past global reset period (GSR)
        #100
        // Do reset
        #FULL_CYCLE
        reset = 0;  
        // Integral starts at 1, wait 15 cycles with 0 input and should switch to zero.
        sda = 0;
        scl = 0;
        #(FULL_CYCLE * 15);
        // Same for high
        sda = 1;
        scl = 1;
        #(FULL_CYCLE * 15);
        // Back to low but add glitch, it should be 17 cycles in total.
        sda = 0;
        scl = 0;
        #(FULL_CYCLE * 8);
        sda = 1;
        scl = 1;
        #FULL_CYCLE;
        sda = 0;
        scl = 0;
        #(FULL_CYCLE * 9);
    end
    
    always begin
        #HALF_CYCLE clk = ~clk;
    end

endmodule