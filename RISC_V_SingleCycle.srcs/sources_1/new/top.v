`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.03.2026 23:17:10
// Design Name: 
// Module Name: top
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


module top(
input clk, reset
    );
wire [31:0]pc_out, instruction, ReadData1, ReadData2, ImmExt, ALU_result, MemData_out,mux2out,mux1out, mux3out;
wire RegWrite,MemRead,Branch,MemtoReg,MemWrite, ALUSrc,zero;
wire [1:0]ALUOp;
wire [3:0]ALU_control;
wire [31:0]nextPC, Sum;

PC pc(
  .clk(clk),
  .reset(reset),
  .PC_in(mux3out),
  .PC_out(pc_out)
    );
    
PCplus4 pcplus4(
 .fromPC(pc_out),
 .nextPC(nextPC)
);

Instruction_Mem ins_mem(
 .clk(clk),
 .reset(reset),
 .read_address(pc_out),
 .instruction_out(instruction)
);

Register_file reg_file(
 .clk(clk),
 .reset(reset),
 .RegWrite(RegWrite),
 .Rs1(instruction[19:15]),
 .Rs2(instruction[24:20]),
 .Rd(instruction[11:7]),
 .write_data(mux2out),
 .read_data1(ReadData1),
 .read_data2(ReadData2)
);

ImmGen immgen(
 .opcode(instruction[6:0]),
 .instruction(instruction),
 .ImmExt(ImmExt)
);

Control_Unit cu(
 .instruction(instruction[6:0]),
 .Branch(Branch), .MemRead(MemRead), .MemtoReg(MemtoReg), .MemWrite(MemWrite), .ALUSrc(ALUSrc), .RegWrite(RegWrite),
 .ALUOp(ALUOp)  
);

ALU_unit alu_unit(
 .A(ReadData1),.B(mux1out),
 .Control_in(ALU_control),
 .ALU_Result(ALU_result),
 .zero(zero)
);

ALU_Control alu_control(
 .ALUOp(ALUOp),
 .func7(instruction[30]),
 .func3(instruction[14:12]),
 .Control_out(ALU_control)
);

Data_Memory data_memory(
 .clk(clk), .reset(reset),
 .MemRead(MemRead), .MemWrite(MemWrite), 
 .Address(ALU_result), .Write_data(ReadData2),
 .MemData_out(MemData_out)
);

Mux1 mux1(
.ALUSrc(ALUSrc),
.A(ReadData2),.B(ImmExt),
.Mux_out(mux1out)
);

Mux3 mux3(
.Branch(Branch),
.zero(zero),
.A(nextPC),.B(Sum),
.Mux_out(mux3out)
);


Mux2 mux2(
.MemtoReg(MemtoReg),
.A(MemData_out),.B(ALU_result),
.Mux_out(mux2out)
);


Adder adder(
 .in1(pc_out),.in2(ImmExt),
 .adder_out(Sum) 
);

endmodule

