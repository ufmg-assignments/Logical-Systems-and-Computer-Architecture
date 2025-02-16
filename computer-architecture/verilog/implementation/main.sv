/*
	O JUMP estava implementado no padrão do MIPS
	Ponto positivo: - A estrutura de controle está pronta para implementar o jump
	Ponto negativo: - Todo o aparato de endereço teria que ser implementado
*/

/*
 * cpu. - five stage MIPS CPU.
 *
 */
`include "regr.sv"
`include "im_reg.sv"
`include "alu.sv"
`include "control.sv"
`include "datam.sv"



module cpu(
    input wire clk
);

    // number of instructions in instruction memory
	parameter NMEM = 7;  
	parameter IM_DATA = "im_data.txt";

	wire regwrite_s5;
	wire [4:0] wrreg_s5;
	wire [31:0]	wrdata_s5;
	reg stall_s1_s2;

	// {{{ flush control
	reg flush_s1, flush_s2, flush_s3;
	always @(*) begin
		flush_s1 <= 1'b0;
		flush_s2 <= 1'b0;
		flush_s3 <= 1'b0;
		if (pcsrc | jump_s4) begin
			flush_s1 <= 1'b1;
			flush_s2 <= 1'b1;
			flush_s3 <= 1'b1;
		end
	end
	// }}}

	// {{{ stage 1, IF (fetch)

	// reg  [5:0] clock_counter;
	// initial begin
	// 	clock_counter <= 6'd1;
	// end
    //     always @(posedge clk) begin
    //             clock_counter <= clock_counter + 1;
	// end

	reg [31:0] pc;
    // PC inicia no endereço 0
	initial begin
		pc <= 32'd0;
	end

    // PC incrementado para a próxima intrução
	wire [31:0] pc4;  // PC + 4
	assign pc4 = pc + 4;   

    // Verifica a necessidade da inserção de uma bolha
	always @(posedge clk) begin
		if (stall_s1_s2) 
			pc <= pc;
		else if (pcsrc == 1'b1)
			pc <= baddr_s4;
		// else if (jump_s4 == 1'b1)
		// 	pc <= jaddr_s4;
		else
			pc <= pc4;
	end

	// pass PC + 4 to stage 2
	wire [31:0] pc4_s2;
	regr #(.N(32)) regr_pc4_s2(.clk(clk),
						.hold(stall_s1_s2), .clear(flush_s1),
						.in(pc), .out(pc4_s2));

	// instruction memory
	wire[31:0] inst;
	wire[31:0] inst_s2;

	im #(.NMEM(NMEM), .IM_DATA(IM_DATA))
		im1(.clk(clk), .addr(pc), .data(inst));
	regr #(.N(32)) regr_im_s2(.clk(clk),
						.hold(stall_s1_s2), .clear(flush_s1),
						.in(inst), .out(inst_s2));

	// }}}

	// {{{ stage 2, ID (decode)

// `include "decodefields.sv"

/* ------------ */
// wire [5:0]  opcode; 
wire [6:0]  opcoderv; 
// wire [4:0]  rs;     
wire [4:0]  rs1;
// wire [4:0]  rt;     
wire [4:0]  rs2;
wire [4:0]  rd;
wire [6:0] func7; 
wire [2:0] func3;
// Esse imediato tem 16 bits e não 12
// wire [15:0] imm;
// wire [4:0]  shamt;
// wire [31:0] jaddr_s2;
// wire [31:0] seimm;  // sign extended immediate


// assign opcode   = inst_s2[31:26];  
assign opcoderv = inst_s2[6:0]; 
// assign rs       = inst_s2[25:21];  
assign rs2 = inst_s2[24:20];
// assign rt       = inst_s2[20:16];  
assign rs1 = inst_s2[19:15];
assign rd       = inst_s2[11:7];
assign func7       = inst_s2[31:25];
assign func3       = inst_s2[14:12];
// assign imm      = inst_s2[15:0];
// assign shamt    = inst_s2[10:6];
// assign jaddr_s2 = {pc[31:28], inst_s2[25:0], {2{1'b0}}};
// assign seimm 	= {{16{inst_s2[15]}}, inst_s2[15:0]};

// register file
wire [31:0] data1, data2;
regm regm1(.clk(clk), .read1(rs1), .read2(rs2),
        .data1(data1), .data2(data2),
        .regwrite(regwrite_s5), .wrreg(wrreg_s5),
        .wrdata(wrdata_s5));

    // control (opcode -> ...)
wire regdst;
wire branch_eq_s2;
wire branch_ne_s2;
wire branch_lt_s2;
wire memread;
wire memwrite;
wire memtoreg;
wire [1:0]	aluop;
wire regwrite;
wire alusrc;
wire jump_s2;
wire [31:0] ImmGen;  // RISCV
//
//agora passa blt para o control
control ctl1(.opcode(opcoderv), .regdst(regdst),
            .branch_eq(branch_eq_s2), .branch_ne(branch_ne_s2), .branch_lt(branch_lt_s2),
            .memread(memread),
            .memtoreg(memtoreg), .aluop(aluop),
            .memwrite(memwrite), .alusrc(alusrc),
            .regwrite(regwrite), .jump(jump_s2), .ImmGen(ImmGen), .inst(inst_s2));

// pass rs to stage 3 (for forwarding)
wire [4:0] rs_s3;     	wire [4:0] rs1_s3;
regr #(.N(5)) regr_s2_rs(.clk(clk), .clear(1'b0), .hold(stall_s1_s2),
            .in(rs1), .out(rs1_s3));

// transfer seimm, rt, and rd to stage 3
wire [31:0] seimm_s3;
wire [4:0] 	rt_s3;    wire [4:0] rs2_s3;
wire [4:0] 	rd_s3;
regr #(.N(32)) reg_s2_seimm(.clk(clk), .clear(flush_s2), .hold(stall_s1_s2),
                    .in(ImmGen), .out(seimm_s3));  // RISCV
regr #(.N(10)) reg_s2_rt_rd(.clk(clk), .clear(flush_s2), .hold(stall_s1_s2),
                    .in({rs2, rd}), .out({rs2_s3, rd_s3}));

// shift left, seimm
// wire [31:0] seimm_sl2;
// assign seimm_sl2 = {seimm[29:0], 2'b0};  // shift left 2 bits
// branch address
wire [31:0] baddr_s2;
assign baddr_s2 = pc4_s2 + ImmGen;

wire [3:0] func_s3;

regr #(.N(4)) func7_3_s2(.clk(clk), .clear(1'b0), .hold(stall_s1_s2),
                    .in({func7[5],func3}), .out(func_s3));
/* ------------ */


	// transfer register data to stage 3
	wire [31:0]	data1_s3, data2_s3;
	regr #(.N(64)) reg_s2_mem(.clk(clk), .clear(flush_s2), .hold(stall_s1_s2),
				.in({data1, data2}),
				.out({data1_s3, data2_s3}));


	// transfer PC + 4 to stage 3
	wire [31:0] pc4_s3;
	regr #(.N(32)) reg_pc4_s2(.clk(clk), .clear(1'b0), .hold(stall_s1_s2),
						.in(pc4_s2), .out(pc4_s3));

	


	// transfer the control signals to stage 3
	wire		regdst_s3;
	wire		memread_s3;
	wire		memwrite_s3;
	wire		memtoreg_s3;
	wire [1:0]	aluop_s3;
	wire		regwrite_s3;
	wire		alusrc_s3;
	// A bubble is inserted by setting all the control signals
	// to zero (stall_s1_s2).
	regr #(.N(8)) reg_s2_control(.clk(clk), .clear(stall_s1_s2), .hold(1'b0),
			.in({regdst, memread, memwrite,
					memtoreg, aluop, regwrite, alusrc}),
			.out({regdst_s3, memread_s3, memwrite_s3,
					memtoreg_s3, aluop_s3, regwrite_s3, alusrc_s3}));

	wire branch_eq_s3, branch_ne_s3, branch_lt_s3;
	regr #(.N(3)) branch_s2_s3(.clk(clk), .clear(flush_s2), .hold(1'b0),
				.in({branch_eq_s2, branch_ne_s2,branch_lt_s2}),
				.out({branch_eq_s3, branch_ne_s3,branch_lt_s3}));

	wire [31:0] baddr_s3;
	regr #(.N(32)) baddr_s2_s3(.clk(clk), .clear(flush_s2), .hold(1'b0),
				.in(baddr_s2), .out(baddr_s3));

	wire jump_s3;
	regr #(.N(1)) reg_jump_s3(.clk(clk), .clear(flush_s2), .hold(1'b0),
				.in(jump_s2),
				.out(jump_s3));

	// wire [31:0] jaddr_s3;
	// regr #(.N(32)) reg_jaddr_s3(.clk(clk), .clear(flush_s2), .hold(1'b0),
	// 			.in(jaddr_s2), .out(jaddr_s3));
	// }}}

	// {{{ stage 3, EX (execute)

	reg [31:0] fw_data1_s3;
// `include "execution_newcode.sv"
/* ------------------- */
// ALU
// second ALU input can come from an immediate value or data
wire [31:0]alusrc_data2;

// Decide o Forwarding
assign alusrc_data2 = (alusrc_s3) ? seimm_s3 : fw_data2_s3;

// ALU control
wire[3:0] aluctl;
wire[5:0] funct;
assign funct = seimm_s3[5:0];

alu_control alu_ctl1(.funct(func_s3), .aluop(aluop_s3), .aluctl(aluctl));
// ALU
wire[31:0]	alurslt;
wire zero_s3;

alu alu1(.ctl(aluctl), .a(fw_data1_s3), .b(alusrc_data2), .out(alurslt),
                                .zero(zero_s3));

// write register
wire[4:0] wrreg;
wire[4:0] wrreg_s4;
assign wrreg = (regdst_s3) ? rd_s3 : rs2_s3;
/* ------------------- */

	// pass through some control signals to stage 4
	wire regwrite_s4;
	wire memtoreg_s4;
	wire memread_s4;
	wire memwrite_s4;
	regr #(.N(4)) reg_s3(.clk(clk), .clear(flush_s2), .hold(1'b0),
				.in({regwrite_s3, memtoreg_s3, memread_s3,
						memwrite_s3}),
				.out({regwrite_s4, memtoreg_s4, memread_s4,
						memwrite_s4}));


	always @(*)
	case (forward_a)
			2'd1: fw_data1_s3 = alurslt_s4;
			2'd2: fw_data1_s3 = wrdata_s5;
		 default: fw_data1_s3 = data1_s3;
	endcase

	wire zero_s4;
	regr #(.N(1)) reg_zero_s3_s4(.clk(clk), .clear(1'b0), .hold(1'b0),
					.in(zero_s3), .out(zero_s4));

	// pass ALU result and zero to stage 4
	wire [31:0]	alurslt_s4;
	regr #(.N(32)) reg_alurslt(.clk(clk), .clear(flush_s3), .hold(1'b0),
				.in({alurslt}),
				.out({alurslt_s4}));

	// pass data2 to stage 4
	wire [31:0] data2_s4;
	reg [31:0] fw_data2_s3;
	always @(*)
	case (forward_b)
			2'd1: fw_data2_s3 = alurslt_s4;
			2'd2: fw_data2_s3 = wrdata_s5;
		 default: fw_data2_s3 = data2_s3;
	endcase
	regr #(.N(32)) reg_data2_s3(.clk(clk), .clear(flush_s3), .hold(1'b0),
				.in(fw_data2_s3), .out(data2_s4));


	// pass to stage 4
	regr #(.N(5)) reg_wrreg(.clk(clk), .clear(flush_s3), .hold(1'b0),
				.in(wrreg), .out(wrreg_s4));

	wire branch_eq_s4, branch_ne_s4, branch_lt_s4;
	regr #(.N(3)) branch_s3_s4(.clk(clk), .clear(flush_s3), .hold(1'b0),
				.in({branch_eq_s3, branch_ne_s3,branch_lt_s3}),
				.out({branch_eq_s4, branch_ne_s4,branch_lt_s4}));

	wire [31:0] baddr_s4;
	regr #(.N(32)) baddr_s3_s4(.clk(clk), .clear(flush_s3), .hold(1'b0),
				.in(baddr_s3), .out(baddr_s4));

	wire jump_s4;
	regr #(.N(1)) reg_jump_s4(.clk(clk), .clear(flush_s3), .hold(1'b0),
				.in(jump_s3),
				.out(jump_s4));

	// wire [31:0] jaddr_s4;
	// regr #(.N(32)) reg_jaddr_s4(.clk(clk), .clear(flush_s3), .hold(1'b0),
	// 			.in(jaddr_s3), .out(jaddr_s4));
	// }}}

	// {{{ stage 4, MEM (memory)

	// pass regwrite and memtoreg to stage 5
	wire memtoreg_s5;
	regr #(.N(2)) reg_regwrite_s4(.clk(clk), .clear(1'b0), .hold(1'b0),
				.in({regwrite_s4, memtoreg_s4}),
				.out({regwrite_s5, memtoreg_s5}));

	// data memory
	wire [31:0] rdata;
	dm dm1(.clk(clk), .addr(alurslt_s4[8:2]), .rd(memread_s4), .wr(memwrite_s4),
			.wdata(data2_s4), .rdata(rdata));
	// pass read data to stage 5
	wire [31:0] rdata_s5;
	regr #(.N(32)) reg_rdata_s4(.clk(clk), .clear(1'b0), .hold(1'b0),
				.in(rdata),
				.out(rdata_s5));

	// pass alurslt to stage 5
	wire [31:0] alurslt_s5;
	regr #(.N(32)) reg_alurslt_s4(.clk(clk), .clear(1'b0), .hold(1'b0),
				.in(alurslt_s4),
				.out(alurslt_s5));

	// pass wrreg to stage 5
	regr #(.N(5)) reg_wrreg_s4(.clk(clk), .clear(1'b0), .hold(1'b0),
				.in(wrreg_s4),
				.out(wrreg_s5));

	// branch
	reg pcsrc;
	always @(*) begin
		case (1'b1)
			branch_eq_s4: pcsrc <= zero_s4;
			branch_ne_s4: pcsrc <= ~(zero_s4);
			branch_lt_s4: pcsrc <= alurslt_s4[31];

			default: pcsrc <= 1'b0;
		endcase
	end
	// }}}
			
	// {{{ stage 5, WB (write back)

	assign wrdata_s5 = (memtoreg_s5 == 1'b1) ? rdata_s5 : alurslt_s5;

	// }}}

	// {{{ forwarding

	// stage 3 (MEM) -> stage 2 (EX)
	// stage 4 (WB) -> stage 2 (EX)

	reg [1:0] forward_a;
	reg [1:0] forward_b;
	always @(*) begin
		// If the previous instruction (stage 4) would write,
		// and it is a value we want to read (stage 3), forward it.

		// data1 input to ALU
		if ((regwrite_s4 == 1'b1) && (wrreg_s4 == rs1_s3)) begin
			forward_a <= 2'd1;  // stage 4
		end else if ((regwrite_s5 == 1'b1) && (wrreg_s5 == rs1_s3)) begin
			forward_a <= 2'd2;  // stage 5
		end else
			forward_a <= 2'd0;  // no forwarding

		// data2 input to ALU
		if ((regwrite_s4 == 1'b1) & (wrreg_s4 == rs2_s3)) begin
			forward_b <= 2'd1;  // stage 5
		end else if ((regwrite_s5 == 1'b1) && (wrreg_s5 == rs2_s3)) begin
			forward_b <= 2'd2;  // stage 5
		end else
			forward_b <= 2'd0;  // no forwarding
	end
	// }}}

	// {{{ load use data hazard detection, signal stall

	/* If an operation in stage 4 (MEM) loads from memory (e.g. lw)
	 * and the operation in stage 3 (EX) depends on this value,
	 * a stall must be performed.  The memory read cannot 
	 * be forwarded because memory access is too slow.  It can
	 * be forwarded from stage 5 (WB) after a stall.
	 *
	 *   lw $1, 16($10)  ; I-type, rt_s3 = $1, memread_s3 = 1
	 *   sw $1, 32($12)  ; I-type, rt_s2 = $1, memread_s2 = 0
	 *
	 *   lw $1, 16($3)  ; I-type, rt_s3 = $1, memread_s3 = 1
	 *   sw $2, 32($1)  ; I-type, rt_s2 = $2, rs_s2 = $1, memread_s2 = 0
	 *
	 *   lw  $1, 16($3)  ; I-type, rt_s3 = $1, memread_s3 = 1
	 *   add $2, $1, $1  ; R-type, rs_s2 = $1, rt_s2 = $1, memread_s2 = 0
	 */
	always @(*) begin
		if (memread_s3 == 1'b1 && ((rs2 == rd_s3) || (rs1 == rd_s3)) ) begin
			stall_s1_s2 <= 1'b1;  // perform a stall
		end else
			stall_s1_s2 <= 1'b0;  // no stall
	end
	// }}}

endmodule


module top;
reg clk;

initial begin
  clk=0;
     forever #1 clk = ~clk;  
end 
//altere aqui, de acordo com o numero de instruções no programa
parameter nInstrucoes = 50;
cpu #(nInstrucoes)CPU(clk);
initial begin
    $dumpfile("test.vcd");
    $dumpvars(0,top);
    #256
    $writememh("mem.data", top.CPU.dm1.mem, 0, 15);
    // $writememh("mem.data", top.CPU.dm1.mem, 0, 31);
    $writememh("reg.data", top.CPU.regm1.mem, 0, 15);
    // $writememh("reg.data", top.CPU.regm1.mem, 0, 31);
    $dumpoff;
    $finish;
    end

endmodule
