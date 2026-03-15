`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.03.2026 16:21:44
// Design Name: 
// Module Name: tb
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


module tb(

    );
    reg clk, reset;
    
    top uut(.clk(clk),.reset(reset));
    initial clk = 0;
    always #5 clk = ~clk;
    
    initial begin
    reset=1;
    #20;
    reset =0;
    #200;
    $stop;
    end
    
    
    
endmodule
