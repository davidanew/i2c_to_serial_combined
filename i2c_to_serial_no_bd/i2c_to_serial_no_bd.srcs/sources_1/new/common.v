`timescale 1ns / 1ps

// Output message type
`define I2C_PROCESS_MESSAGE_NULL   0
`define I2C_PROCESS_MESSAGE_START  1
`define I2C_PROCESS_MESSAGE_VALUE  2
`define I2C_PROCESS_MESSAGE_ACK    3
`define I2C_PROCESS_MESSAGE_NACK   4
`define I2C_PROCESS_MESSAGE_STOP   6
`define I2C_PROCESS_MESSAGE_ERROR  7

`define CLK_HALF_CYCLE = 5;
`define CLK_FULL_CYCLE = 10;

// UART frequency 2500 cycles for 9600 (lattice 48Mhz/2)
`define UART_COUNTS_PER_BIT 1