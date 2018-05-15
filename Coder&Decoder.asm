###################################################
#
# TRABALHO DE OAC - TURMA D
#
# ALUNO: LUCAS DA SILVA MOUTINHO - 15/0015747
#
# PROFESSOR: VIDAL
#
# CODIFICADOR E DECODIFICADOR LEMPEL-ZIV LZ78
#
###################################################
.data
	# Strings para permitir a interface com usuario via terminal MIPS
	quebraDeLinha: .asciiz "\n"
	strIntro: .asciiz "Bem vindo ao Programa Codificador & Decodificador MIPS\n"
	strSeparador: .asciiz "***************************************************\n"
	strExit: .asciiz "Obrigado por usar o programa....\n\n FINALIZANDO...\n"
	strSubmenu: .asciiz "Escreva o nome do arquivo...\nArquivos à serem codificados devem possuir a extensão .txt\nArquivos a serem decodificados devem possuir a extensão .lzw\n\n"
	strOpenError: .asciiz "Erro ao abrir o arquivo\nArquivo inexistente ou com a extensão incorreta...\n\nVOLTANDO AO MENU\n\n"
	strReadError: .asciiz "Erro ao ler o arquivo...\n\nVOLTANDO AO MENU\n\n"
	strSucessoCod: .asciiz "Sucesso ao Codificar o Arquivo...\n\nVOLTANDO AO MENU\n\n"
	strSucessoDecod: .asciiz "Sucesso ao Decodificar o Arquivo...\n\nVOLTANDO AO MENU\n\n"
	strMenu: .asciiz "Selecione uma das opções:\n0 - Codificar e/ou Decodificar um arquivo\n1 - Sair do sistema\n"
	strErroOpcao: .asciiz "Opcao invalida...\n\nTente Novamente\n\n"
	
	# Nome dos arquivos de input e output
	nomeArquivo: .space 20 # Nome do arquivo de input com no maximo 20 caracteres
	nomeSaida: .space 20 # Nome do arquivo de output com no maximo 20 caracteres
	nomeDic: .asciiz "Dicionario.txt" # Nome do arquivo de output do dicionario gerado na codificação
	
	# Espaço da memoria para armazenar o dicionario
	dicionario: .word 0:640000 # cria um dicionario com 20000 linhas, cada uma com 32 words, ou seja 128 caracteres
	
	# Buffers de leitura para sequencia de caracteres
	buffer: .word 0:32 # Buffer intermediario
	outputBuffer: .space 10 # Buffer de saida
	
.globl main
.text
main:	
	# Strings para a abertura do Sistema via terminal MIPS
	li $v0, 4
	la $a0, strIntro
	syscall
	la $a0, strSeparador
	syscall
	la $a0, quebraDeLinha
	syscall
	la $s0, buffer # $s0 armazenará o address do buffer intermediario
	la $s1, dicionario # $s1 armazenará o address do dicionario
	la $s2, outputBuffer # $s2 armazenará o address do buffer de saida
	la $s4, nomeSaida # $s4 armazenará o address do nome do arquivo de saida
	la $s6, nomeArquivo # $s6 armazenará o address do nome do arquivo de entrada
	
	
menu:
	# Strings para a abertura do Sistema via terminal MIPS
	la $a0, quebraDeLinha
	li $v0, 4
	syscall
	la $a0, strSeparador
	syscall
	la $a0, strMenu
	syscall
	la $a0, strSeparador
	syscall
	la $a0, quebraDeLinha
	syscall
	li $v0, 5
	syscall
	move $t2, $v0
	li $t0, 0 # opcao 0
	li $t1, 1 # opcao 1
	beq $t0, $t2, submenu
	beq $t1, $t2, exit
	la $a0, strErroOpcao # opcao invalida
	li $v0, 4
	syscall
	j menu
	
submenu:	
	# Menu de operação para o codificador e decodificador
	la $a0, strSubmenu # String de explicação sobre os inputs de nomes de arquivos
	li $v0, 4
	syscall
	
	la $s6, nomeArquivo # $s6 armazenará o address do nome do arquivo de entrada
	
	li $v0, 8 # Input do nome do arquivo a ser aberto
	move $a0, $s6 # Buffer que conterá nome do arquivo
	li $a1, 20 # Máximo de 20 caracteres
	syscall
	
	jal stringNewLine
	move $t0, $a0 # recebe o new line byte da string
	
	sb $0, ($t0) # Retira byte de newline (10 em decimal)
	
openFile:
	# Tenta abrir arquivo com o nome que fora colocado como input pelo usuario
	li $v0, 13 # syscall para abrir arquivo
	move $a0, $s6 # nome do arquivo
	add $a1, $0, $0 # flag para leitura ( read )
	add $a2, $0, $0 # mode ignorado
	syscall
	move $s7, $v0 # File Descriptor do arquivo de entrada salvo em $s7
	bltz $s7, openError # File Descriptor negativo, erro ao tentar abrir o arquivo
	
	jal stringLength
	move $t0, $a0
	li $t1, 5 # Arquivos tem de ter no minimo 5 caracteres. Exemplo: T.txt
	slt $t1, $t0, $t1
	bne $t1, $0, openError # Retorna erro, pois o tamanho da string é menor do que 4, ou seja, numero de caracteres insuficientes no nome do arquivo
	
extensionTXT:
	# Série de testes para avaliar a extensão do arquivo
	jal stringEnd
	move $t0, $a0 # recebe o null byte da string
	addi $t0, $t0, -4 # volta no quarto caractere antes do fim da string
	li $t1, 46 # caractere .
	lb $t2, ($t0)
	bne $t2, $t1, openError # Quarto caractere antes do fim é diferente de ponto.
	addi $t0, $t0, 1
	li $t1, 116 # caractere t
	lb $t2, ($t0)
	bne $t2, $t1, extensionLZW # Volta para avaliar se a extensão é lzw
	addi $t0, $t0, 1
	li $t1, 120 # caractere x
	lb $t2, ($t0)
	bne $t2, $t1, openError # Extensão incorreta
	addi $t0, $t0, 1
	li $t1, 116 # caractere t
	lb $t2, ($t0)
	bne $t2, $t1, openError # Extensão incorreta
	j codificador # Arquivo deve ser codificado
	
extensionLZW:
	# Série de testes para avaliar a extensão do arquivo
	jal stringEnd
	move $t0, $a0 # recebe o null byte da string
	addi $t0, $t0, -3 # volta no terceiro caractere antes do fim da string
	li $t1, 108 # caractere l
	lb $t2, ($t0)
	bne $t2, $t1, openError # Extensão incorreta
	addi $t0, $t0, 1
	li $t1, 122 # caractere z
	lb $t2, ($t0)
	bne $t2, $t1, openError # Extensão incorreta
	addi $t0, $t0, 1
	li $t1, 119 # caractere w
	lb $t2, ($t0)
	bne $t2, $t1, openError # Extensão incorreta
	j decodificador # Arquivo deve ser decodificado

codificador:
	# Abrindo arquivo para saida
	jal outputArq
	move $s5, $a0 # $s5 recebe file descriptor do arquivo de saida
	
	addi $t7, $0, 1 # variavel n ( numero da linha )
	add $t1, $0, $0 # variavel x
	add $t2, $0, $0 # flag
	add $t3, $0, $0 # variavel y
	move $s3, $s0 # buffer intermediario
	move $t8, $s2 # buffer de saida
	move $t0, $s1 # indice i recebe inicio do dicionario
	
loopC1:
	
	# faz uma leitura em disco e salva no buffer
	li $v0, 14
	move $a0, $s7
	move $a1, $s3
	addi $a2, $0, 1
	syscall
	move $t9, $v0
	bltz $t9, readError # erro de leitura
	beq $t9, $0, endLoopC1 # atingiu o EOF
	lb $t3, ($s3) # variavel y recebe o ultimo caractere lido
	
loopC2:
	# percorrendo o dicionario. Verifica se a linha esta vazia
	lb $t9, ($t0)
	beq $t9, $0, endLoopC2
	
	addi $t2, $0, 1 # flag recebe 1, supoem-se que a linha eh igual ao buffer
	
	move $t4, $t0 # variavel j recebe variavel i
	move $t5, $s0 # buffer intermediario
	
	
loopC3:
	lb $t6, ($t4) # dic[i][j]
	lb $t9, ($t5) # buffer intermediario
	
	beq $t9, $t6, elseC3 #sao iguais
	add $t2, $0, $0 # flag volta para 0, pois nao sao iguais
	j endLoopC3
	
elseC3:
	beq $t6, $0, endLoopC3
	addi $t5, $t5, 1
	addi $t4, $t4, 1
	j loopC3
	
endLoopC3:
	
	beq $t2, $0, elseC2 # se a flag for 0
	add $t1, $t7, $0
	addi $t0, $t0, 128
	addi $t7, $t7, 1
	j endLoopC2
	
elseC2:
	addi $t0, $t0, 128
	addi $t7, $t7, 1
	j loopC2

endLoopC2:
	
	bne $t2, $0, endifC1 # se a flag nao for 0
	move $t4, $t0 # variavel j recebe a i
	move $t5, $s0 # indice do buffer volta para o inicio
	
pseudoWhile:
	# percorre linha do dicionario gravando o buffer
	lb $t9, ($t5) # buffer intermediario
	beq $t9, $0, endPseudoWhile
	
	sb $t9, ($t4) # dic[i][j]
	addi $t5, $t5, 1
	addi $t4, $t4, 1
	j pseudoWhile
	
endPseudoWhile:
	# escreve no buffer de saida a codificacao
	move $a0, $t1 # escreve a variavel X na saida
	jal iToAscii
	move $t8, $s2 # buffer de saida
	addi $t9, $0, 48
	
	# salva a sequencia de caracteres corretamente no buffer de saida
	beq $a0, $t9, analisaA1
	sb $a0, ($t8)
	addi $t8, $t8, 1
	sb $a1, ($t8)
	addi $t8, $t8, 1
	sb $a2, ($t8)
	addi $t8, $t8, 1
	j analisaA3
analisaA1:
	beq $a1, $t9, analisaA2
	sb $a1, ($t8)
	addi $t8, $t8, 1
	sb $a2, ($t8)
	addi $t8, $t8, 1
	j analisaA3
analisaA2:
	beq $a2, $t9, analisaA3
	sb $a2, ($t8)
	addi $t8, $t8, 1
	j analisaA3
analisaA3:
	sb $a3, ($t8)
	addi $t8, $t8, 1
	sb $t3 ,($t8)
	addi $t8, $t8, 1
	li $t9, 96 # caractere de acento no ascii . Usado para separar
	sb $t9, ($t8)
	
	# escreve no arquivo de saida o conteudo contido no buffer de saida
	li $v0, 15
	move $a0, $s5
	move $a1, $s2
	subu $a2, $t8, $s2
	addi $a2, $a2, 1
	syscall
	move $t9, $v0
	bltz $t9, readError # erro de leitura
	
	move $t8, $s2 # buffer de saida
	# limpa buffer de saida
	sb $0 ,($t8)
	addi $t8, $t8, 1
	sb $0 ,($t8)
	addi $t8, $t8, 1
	sb $0, ($t8)
	sb $0 ,($t8)
	addi $t8, $t8, 1
	sb $0, ($t8)
	sb $0 ,($t8)
	addi $t8, $t8, 1
	sb $0, ($t8)
	sb $0 ,($t8)
	addi $t8, $t8, 1
	sb $0, ($t8)
	addi $t8, $t8, 1
	sb $0 ,($t8)
	addi $t8, $t8, -6
	
	
	move $t5, $s0 # buffer intermediario
	
bufferWhile:
	# percorre linha do buffer, limpando-o
	
	sb $0, ($t5)
	addi $t5, $t5, 1
	lb $t9, ($t5)
	beq $t9, $0, endBufferWhile
	j bufferWhile
	
endBufferWhile:
	move $s3, $s0 # buffer intermediario
	addi $s3, $s3, -1
	add $t1, $0, $0
	
endifC1:
	add $t2, $0, $0 # flag
	move $t0, $s1 # indice i recebe inicio do dicionario
	addi $t7, $0, 1 # reinicia o numero da linha
	addi $s3, $s3, 1
	j loopC1
	
endLoopC1:
	
	# analisa caso extraordinario
	lb $t9, ($s0)
	beq $t9, $0, notSpecial
	
	move $t5, $s0 # buffer intermediario
	
superbufferWhile:
	# percorre linha do buffer
	lb $t9, ($t5)
	beq $t9, $0, superendBufferWhile
	addi $t5, $t5, 1
	j superbufferWhile
	
superendBufferWhile:

	addi $t5, $t5, -1
	sb $0, ($t5)
	move $t5, $s0 # buffer intermediario
	move $t0, $s1 # indice i recebe inicio do dicionario
	addi $t7, $0, 1
	add $t2, $0, $0
	lb $t9, ($s0)
	bne $t9, $0, superloopC2
	add $t1, $0, $0
	j endPseudoWhile
	
superloopC2:
	# percorrendo o dicionario. Verifica se a linha esta vazia
	lb $t9, ($t0)
	beq $t9, $0, superendLoopC2
	
	addi $t2, $0, 1 # flag recebe 1, supoem-se que a linha eh igual ao buffer
	
	move $t4, $t0 # variavel j recebe variavel i
	move $t5, $s0 # buffer intermediario
	
superloopC3:
	lb $t6, ($t4) # dic[i][j]
	lb $t9, ($t5) # buffer intermediario
	
	beq $t9, $t6, superelseC3 #sao iguais
	add $t2, $0, $0 # flag volta para 0, pois nao sao iguais
	j superendLoopC3
	
superelseC3:
	beq $t6, $0, superendLoopC3
	addi $t5, $t5, 1
	addi $t4, $t4, 1
	j superloopC3
	
superendLoopC3:
	
	beq $t2, $0, superelseC2 # se a flag for 0
	add $t1, $t7, $0
	addi $t0, $t0, 128
	addi $t7, $t7, 1
	j superendLoopC2
	
superelseC2:
	addi $t0, $t0, 128
	addi $t7, $t7, 1
	j superloopC2
superendLoopC2:
	sb $0, ($s0)
	j endPseudoWhile

notSpecial:
	
	# Strings para inidcação de sucesso na codificação do arquivo
	la $a0, quebraDeLinha
	li $v0, 4
	syscall
	la $a0, strSucessoCod
	syscall	
	
imprimeDic:
	
	li $v0, 13 # syscall para abrir arquivo
	la $a0, nomeDic # nome do arquivo
	addi $a1, $0, 1 # flag para escrita ( write )
	add $a2, $0, $0 # mode ignorado
	syscall
	bltz $v0, openError
	move $t1, $v0 # descriptor da saida dic
	
	
	move $t5, $s1 # indice do buffer volta para o inicio
	move $t0, $s1 # indice i no dic
	addi $t7, $0, 1 # nuero de linha

imloopC2:
	# percorrendo o dicionario. Verifica se a linha esta vazia
	lb $t9, ($t0)
	beq $t9, $0, imendLoopC2
	
	# escreve no buffer de saida a codificacao
	move $a0, $t7 # escreve a variavel X na saida
	jal iToAscii
	move $t8, $s2 # buffer de saida
	addi $t9, $0, 48 # zero em ascii
	
	# salva a sequencia de caracteres corretamente no buffer de saida
	beq $a0, $t9, analisaB1
	sb $a0, ($t8)
	addi $t8, $t8, 1
	sb $a1, ($t8)
	addi $t8, $t8, 1
	sb $a2, ($t8)
	addi $t8, $t8, 1
	j analisaB3
analisaB1:
	beq $a1, $t9, analisaB2
	sb $a1, ($t8)
	addi $t8, $t8, 1
	sb $a2, ($t8)
	addi $t8, $t8, 1
	j analisaB3
analisaB2:
	beq $a2, $t9, analisaB3
	sb $a2, ($t8)
	addi $t8, $t8, 1
	j analisaB3
analisaB3:
	sb $a3, ($t8)
	addi $t8, $t8, 1
	li $t9, 32 # caractere de Space
	sb $t9, ($t8)
	
	# escreve no arquivo de saida o conteudo contido no buffer de saida
	li $v0, 15
	move $a0, $t1
	move $a1, $s2
	subu $a2, $t8, $s2
	syscall
	bltz $v0, readError
	
	move $t8, $s2 # buffer de saida
	# limpa buffer de saida
	sb $0 ,($t8)
	addi $t8, $t8, 1
	sb $0 ,($t8)
	addi $t8, $t8, 1
	sb $0, ($t8)
	sb $0 ,($t8)
	addi $t8, $t8, 1
	sb $0, ($t8)
	sb $0 ,($t8)
	addi $t8, $t8, 1
	sb $0, ($t8)
	sb $0 ,($t8)
	addi $t8, $t8, 1
	sb $0, ($t8)
	addi $t8, $t8, 1
	sb $0 ,($t8)
	addi $t8, $t8, -6
	
	move $t4, $t0 # variavel j recebe variavel i
imloopC3:
	lb $t6, ($t4) # dic[i][j]
	
	beq $t6, $0, imendLoopC3 # é o fim
	
	# escreve no arquivo de saida o conteudo contido na linha
	li $v0, 15
	move $a0, $t1
	move $a1, $t4
	li $a2, 1
	syscall
	bltz $v0, readError
	
	sb $0, ($t4)
	
	addi $t4, $t4, 1
	
	j imloopC3
	
imendLoopC3:
	li $t9, 10 #end of line
	sb $t9, ($t8)
	# escreve no arquivo de saida o end line
	li $v0, 15
	move $a0, $t1
	move $a1, $t8
	li $a2, 1
	syscall
	bltz $v0, readError
	sb $0, ($t8)

	addi $t0, $t0, 128
	addi $t7, $t7, 1
	j imloopC2
imendLoopC2:
	j menu
	
	
decodificador:

	# Abrindo arquivo para saida
	jal outputArq
	move $s5, $a0 # $s5 recebe file descriptor do arquivo de saida
	
	add $t1, $0, $0 # variavel w
	add $t2, $0, $0 # variavel k
	add $t3, $0, $0 # variavel y
	add $t4, $0, $0 # variavel j
	add $t8, $0, $0 # ultimo caractere no buffer
	move $t5, $s0 # buffer intermediario
	move $t0, $s1 # indice i recebe inicio do dicionario
	move $t2, $s1 # variavel k recebe inicio do dicionario
	
enquanto_decod:
	move $t5, $s0 # buffer intermediario
	
	# faz uma leitura em disco e salva no buffer
	li $v0, 14
	move $a0, $s7
	move $a1, $t5
	addi $a2, $0, 1
	syscall
	move $t9, $v0
	bltz $t9, readError # erro de leitura
	beq $t9, $0, end_decod # atingiu o EOF
	lb $t3, ($t5) # variavel y recebe o ultimo caractere lido
	
loop_decod:

	li $t6, 96 # caractere de separação
	beq $t6, $t3, end_loop_decod # caractere de separação achado
	addi $t5, $t5, 1
	
	
	# faz uma leitura em disco e salva no buffer
	li $v0, 14
	move $a0, $s7
	move $a1, $t5
	addi $a2, $0, 1
	syscall
	move $t9, $v0
	bltz $t9, readError # erro de leitura
	beq $t9, $0, end_decod # atingiu o EOF
	lb $t3, ($t5) # variavel y recebe o ultimo caractere lido
	
	j loop_decod
	
end_loop_decod:
	
	add $t6, $0, $0 # numero de integers zerado
	sb $0, ($t5)
	subu $t6, $t5, $s0
	addi $t6, $t6, -1  # numero de integers
	addi $t8, $t5, -1 # ultimo caractere
	addi $t5, $t5, -2 # primeiro number
	
	# separa as integers
	lb $a3, ($t5)
	li $t9, 2
	beq $t6, $t9, caso1
	li $t9, 3
	beq $t6, $t9, caso2
	li $t9, 4
	beq $t6, $t9, caso3
	addi $a2, $0, 48
	addi $a1, $0, 48
	addi $a0, $0, 48
	j notACase
	
caso1:
	addi $t5, $t5, -1
	lb $a2, ($t5)
	addi $a1, $0, 48
	addi $a0, $0, 48
	j notACase

caso2:
	addi $t5, $t5, -1
	lb $a2, ($t5)
	addi $t5, $t5, -1
	lb $a1, ($t5)
	addi $a0, $0, 48
	j notACase

caso3:
	addi $t5, $t5, -1
	lb $a2, ($t5)
	addi $t5, $t5, -1
	lb $a1, ($t5)
	addi $t5, $t5, -1
	lb $a0, ($t5)

notACase:

	jal asciiToI
	move $t7, $a0 # armazena indice da linha
	move $t0, $s1 # indice i recebe inicio do dicionario
	move $t6, $t2 # posicao na nova linha
	beq $t7, $0, endWhileWriteDic # se indice for zero, nao existe na tabela
	
SearchDic:
	
	addi $t7, $t7, -1

whileMult:
	# acha o endereço correto do indice i
	beq $t7, $0, endSearchDic
	addi $t0, $t0, 128
	addi $t7, $t7, -1
	j whileMult

endSearchDic:
	
	move $t4, $t0 # posicao na linha do indice
	
whileWriteDic:
	# escreve a linha de i no arquivo de saida
	
	lb $t9, ($t4)
	beq $t9, $0, endWhileWriteDic
	
	# escreve no arquivo de saida o conteudo contido na linha
	li $v0, 15
	move $a0, $s5
	move $a1, $t4
	li $a2, 1
	syscall
	bltz $v0, readError

	# armazena conteudo no dicionario
	sb $t9, ($t6)
	addi $t6, $t6, 1
	
	addi $t4, $t4, 1
	
	j whileWriteDic
	
endWhileWriteDic:

	
	# escreve no arquivo de saida o ultimo caracterre do buffer
	li $v0, 15
	move $a0, $s5
	move $a1, $t8
	li $a2, 1
	syscall
	bltz $v0, readError
	
	
	# armazena conteudo no dicionario
	lb $t9, ($t8)
	sb $t9, ($t6)
	addi $t6, $t6, 1
	
	addi $t2, $t2, 128 # ultima linha do dic
	
	move $t5, $s0 # buffer intermediario
	
releaseBuffer:
	# limpa o buffer inserindo zeros
	lb $t9, ($t5)
	beq $t9, $0, endReleaseBuffer
	sb $0, ($t5)
	addi $t5, $t5, 1
	j releaseBuffer
	
endReleaseBuffer:
	j enquanto_decod
	
end_decod:
	# Strings para inidcação de sucesso na decodificação do arquivo
	la $a0, quebraDeLinha
	li $v0, 4
	syscall
	la $a0, strSucessoDecod
	syscall	
	
	j menu
	
readError:
	# Strings para inidcação de erro na tentativa de ler o arquivo
	la $a0, quebraDeLinha
	li $v0, 4
	syscall
	la $a0, strReadError
	syscall
	jal cleanArqBuffer
	j menu
	
openError:
	# Strings para inidcação de erro na tentativa de abrir o arquivo
	la $a0, quebraDeLinha
	li $v0, 4
	syscall
	la $a0, strOpenError
	syscall
	jal cleanArqBuffer
	j menu

stringEnd:
	move $t0, $s6
loopEnd:
	# Procura o ultimo caractere da string e o retorna
	addi $t0, $t0, 1
	lb $t1, ($t0)
	bne $t1, $0, loopEnd
	move $a0, $t0
	jr $ra
	
stringNewLine:
	move $t0, $s6
	addi $t3, $0, 10
loopNewLine:
	# Procura o ultimo caractere da string e o retorna
	addi $t0, $t0, 1
	lb $t1, ($t0)
	bne $t1, $t3, loopNewLine
	move $a0, $t0
	jr $ra
	
stringLength:
	# Retorna o tamanho da string
	move $t0, $s6
	add $t2, $0, $0
loopLength:
	lb $t1, ($t0)
	beq $t1, $0, endLength
	addi $t2, $t2, 1
	addi $t0, $t0, 1
	j loopLength
endLength:
	move $a0, $t2
	jr $ra
	
cleanArqBuffer:
	move $t0, $s6
	li $t1, 20 # contador do loop
loopClean:
	# Apaga conteudo do buffer do nome do arquivo byte a byte
	sb $zero, ($t0)
	addi $t0, $t0, 1
	addi $t1, $t1, -1
	bgtz $t1, loopClean
	jr $ra

outputArq:
	# Começa preparando o nome do arquivo de saida
	move $t3, $s4 # nome do arquivo de saida
	move $t0, $s6 # nome do arquivo de entrada
loopOutput:
	lb $t1, ($t0)
	sb $t1, ($t3)
	beq $t1, $0, endLoopOutput
	addi $t0, $t0, 1
	addi $t3, $t3, 1
	j loopOutput
endLoopOutput:
	# verifica a extensão correta do arquivo de saida
	addi $t3, $t3, -3
	lb $t1, ($t3)
	li $t2, 116 # caractere t
	beq $t1, $t2, outputLZW
	
	# arquivo de saida ,txt
	sb $t2, ($t3)
	addi $t3, $t3, 2 # caractere t
	sb $t2, ($t3)
	addi $t3, $t3, -1
	li $t2, 120 # caractere x
	sb $t2, ($t3)
	j continueOutput
outputLZW:
	# arquivo de saida .lzw
	li $t2, 108 # caractere l
	sb $t2, ($t3)
	addi $t3, $t3, 1
	li $t2, 122 # caractere z
	sb $t2, ($t3)
	addi $t3, $t3, 1
	li $t2, 119 # caractere w
	sb $t2, ($t3)
continueOutput:
	# Com o nome do arquivo de saida, abre-se o arquivo de saida com o syscall
	# Abrindo arquivo para saida
	li $v0, 13 # syscall para abrir arquivo
	move $a0, $s4 # nome do arquivo
	addi $a1, $0, 1 # flag para escrita ( write )
	add $a2, $0, $0 # mode ignorado
	syscall
	move $a0, $v0 # File Descriptor do arquivo de saida salvo em $a0 por ser uma função
	bltz $a0, openError # File Descriptor negativo, erro ao tentar abrir o arquivo
	jr $ra
	
	
iToAscii:
	# separa o numero por digitos
	move $t9, $a0
	div $t6, $t9, 1000
	move $a0, $t6
	rem $t9, $t9, 1000
	div $t6, $t9, 100
	move $a1, $t6
	rem $t9, $t9, 100
	div $t6, $t9, 10
	move $a2, $t6
	rem $t9, $t9, 10
	move $a3, $t9
	
	# converte para ascii somando 48 em cada digito
	addi $a0, $a0, 48
	addi $a1, $a1, 48
	addi $a2, $a2, 48
	addi $a3, $a3, 48
	
	jr $ra
	
asciiToI:
	
	# converte para decimal subtraindo 48 em cada digito
	addi $a0, $a0, -48
	addi $a1, $a1, -48
	addi $a2, $a2, -48
	addi $a3, $a3, -48
	
	# converte para decimal
	mul $a2, $a2, 10
	mul $a1, $a1 100
	mul $a0, $a0, 1000
	
	add $a0, $a0, $a1
	add $a0, $a0, $a2
	add $a0, $a0, $a3
	
	jr $ra

exit:
	# Strings para finalização do sistema via terminal MIPS
	la $a0, quebraDeLinha
	li $v0, 4
	syscall
	la $a0, strExit
	syscall
	
