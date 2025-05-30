`timescale 1ns / 1ps

module test_top_generic;

    reg clk = 0;
    reg sda = 1;
    reg scl = 1;
    reg reset = 0;
    wire tx;

    top_generic i_top_generic
    (
        .clk(clk),
        .reset(reset),
        .scl(scl),
        .sda(sda),
        .tx(tx)
    );
    
    defparam i_top_generic.i_buffered_uart.i_uart_tx.UART_COUNTS_PER_BIT = 1;   

    localparam CLK_HALF_CYCLE = 5;
    localparam CLK_FULL_CYCLE = CLK_HALF_CYCLE * 2;
    localparam I2C_QUARTER_CYCLE = CLK_FULL_CYCLE * 16;
    localparam I2C_HALF_CYCLE = I2C_QUARTER_CYCLE * 2;
    integer i = 0;
    initial
    begin
        reset = 1;
        // get past global reset period (GSR)
        #100    
        reset = 0;
        // Start condition - sda fall during SCL high
        #I2C_QUARTER_CYCLE;
        sda = 0;
        // SCL low after delay to start data cycle
        #I2C_QUARTER_CYCLE;
        scl = 0;
        // delay for next data change
        #I2C_QUARTER_CYCLE;
        // Loop for data
        for (i = 0; i < 8; i = i + 1)
        begin 
            // Set data           
            sda = 1;
            // Toggle clock after delay
            #I2C_QUARTER_CYCLE;
            scl = 1;
            #I2C_HALF_CYCLE;
            scl = 0;
            // delay for next data or ACK/NACK
            #I2C_QUARTER_CYCLE;
        end 
        // Set ACK and toggle clock again.
        sda = 0;
        #I2C_QUARTER_CYCLE;
        scl = 1;
        #I2C_HALF_CYCLE;
        scl = 0;
        // delay for data change
        #I2C_QUARTER_CYCLE;
        // Keep data at zero as we want a rise for stop condition
        sda = 0;
        // Clock rise after delay
        #I2C_QUARTER_CYCLE;
        scl = 1;
        // Stop condition after delay.
        #I2C_QUARTER_CYCLE;
        sda = 1;
        // SDA back to idle state after delay
        //#I2C_QUARTER_CYCLE;
        //sda = 1;
        
    end
    
    always begin
        #CLK_HALF_CYCLE clk = ~clk;
    end

endmodule
