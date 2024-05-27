module alu(
    input[3:0] ctl,
    input[31:0] a, b,
    output reg[31:0] out,
    output zero
);

	wire[31:0] sub_ab;
	wire[31:0] add_ab;
	wire oflow_add;
	wire oflow_sub;
	wire oflow;
	wire slt;

	assign zero = (0 == out);

	assign sub_ab = a - b;
	assign add_ab = a + b;
    // Verificação de condições de overflow
	assign oflow_add = (a[31] == b[31] && add_ab[31] != a[31]) ? 1 : 0;
	assign oflow_sub = (a[31] == b[31] && sub_ab[31] != a[31]) ? 1 : 0;

	assign oflow = (ctl == 4'b0010) ? oflow_add : oflow_sub;

	// set if less than, 2s complement 32-bit numbers
	assign slt = oflow_sub ? ~(a[31]) : a[31];

    // Seleciona a operação a ser implementada
	always @(*) begin
		case (ctl)
			4'b0010:  out <= add_ab;				/* add */
			4'b0000:  out <= a & b;				/* and */
			4'b1100: out <= ~(a | b);				/* nor */
			4'b0001:  out <= a | b;				/* or */
			4'b0111:  out <= {{31{1'b0}}, slt};	/* slt */
			4'b0110:  out <= sub_ab;				/* sub */
			4'b1101: out <= a ^ b;				/* xor */
			4'b0011: out <= (a << b[4:0]); /* sll */
			default: out <= 0;
		endcase
	end

endmodule

// Observe que o SLL pode ocorrer junto do SLLI
// No caso o código da ALU
// Porque chega um imediato de 32 bits mas em ambos os casos só é necessário
// Considerar os 5 bits menos significativos
module alu_control(
    input wire[3:0] funct,
    input wire[1:0] aluop,
    output reg[3:0] aluctl
);

    // Map do funct3 para operações da ALU
	// Esse funct é um funct7[7],funct3[2:0]
	reg [3:0] _funct_r;
	reg [3:0] _funct_i;

	// Trata operações do Tipo R
	always @(*) begin
		case(funct[3:0])
			4'd0:  _funct_r = 4'd2;	/* add */
			4'd8:  _funct_r = 4'd6;	/* sub */
			4'd5:  _funct_r = 4'd1;	/* or */
			4'd6:  _funct_r = 4'd13;	/* xor */
			4'd7:  _funct_r = 4'd12;	/* nor */
			4'd10: _funct_r = 4'd7;	/* slt */
			4'b0001: _funct_r = 4'd3; // sll
			default: _funct_r = 4'd0; /* and */
		endcase
	end

	// Trata operações do Tipo I
	// Discutir implementação das outra instruções do tipo I
	always @(*) begin
		case(funct[2:0])
			// Aqui vamos considerar so o funct 3 para fins de simplicidade
			3'b001: _funct_i = 4'd3; // SLLI
			3'b000: _funct_i = 4'd2; // ADDI
			3'b110: _funct_i = 4'd1; // ORI
			default: _funct_i = 4'd2;
		endcase
	end

	always @(*) begin
		case(aluop)
			// Necessário alterar o ALUOP code igual a 11 para realiar o
			// SLL
			2'd0: aluctl = 4'd2;	/* add LOAD/STORE */
			2'd1: aluctl = 4'd6;	/* sub BEQ*/
			2'd2: aluctl = _funct_r; /* Instrução Tipo-R */
			2'd3: aluctl = _funct_i;	/* TIPO I */
			default: aluctl = 0;
		endcase
	end

endmodule
