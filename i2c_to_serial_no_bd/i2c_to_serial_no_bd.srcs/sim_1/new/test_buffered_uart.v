`timescale 1ns / 1ps



module test_buffered_uart;

    localparam INPUT_CLOCK_MHz = 48.0/2.0;
    localparam FULL_CYCLE = 1000.0 / INPUT_CLOCK_MHz;
    localparam HALF_CYCLE = FULL_CYCLE / 2.0;

    reg clk = 0;
    reg [31:0]data = 0;
    reg data_valid = 0;
    reg reset = 0;
    wire tx_signal;

    buffered_uart i_buffered_uart
        (.clk(clk),
        .data(data),
        .data_valid(data_valid),
        .reset(reset),
        .tx_signal(tx_signal));
     
    //defparam i_buffered_uart.i_uart_tx.UART_COUNTS_PER_BIT = 1;   
   
    initial
    begin
        $display ("INPUT_CLOCK_MHz = %f", INPUT_CLOCK_MHz); 
        //$display ("INPUT_CLOCK_GHz = %f", INPUT_CLOCK_GHz); 
        $display ("FULL_CYCLE = %f", FULL_CYCLE); 
        $display ("HALF_CYCLE = %f", HALF_CYCLE); 
   
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
