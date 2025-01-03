`timescale 1ns / 1ps

`define I2C_PROCESS_MESSAGE_NULL   0
`define I2C_PROCESS_MESSAGE_START  1
`define I2C_PROCESS_MESSAGE_VALUE  2
`define I2C_PROCESS_MESSAGE_ACK    3
`define I2C_PROCESS_MESSAGE_NACK   4
`define I2C_PROCESS_MESSAGE_RSTART 5
`define I2C_PROCESS_MESSAGE_STOP   6
`define I2C_PROCESS_MESSAGE_ERROR  7


module test_message_decoder;

    localparam HALF_CYCLE = 5;
    localparam FULL_CYCLE = HALF_CYCLE * 2;
    
    localparam I2C_PROCESS_MESSAGE_NULL   = 0;
    localparam I2C_PROCESS_MESSAGE_START  = 1;
    localparam I2C_PROCESS_MESSAGE_VALUE  = 2;
    localparam I2C_PROCESS_MESSAGE_ACK    = 3;
    localparam I2C_PROCESS_MESSAGE_NACK   = 4;
    localparam I2C_PROCESS_MESSAGE_RSTART = 5;
    localparam I2C_PROCESS_MESSAGE_STOP   = 6;
    localparam I2C_PROCESS_MESSAGE_ERROR  = 7;
    
    
    reg clk = 0;
    reg [3:0] type = 0;
    reg [7:0] value = 0;
    reg reset = 0;
    wire [31:0] ascii;
    wire valid;
    
    message_decoder i_message_decoder
    (
        .clk(clk),
        .message_type(type),
        .value(value),
        .reset(reset),
        .ascii(ascii),
        .valid(valid)
    );
    
    initial
    begin
        reset = 1;
        // get past global reset period (GSR)
        #100
        // Do reset
        #FULL_CYCLE   
        reset = 0;
        //
        type = I2C_PROCESS_MESSAGE_START;
        #FULL_CYCLE;
        if (ascii == "STAR")
        begin
            $display("STAR ASSERTION PASSED in %m");
        end
        else
        begin
            $display("STAR ASSERTION FAILED in %m");
        end
        type = I2C_PROCESS_MESSAGE_NULL;
        #FULL_CYCLE;
        
        type = I2C_PROCESS_MESSAGE_VALUE;
        value = 8'h1D;
        #FULL_CYCLE;
        if (ascii == "0x1d")
        begin
            $display("0x1d ASSERTION PASSED in %m");
        end
        else
        begin
            $display("0x1d ASSERTION FAILED in %m");
        end
        type = I2C_PROCESS_MESSAGE_NULL;
        #FULL_CYCLE;        
    end
    
    always 
    begin
        #HALF_CYCLE clk = ~clk;
    end    
endmodule
