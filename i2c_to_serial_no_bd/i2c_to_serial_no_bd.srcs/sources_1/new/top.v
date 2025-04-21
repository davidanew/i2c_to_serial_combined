`timescale 1ns / 1ps

module top
    (
        input clk,
        input reset,
        output scl,
        output sda,
        output tx
    );

    i2c_example_gen i_i2c_example_gen
    (
        .clk(clk),
        .reset(reset),
        .scl(scl),
        .sda(sda)
    );
    
    top_generic i_top_generic
    (
        .clk(clk),
        .reset(reset),
        .scl(scl),
        .sda(sda),
        .tx(tx)
    );
        
endmodule
