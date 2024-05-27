addi x11, x0, 1				# inicia o registrador que vai guardar o resultado
addi x12, x0, 1				# inicia o registrador com o proximo valor a ser multiplicado

FACT:
	mul x11, x11, x12		# res = res * i
	addi x12, x12, 1		# i = i + 1
	bge x10, x12, FACT		# se n >= i, retorne a FACT
    
END:
	addi x12, x0, 0			# o registrador auxiliar utilizado sera zerado