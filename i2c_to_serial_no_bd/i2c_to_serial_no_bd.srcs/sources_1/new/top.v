`timescale 1ns / 1ps

module top
    (
        input clk,
        input reset,
        output scl,
        output sda,
        output tx
    );
    wire scl;
    wire sda;
    wire tx;

    i2c_example_gen 
    #(
    .I2C_COUNTS_PER_BIT(16)
    )
    i_i2c_example_gen
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
    
    defparam i_top_generic.i_buffered_uart.i_uart_tx.UART_COUNTS_PER_BIT = 1;     
    
endmodule
