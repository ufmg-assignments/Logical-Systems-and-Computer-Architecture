# Caso teste, em que o vetor possui 5 elementos, vetor = [4,13,8,2,9]
# Detalhe: deve-se pular 4 posicoes a cada novo elemento
#addi x12, x0, 4
#sw x12, 0(x10)
#addi x12, x0, 13 
#sw x12, 4(x10)
#addi x12, x0, 8 
#sw x12, 8(x10)
#addi x12, x0, 2 
#sw x12, 12(x10)
#addi x12, x0, 9 
#sw x12, 16(x10)

mv x30, x10					# endereco do primeiro elemento do vetor em x30
slli x6, x11, 2					# variavel auxiliar para calcular o endereco do ultimo elemento
add x7, x10, x6					# x7 guarda o endereco do ultimo elemento do vetor

LOOP:
	lw x15, 0(x30)				# x15 vai guardar o menor elemento do subvetor a ser ordenado
	mv x16, x30				# x16 vai guardar o endereco desse menor elemento
	mv x5, x30				# x5 sera utilizado para iterar sobre o subvetor
    
LOOP2:
	lw x14, 0(x5)				# x14 guarda o valor do proximo elemento a ser comparado
	blt x14, x15, ATUALIZAR			# comparacao entre x14 e x15, se x14 for menor, x15 deve ser atualizado
	addi x5, x5, 4				# incremento do iterador
	bltu x5, x7, LOOP2			# retorno ao LOOP2 para analisar o proximo elemento do vetor
	jal x0, TROCA				# se o LOOP2 tiver acabado, pula-se para a troca
    
ATUALIZAR:
	addi x15, x14, 0			# x15 atualizado
	add x16, x5, x0				# endereco do menor elemento atualizado
	addi x5, x5, 4				# incremento do iterador
	bltu x5, x7, LOOP2			# retorno ao LOOP2 para analisar o proximo elemento do vetor
    
TROCA:
	lw x18, 0(x30)				# x18 guarda o primeiro elemento do subvetor
	sw x18, 0(x16)				# esse primeiro elemento sera colocado na posicao de memoria do menor elemento
	sw x15, 0(x30)				# o menor valor encontrado sera colocado na primeira posicao do subvetor
	addi x30, x30, 4			# incremento de x30. Agora ele sera o primeiro elemento do subvetor nao ordenado
	bltu x30, x7, LOOP			# equanto x30 for menor que o final do vetor, deve-se retornar ao LOOP