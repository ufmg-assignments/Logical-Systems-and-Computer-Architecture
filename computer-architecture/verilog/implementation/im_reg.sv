// Instriction Memory
module im(
    input wire clk,
    input wire[31:0] addr,
    output wire[31:0] data
);
	// Number of memory entries,
    // not the same as the memory size
    parameter NMEM = 128;

    // file to read data from
	parameter IM_DATA = "im_data.txt";

    // 32-bit memory with 128 entries
	reg[31:0] mem [0:127];

    // Carregamento dos dados do arquivo para a memória
	initial begin
		$readmemh(IM_DATA, mem, 0, NMEM-1);
	end

    // Já considera o limite de endereços 
    // e já considera que o endereço é incrementado de 4 em 4
	assign data = mem[addr[8:2]][31:0];
endmodule

// Implementa o banco de registradores
module regm(
    input wire clk,
    input wire[4:0]	read1, read2,
	output wire[31:0] data1, data2,
    input wire regwrite,
    input wire[4:0] wrreg,
    input wire[31:0] wrdata
);

    // Number of memory entries,
    // not the same as the memory size
	parameter NMEM = 20;   

    // file to read data from
	parameter RM_DATA = "rm_data.txt";

    // 32-bit memory with 32 entries
    // (RISC-V são 32 Registradores)
	reg [31:0] mem [0:31];


    // Carregamento dos dados do arquivo para a memória
	initial begin
		$readmemh(RM_DATA, mem, 0, NMEM-1);
	end

    // Variáveis auxiliares
	reg [31:0] _data1, _data2;


	always @(*) begin
        // Registrador x0 é sempre zero
		if (read1 == 5'd0)
			_data1 = 32'd0;
        // Não espera o clock para atualizar o valor
        // associado ao registrador
		else if ((read1 == wrreg) && regwrite)
			_data1 = wrdata;
        // Faz o output do valor associado
		else
			_data1 = mem[read1][31:0];
	end

	always @(*) begin
        // Registrador x0 é sempre zero
		if (read2 == 5'd0)
			_data2 = 32'd0;
        // Não espera o clock para atualizar o valor
        // associado ao registrador
		else if ((read2 == wrreg) && regwrite)
			_data2 = wrdata;
		else
        // Faz o output do valor associado
			_data2 = mem[read2][31:0];
	end

    // Atribui o valor dos registradores à saida
	assign data1 = _data1;
	assign data2 = _data2;

    // Escreve na memória na borda de clock
	always @(posedge clk) begin
		if (regwrite && wrreg != 5'd0) begin
			// escreve o valor se o registrador de destino não for o x0
			mem[wrreg] <= wrdata;
		end
	end
endmodule