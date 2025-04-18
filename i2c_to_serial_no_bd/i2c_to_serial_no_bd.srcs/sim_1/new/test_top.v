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
    //localparam CLK_HALF_CYCLE = 5;
    localparam CLK_HALF_CYCLE = 10; // for 50MHz clock (~48MHz)
    localparam CLK_FULL_CYCLE = CLK_HALF_CYCLE * 2; 
    
    reg clk = 0;
    reg reset = 0;
    wire scl;
    wire sda;
    wire tx; 

    top i_top
    (
        .clk(clk),
        .reset(reset),
        .scl(scl),
        .sda(sda),
        .tx(tx)
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
