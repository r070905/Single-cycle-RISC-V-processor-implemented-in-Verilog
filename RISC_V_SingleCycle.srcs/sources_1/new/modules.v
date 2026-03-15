`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.03.2026 14:53:35
// Design Name: 
// Module Name: modules
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


module PC(
 input clk,
 input reset,
 input [31:0]PC_in,
 output reg [31:0]PC_out
    );
    always@(posedge clk or posedge reset)begin
     if(reset)PC_out <= 32'd0;
     else PC_out <= PC_in;
    end
endmodule




module PCplus4(
 input [31:0]fromPC,
 output [31:0]nextPC
);
 assign nextPC = fromPC + 32'd4;
endmodule




module Instruction_Mem(
 input clk,
 input reset,
 input [31:0]read_address,
 output reg [31:0]instruction_out
);
 
 reg [31:0]I_Mem[63:0];
 integer i;
 
 initial begin
    $display("STARTING READMEMH");
    $readmemh("program.hex", I_Mem);
    $display("DONE READMEMH");
 end
 
 always@(posedge clk /*or posedge reset*/)begin
//  if(reset)begin
//   for(i=0;i<64;i=i+1)I_Mem[i] <= 32'd0;
//  end
  
  //else begin
   instruction_out <= I_Mem[read_address[7:2]];
  //end
 end
endmodule



//Synchronous Write and Asynchronous Read(to keep it single cycle)
// Think what if Rs = Rd
module Register_file(
 input clk,
 input reset,
 input RegWrite,
 input [4:0]Rs1,
 input [4:0]Rs2,
 input [4:0]Rd,
 input [31:0]write_data,
 output [31:0]read_data1,
 output [31:0]read_data2
);

reg [31:0] Reg_Mem[31:0];
integer i;

 always@(posedge clk or posedge reset)begin
  if(reset)begin
   for(i=0;i<32;i=i+1)begin
    Reg_Mem[i] <= 32'd0;
   end
  end
   
  else begin
   if(RegWrite) begin
    Reg_Mem[Rd] <= write_data;
   end
  end
 end
 
    assign read_data1 = Reg_Mem[Rs1];
    assign read_data2 = Reg_Mem[Rs2];

endmodule




// always block so use "reg" for assigning
module ImmGen(
 input [6:0]opcode,
 input [31:0]instruction,
 output reg [31:0]ImmExt
);

always@(*)begin
 case(opcode)
   7'b0000011 : ImmExt = {{20{instruction[31]}}, instruction[31:20]}; //I-type
   7'b0100011 : ImmExt = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]}; //S-type
   7'b1100011 : ImmExt = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25],instruction[11:8], 1'b0}; //SB-type (why is LSB 0) 
   //Read about each instruction properly, what is does and how it executes
   default : ImmExt = 32'd0;
 endcase
end

endmodule




module Control_Unit(
 input [6:0]instruction,
 output reg Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite,
 output reg[1:0]ALUOp  
);
 
always@(*)begin
 
 case(instruction)
  7'b0110011: {Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite,ALUOp} = 8'b001000_10;
  7'b0000011: {Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite,ALUOp} = 8'b111100_00;
  7'b0100011: {Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite,ALUOp} = 8'b110010_00;
  7'b1100011: {Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite,ALUOp} = 8'b000001_01;
  default: {Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite,ALUOp} = 8'd0;
 endcase
end

endmodule




module ALU_unit(
 input [31:0]A,B,
 input [3:0]Control_in,
 output reg [31:0]ALU_Result,
 output reg zero
);
//always@(Control_in or A or B)begin -> sensitivity list, whenever any of these changes; * is better, what if we add another parameter c so.......
/*always@(*)begin
 case(Control_in)
  4'b0000: begin zero<=0; ALU_Result = A&B; end
  4'b0001: begin zero<=0; ALU_Result = A|B; end
  4'b0010: begin zero<=0; ALU_Result = A+B; end
  4'b0110: begin if(A==B)zero<=1; else zero<=0; ALU_Result = A-B; end
 endcase
end*/

//better and cleaner (read more about zero flag and understand the avobe code)
always@(*)begin
 case(Control_in)
  4'b0000: ALU_Result = A&B; 
  4'b0001: ALU_Result = A|B; 
  4'b0010: ALU_Result = A+B; 
  4'b0110: ALU_Result = A-B; 
  default: ALU_Result = 0;
 endcase
 zero = (ALU_Result ==0);
end

endmodule





module ALU_Control(
 input [1:0]ALUOp,
 input func7,
 input [2:0]func3,
 output reg [3:0]Control_out
);
always@(*)begin
 case({ALUOp, func7,func3})
 6'b00_0_000: Control_out = 4'b0010;
 6'b01_0_000: Control_out = 4'b0110;
 6'b10_0_000: Control_out = 4'b0010;
 6'b10_1_000: Control_out = 4'b0110;
 6'b10_0_111: Control_out = 4'b0000;
 6'b10_0_110: Control_out = 4'b0001;
 default : Control_out = 4'd0;
 endcase
end
endmodule



/*Use clk when:
The block stores data
The block has memory
The output depends on previous cycle
It is built using flip-flops

🔵 No clk when:
The block only computes
It is pure logic
Output depends only on current inputs
*/

module Data_Memory(
 input clk, reset,
 input MemRead, MemWrite, 
 input [31:0]Address, Write_data,
 output [31:0]MemData_out
);
reg [31:0] D_Memory[63:0];
integer i;

always@(posedge clk or posedge reset)begin
 if(reset)begin
  for(i=0;i<64;i=i+1)begin
   D_Memory[i]<= 32'd0; 
  end
 end 

 else if(MemWrite) D_Memory[Address[7:2]] <= Write_data;
 
end
assign MemData_out = MemRead? D_Memory[Address[7:2]]: 32'd0;

endmodule





module Mux1(
input ALUSrc,
input [31:0]A,B,
output [31:0]Mux_out
);
assign Mux_out = (ALUSrc==0)? A:B;
endmodule

module Mux2(
input MemtoReg,
input [31:0]A,B,
output [31:0]Mux_out
);
assign Mux_out = (MemtoReg==0)? B:A;
endmodule


module Mux3(
input Branch,
input zero,
input [31:0]A,B,
output [31:0]Mux_out
);
assign Mux_out = (Branch&zero)? B:A;
endmodule






module Adder(
 input [31:0] in1,in2,
 output [31:0] adder_out 
);
 assign adder_out = in1 + in2;
endmodule



