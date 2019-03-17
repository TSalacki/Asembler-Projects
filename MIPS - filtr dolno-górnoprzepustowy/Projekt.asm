.data
prompt:		.asciiz	"Nazwa pliku wejsciowego:\n"
prompt2:	.asciiz	"Nazwa pliku wyjsciowego:\n"
prompt3:	.asciiz "Podaj wage pikseli obwodowych:\n"
prompt4:	.asciiz "Podaj wage centralnego piskela:\n"
prompt5:	.asciiz "Blad otwarcia plikow! Upewnij sie ze podales dobre nazwy!\n"
prompt6:	.asciiz "\n"
prompt7:	.asciiz "Za maly bufor!\n"
header: 	.space  54 	
input_file:	.space	128 	
output_file:	.space	128 
out_buff:	.space 	1
buff:		.space 	9216

# $s0 - suma wag
# $s1 - waga pikselu obwodowego
# $s2 - waga piskelu centralnego 
# $s3 - deskryptor pliku wejscia
# $s4 - deskryptor pliku wyjscia
# $s5 - szerokosc obrazka (piskele
# $s6 - wysokosc obrzka (piksele)

.text
main:
#zapytaj o nazwe pliku wejsciowego
	li	$v0, 4		# syscall 4, pisz string
	la	$a0, prompt	
	syscall
#odczytaj nazwe pliku wejsciowego
	li	$v0, 8		# syscall 8, czytaj string
	la	$a0, input_file
	li	$a1, 128		
	syscall
#zapytaj o nazwe pliku wyjsciowego
	li	$v0, 4		# syscall 4, pisz string
	la	$a0, prompt2	
	syscall	
#odczytaj nazwe pliku wyjsciowego
	li	$v0, 8		# syscall 8, czytaj string
	la 	$a0, output_file	
	li 	$a1, 128		
	syscall
#zapytaj o wage pikseli obwodowych
	li	$v0, 4		# syscall 4, pisz string
	la	$a0, prompt3	
	syscall	
#odczytaj wage pikseli obwodowych
	li	$v0, 5		# syscall 5, czytaj int		
	syscall
	move 	$s1, $v0
#zapytaj o wage pikselu centralnego
	li	$v0, 4		# syscall 4, pisz string
	la	$a0, prompt4	
	syscall	
#odczytaj wage pikselu centralnego
	li	$v0, 5		# syscall 5, czytaj int	
	syscall
	move 	$s2, $v0	
#usun enter z konca nazw plikow
	li	$t0, '\n'	#znak nowej linii
	li	$t1, 0		#max dlugosc nazwy
#policz sume wag
	mul	$s0, $s1, 8
	add	$s0, $s0, $s2
remove_newline_input:
	addi	$t1, $t1, 1				#mozemy pominac indeks 0, bo nie moze byc nazwa pliku pusta
	lb	$t2, input_file($t1)
	bne	$t2, $t0, remove_newline_input
	beq	$t1, 128, exit				#nazwa niepoprawna
	sb	$zero, input_file($t1)
initiate_loop:
	li	$t0, '\n'	#znak nowej linii
	li	$t1, 0		
remove_newline_output:
	addi	$t1, $t1, 1				#mozemy pominac indeks 0, bo nie moze byc nazwa pliku pusta
	lb	$t2, output_file($t1)
	bne	$t2, $t0, remove_newline_output
	beq	$t1, 128, exit				#nazwa niepoprawna
	sb	$zero, output_file($t1)	
open_file:
#otworz plik wejsciowy i sprawdz czy sie udalo
	li 	$v0, 13
	la	$a0, input_file
	li	$a1, 0
	li	$a2, 0
	syscall
	bltz	$v0, error_file		#jesli deskryptor <0, to plik sie nie otworzyl
	move	$s3, $v0
#otworz plik wyjsciowy i sprawdz czy sie udalo
	li 	$v0, 13
	la	$a0, output_file
	li	$a1, 1
	li	$a2, 0
	syscall
	bltz	$v0, error_file		#jesli deksryptor <0, to plik sie nie otworzyl
	move	$s4, $v0
header_stuff:
#odczytujemy naglowek
	li	$v0, 14			#czytanie z pliku
	move	$a0, $s3		#adres pliku wejsciowego
	la	$a1, header		#bufor naglowka
	li	$a2, 54			#dlugosc naglowka
	syscall
#zapisujemy wysokosc i szerokosc obrazka. Sprawdzamy czy jestesmy w stanie go przetworzyc	
	lw	$s5, header+18		#zaladowanie szerokosci obrazka
	lw	$s6, header+22		#zaladowanie wysokosci obrazka
	mul 	$t5, $s5, 3
#sprawdzamy czy mamy wystarczajacy bufor
	mul 	$t0, $s5, 6		#rozmiar dwoch linii pliku w bajtach (2 linie po 3 bajty na piskel)
	addi	$t0, $t0, 9		#3 piskele pod wyliczanym pikselem
	li	$t1, 9216
	ble	$t1, $t0, exit_buf	#jesli nawet dwie linie i 3 piskele pod drugim nie mieszcza sie w buforze, to nie ma sensu kontynuowac
	
#po odczytaniu naglowka od razu wklejamy go do nowego pliku; naglowki zostaja w koncu takie same
	li	$v0, 15			#zapis do pliku
	move	$a0, $s4		#adres pliku wyjsciowego
	la	$a1, header		#bufor naglowka
	li	$a2, 54			#dlugosc naglowka
	syscall
read_buffer:
#ladujemy bufor
	li	$v0, 14
	move	$a0, $s3
	la	$a1, buff
	li	$a2, 9216
	syscall
	li	$t9, 0		#ktory bajt zaczynamy liczyc
calculate_padding:
#liczymy ile bajtow dopelnia wiersz do 4
	mul	$s5, $s5, 3
	li	$t8, 4
	div	$s5, $t8
	mfhi	$t5
	sub	$t5, $t8, $t5
	beq	$t5, 4, zero_padding 	#jesli mamy wielokrotnosc 4 w rzedzie, to zerujemy wyrownainie
load_buffer_address:
	la	$t2, buff	#ladujemy adres pierwszego piksela
	add	$s5, $s5, $t5	#dodajemy padding
	mul	$s6, $s6, $s5	#oblicz ilosc bajtow do obrobienia
	move	$t0, $s6
	
######################################################################
# s0 - suma wag				(nie mozna uzyc gdzie indziej)
# s1 - waga piksela obwodowego		(nie mozna uzyc gdzie indziej)
# s2 - waga piskelca centralnego	(nie mozna uzyc gdzie indziej)
# s5 - szerokosc (bajty)		(nie mozna uzyc gdzie indziej)
# s6 - bajty do obrobienia		(nie mozna uzyc gdzie indziej)
# t2 - obecny adres			(nie mozna uzyc gdzie indziej)
# t8 - obrabiany kolor pikselu		(nie mozna uzyc gdzie indziej)
# t9 - obrabiany bajt w buforze		(nie mozna uzyc gdzie indziej)
# s7 - dane do zaladowania		(mozna uzyc gdzie indziej)
# t3 - adres do liczenia		(mozna uzyc gdzie indziej)
# t6 - wartosc koloru			(mozna uzyc gdzie indziej)
# t7 - srednia				(mozna uzyc gdzie indziej)
# t0 - ilosc wszystkij bajtow		(nie mozna uzyc gdzie indziej)
# t1 - obrobione do tej pory bajty	(nie mozna uzyc gdzie indziej)

loop:
#mamy bufor wiec zaczynamy liczyc
	blez	$s6, exit	#zorbilismy wszystkie bajty wiec koniec
	lb	$t7, ($t2)
	ble	$s6, $s5, save	#w ostatnim rzedzie nic nie zapisujemy
calculation_check:
#sprawdzamy czy istnieje gorny lewy
	sub	$t1, $t0, $s6	#sprawdzamy ile bajtow juz zrobilismy
	subi	$t1, $t0, 3	#nie obliczamy pierwszego piksela z drugiego rzedu
	ble	$t1, $s5, save  #w pierwszym rzedzie nic nie zapisujemy

#sprawdzamy czy istnieje dolny prawy
	add	$t5, $t9, $s5
	add	$t5, $t5, 3
	bgt	$t5, 9216, reload_buff	#jesli nie, to przeladowujemy bufor
calculation:
#sprawdzilismy czy wszystkie bajty sa dostepne, wiec liczymy
	move	$t7, $zero	#resetujemy srednia
#dolny prawy
	add 	$t3, $t2, $s5
	addi 	$t3, $t3, 3
	lb	$t6, ($t3)
	sll 	$t6, $t6, 24 
	srl	$t6, $t6, 24
	mul 	$t6, $s1, $t6
	add 	$t7, $t7, $t6
#dolny srodek
	add 	$t3, $t2, $s5
	lb	$t6, ($t3)
	sll 	$t6, $t6, 24 
	srl	$t6, $t6, 24
	mul 	$t6, $s1, $t6
	add 	$t7, $t7, $t6
#dolny lewy
	add 	$t3, $t2, $s5
	addi 	$t3, $t3, -3
	lb	$t6, ($t3)
	sll 	$t6, $t6, 24 
	srl	$t6, $t6, 24
	mul 	$t6, $s1, $t6
	add 	$t7, $t7, $t6
#srodek prawy
	move 	$t3, $t2
	addi 	$t3, $t3, 3
	lb	$t6, ($t3)
	sll 	$t6, $t6, 24 
	srl	$t6, $t6, 24
	mul 	$t6, $s1, $t6
	add 	$t7, $t7, $t6
#srodek srodek
	move 	$t3, $t2
	lb	$t6, ($t3)
	sll 	$t6, $t6, 24 
	srl	$t6, $t6, 24
	mul 	$t6, $s2, $t6
	add 	$t7, $t7, $t6
#srodek lewy
	move 	$t3, $t2
	addi 	$t3, $t3, -3
	lb	$t6, ($t3)
	sll 	$t6, $t6, 24 
	srl	$t6, $t6, 24
	mul 	$t6, $s1, $t6
	add 	$t7, $t7, $t6
#gora prawy
	sub 	$t3, $t2, $s5
	addi 	$t3, $t3, 3
	lb	$t6, ($t3)
	sll 	$t6, $t6, 24 
	srl	$t6, $t6, 24
	mul 	$t6, $s1, $t6
	add 	$t7, $t7, $t6
#gora centrum
	sub 	$t3, $t2, $s5
	lb	$t6, ($t3)
	sll 	$t6, $t6, 24 
	srl	$t6, $t6, 24
	mul 	$t6, $s1, $t6
	add 	$t7, $t7, $t6
#gora lewy
	sub 	$t3, $t2, $s5
	addi 	$t3, $t3, -3
	lb	$t6, ($t3)
	sll 	$t6, $t6, 24 
	srl	$t6, $t6, 24
	mul 	$t6, $s1, $t6
	add 	$t7, $t7, $t6
#wylicz srednia
	div	$t7, $t7, $s0
division_check:
#mozliwe, ze przestrzelilismy powyzej/ponizej 255 i 0, wiec trzeba to naprawic
	bge	$t7, $zero, check1	#sprawdzamy czy mam mniej niz 0
	li	$t7, 0
check1:
	ble	$t7, 255, save		#sprawdzamy czy mamy mniej niz 255
	li	$t7, 255
save: 
#zapisanie danych do bufora wyjsciowego
	sb	$t7, out_buff
#zapis do pliku
	li	$v0, 15
	move	$a0, $s4
	la	$a1, out_buff
	li	$a2, 1
	syscall
	addi 	$t9, $t9, 1	#przechodzimy do kolejnego bajtu
	addi	$t2, $t2, 1	#przechodzimy do adresu kolejnego bajtu
	subi	$s6, $s6, 1	#zmniejszamy liczbe bajtow do obrobienia
	j	loop		#liczymy kolejny kolor
exit:
#zamykamy plik wejsciowy
	li	$v0, 16
	move	$a0, $s3
	syscall
#zamykamy plik wyjsciowy		
	li	$v0, 16
	move	$a0, $s4
	syscall
	
	li	$v0, 10
	syscall
	
exit_buf:
	li	$v0, 4
	la	$a0, prompt6
	syscall
#zamykamy plik wejsciowy
	li	$v0, 16
	move	$a0, $s3
	syscall
#zamykamy plik wyjsciowy		
	li	$v0, 16
	move	$a0, $s4
	syscall
	li	$v0, 10
	syscall
error_file:
	li 	$v0, 4
	la 	$a0, prompt5
	syscall
	j 	main
reload_buff:
#################################################################
# s7 - liczba bajtow do zaladowania
# t4 - tyle bajtow trzeba przekopiowac: 9216 - s7
# t3 - adres bufora
# t6 - adres bajtu do skopiowanie
# t9 - obrabiany piksel w buforze
# s5 - szerokosc

#obliczamy liczbe bajtow do zaladowania
	sub	$s7, $t9, $s5	
	subi	$s7, $s7, 2
	sub	$t9, $t9, $s7 		#ustawiamy nowa wartosc licznika obecnego bajtu
	
	li	$t4, 9216
	sub	$t4, $t4, $s7		#ustalamy licznik bajtow do skopiowania	
	sub	$t2, $t2, $s7		#przesuwamy obecny adres w buforze
	
	la	$t3, buff
	add	$t6, $t3, $s7		#ustawiamy adres pierwszego bajtu do skopiowania

#przesuwamy bufor o t4 miejsc w lewo
move_buff:
	lb	$t7, ($t6)		#ladujemy bajt z konca...
	sb	$t7, ($t3)		#przepisujemy na poczatek
	addi	$t3, $t3, 1		#przechodzimy na kolejny bajt bufora
	addi	$t6, $t6, 1		#przechodzimy na kolejny bajt bufora
	subi	$t4, $t4, 1		#zmniejszamy licznik
	bgtz	$t4, move_buff
reload_buff_fin:
#ladujemy nowe dane
	li	$v0, 14
	move	$a0, $s3
	la	$a1, ($t3)
	move	$a2, $s7
	syscall
	j	loop
zero_padding:
	move	$t5, $zero
	j 	load_buffer_address

