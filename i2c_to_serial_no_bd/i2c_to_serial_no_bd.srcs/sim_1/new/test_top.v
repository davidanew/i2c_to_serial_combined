`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.03.2025 16:28:52
// Design Name: 
// Module Name: test_top
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


module test_top;
    localparam INPUT_CLOCK_MHz = 24.0;
    localparam FULL_CYCLE = 1000.0 / INPUT_CLOCK_MHz;
    localparam HALF_CYCLE = FULL_CYCLE / 2.0;

    localparam UART_RX_BAUD = 9600.0;
    // What the period would be for a normal clock for this
    localparam UART_RX_PERIOD_NOMINAL = 1000000000/UART_RX_BAUD;
    // Actual clock period for uart rx needs to be 16x less and div 2 for half cycle
    localparam UART_RX_HALF_CYCLE = UART_RX_PERIOD_NOMINAL/32;
    
    reg clk = 0;
    reg reset = 0;
    wire scl;
    wire sda;
    wire tx; 
    // clock for test only uart rx
    reg uart_rx_clk = 0;
    // For test only uart data out
    wire [7:0] uart_rx_data_out;

    // TODO: make call fomat consistant

    top i_top
    (
        .clk(clk),
        .reset(reset),
        .scl(scl),
        .sda(sda),
        .tx(tx)
    );

    // Just used for checking the output
    uart_rx i_uart_rx
        (.clk(uart_rx_clk),
        .reset(reset),
        .serial_in(tx),
        .data_out(uart_rx_data_out),
        .data_ready());  
  
    always 
    begin
        #HALF_CYCLE clk <= ~clk;
    end 

    // Clock for output reader
    always
    begin
        #UART_RX_HALF_CYCLE uart_rx_clk = ~uart_rx_clk;
    end
    
    initial
    begin

        $dumpfile("test_top.vcd"); // Dump to this file
        $dumpvars(0, test_top); // Dump all signals in the testbench
        $display ("INPUT_CLOCK_MHz = %f", INPUT_CLOCK_MHz); 
        $display ("FULL_CYCLE = %f", FULL_CYCLE); 
        $display ("HALF_CYCLE = %f", HALF_CYCLE);

        $display ("Test uart rx baud rate = %f", UART_RX_BAUD); 
        $display ("Nominal clock period for above = %f", UART_RX_PERIOD_NOMINAL); 
        $display ("Half clock period (16x less and half period) = %f", UART_RX_HALF_CYCLE);     

        #HALF_CYCLE
        reset = 1;
        #FULL_CYCLE    
        reset = 0;

        #100000000
        $finish;
    end 

endmodule
