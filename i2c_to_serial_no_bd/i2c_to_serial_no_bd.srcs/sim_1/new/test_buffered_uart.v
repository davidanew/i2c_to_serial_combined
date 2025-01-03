`timescale 1ns / 1ps



module test_buffered_uart;

    localparam HALF_CYCLE = 5;
    localparam FULL_CYCLE = HALF_CYCLE * 2;

    reg clk = 0;
    reg [31:0]data = 0;
    reg data_valid = 0;
    reg reset = 0;
    wire tx_signal;

    buffered_uart buffered_uart_i
        (.clk(clk),
        .data(data),
        .data_valid(data_valid),
        .reset(reset),
        .tx_signal(tx_signal));
        
    initial
    begin
        reset = 1;
        // get past global reset period (GSR)
        #100
        // Do reset
        #FULL_CYCLE   
        reset = 0;
        //
        data = "abcd";
        data_valid = 1;
        #FULL_CYCLE
        data_valid = 0;
    end
    
    always 
    begin
        #HALF_CYCLE clk = ~clk;
    end    
endmodule
