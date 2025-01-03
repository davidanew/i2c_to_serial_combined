`timescale 1ns / 1ps

module top_generic
    (
        input clk,
        input reset,
        input scl,
        input sda,
        output tx
    );
    
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
    
    wire [3:0] message_type;
    wire [7:0] value;
    
    i2c_process i_i2c_process
    (
        .clk(clk),
        .sda(sda_filt),
        .scl(scl_filt),
        .reset(reset),
        .message_type(message_type),
        .value(value)
    );
    
    wire [31:0] ascii;
    wire message_valid;
    
    message_decoder i_message_decoder
    (
         .clk(clk),
         .message_type(message_type),
         .value(value),
         .reset(reset),
         .ascii(ascii),
         .valid(message_valid)
    );
    
    buffered_uart i_buffered_uart
    (
        .clk(clk),
        .data(ascii),
        .data_valid(message_valid),
        .reset(reset),
        .tx_signal(tx)
    );
endmodule
