.data
	
	# Strings para permitir a interface com usuario via terminal MIPS
	quebraDeLinha: .asciiz "\n"
	strIntro: .asciiz "Bem vindo ao Programa Codificador & Decodificador MIPS\n"
	strSeparador: .asciiz "***************************************************\n"
	strExit: .asciiz "Obrigado por usar o programa....\n\n FINALIZANDO...\n"
	strMenu: .asciiz "Escreva o nome do arquivo...\nArquivos à serem codificados devem possuir a extensão .txt\nArquivos a serem decodificados devem possuir a extensão .lzw\n\n"
	strError: .asciiz "Erro ao abrir o arquivo/Arquivo inexistente...\n\nVOLTANDO AO MENU\n\n"
	
	#nome do arquivo de input com no maximo 20 caracteres
	nomeArquivo: .space 20 
	

.globl main
.text
main:	
	# Strings para a abertura do Sistema via terminal MIPS
	la $a0, quebraDeLinha
	li $v0, 4
	syscall
	la $a0, strSeparador
	syscall
	la $a0, strIntro
	syscall
	la $a0, strSeparador
	syscall
	la $a0, quebraDeLinha
	syscall
	
menu:	
	# Menu de operação
	la $a0, strMenu # String de explicação sobre os inputs de nomes de arquivos
	li $v0, 4
	syscall
	li $v0, 8 # Input do nome do arquivo a ser aberto
	la $a0, nomeArquivo # Buffer que conterá nome do arquivo
	li $a1, 20 # Máximo de 20 caracteres
	syscall
	add $s6, $a0, $0 # $s6 armazenará o address do nome do arquivo
	add $t0, $s6, $0 # $s6 movido para $t0 para percorrer a string caractere por caractere
	
loopChar:
	# Procura o ultimo caractere da string
	addi $t0, $t0, 1
	lb $t1, ($t0)
	bne $t1, $0, loopChar 
	
	# Retira byte de newline (10 em decimal) se este existir
	addi $t0, $t0, -1
	li $t2, 10
	lb $t1, ($t0)
	bne $t1, $t2, openFile
	sb $0, ($t0)
	
openFile:
	# Tenta abrir arquivo com o nome que fora colocado como input pelo usuario
	li $v0, 13 # syscall para abrir arquivo
	move $a0, $s6 # nome do arquivo
	add $a1, $0, $0 # flag para leitura ( read )
	add $a2, $0, $0 # mode ignorado
	syscall
	move $s7, $v0 # File Descriptor salvo em $s7
	bltz $s7, readError
	j exit
	
	
readError:
	# Strings para inidcação de erro na tentativa de abrir o arquivo
	la $a0, quebraDeLinha
	li $v0, 4
	syscall
	la $a0, strError
	syscall
	move $t0, $s6
	li $t1, 5 # contador do loop
	
loopError:
	# Apaga conteudo do buffer
	sw $0, ($t0)
	addi $t0, $t0, 4
	addi $t1, $t1, -1
	bgtz $t1, loopError
	j menu

exit:
	# Strings para finalização do sistema via terminal MIPS
	la $a0, quebraDeLinha
	li $v0, 4
	syscall
	la $a0, strExit
	syscall
	
