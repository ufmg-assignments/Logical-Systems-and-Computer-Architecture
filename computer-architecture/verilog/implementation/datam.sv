module dm(
    input wire clk,
    input wire[6:0] addr,
    input wire rd, wr,
    input wire[31:0] wdata,
    output wire[31:0] rdata
);

    // Number of memory entries,
    // not the same as the memory size
    // Número de linhas que estarão no arquivo que será
    // carregado para a memória
	parameter NMEM = 20;

    // file to read data from
	parameter RM_DATA = "dm_data.txt";

     // 32-bit memory with 128 entries
	reg[31:0] mem [0:127];


    // Carregamento dos dados do arquivo para a memória
    initial begin
		$readmemh(RM_DATA, mem, 0, NMEM-1);
	end
		
    // Na borda de subida escreve o dado na memória no endereço indicado
	always @(posedge clk) begin
		if (wr) begin
			mem[addr] <= wdata;
		end
	end

	// During a write, avoid the one cycle delay by reading from 'wdata'
    // Não espera o clock atualizar o valor para atualizar a saída
	assign rdata = wr ? wdata : mem[addr];

endmodule
