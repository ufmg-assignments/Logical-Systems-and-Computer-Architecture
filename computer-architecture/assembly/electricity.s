beq x10, x0, CALCULAR_POTENCIA		# condicao para calcular a potencia
beq x11, x0, CALCULAR_TENSAO		# condicao para calcular a tensao
beq x12, x0, CALCULAR_CORRENTE		# condicao para calcular a corrente
jal x0, END				# se todos registradores forem diferentes de 0, nada sera feito

CALCULAR_POTENCIA:
	beq x11, x0, ZERAR		#se mais de uma variavel for 0, pula para ZERAR
	beq x12, x0, ZERAR
	mul x10, x11, x12		# P = V * I
	jal x0, END			# pula para o fim do codigo

CALCULAR_TENSAO:
	beq x10, x0, ZERAR		#se mais de uma variavel for 0, pula para ZERAR
	beq x12, x0, ZERAR
	div x11, x10, x12		# V = P / I
	jal x0, END			# pula para o fim do codigo
    
CALCULAR_CORRENTE:
	beq x10, x0, ZERAR		#se mais de uma variavel for 0, pula para ZERAR
	beq x11, x0, ZERAR
	div x12, x10, x11		# I = P / V
	jal x0, END			# pula para o fim do codigo

ZERAR:					#zera todos os registradores que seriam usados
	addi x10, x0, 0
	addi x11, x0, 0
	addi x12, x0, 0
	jal x0, END

END: