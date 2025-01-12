`timescale 1ns / 1ps

module test_i2c_example_gen;

    localparam CLK_HALF_CYCLE = 5;
    localparam CLK_FULL_CYCLE = CLK_HALF_CYCLE * 2; 
    
    reg clk = 0;
    reg reset = 0;
    wire scl;
    wire sda;   

    i2c_example_gen 
    #(
    .I2C_COUNTS_PER_BIT(1)
    )
    i_i2c_example_gen
    (
        .clk(clk),
        .reset(reset),
        .scl(scl),
        .sda(sda)
    );
    
    always 
    begin
        #CLK_HALF_CYCLE clk <= ~clk;
    end 
    
    initial
    begin
        #CLK_HALF_CYCLE
        reset = 1;
        #CLK_FULL_CYCLE    
        reset = 0;
    end; 
endmodule
 