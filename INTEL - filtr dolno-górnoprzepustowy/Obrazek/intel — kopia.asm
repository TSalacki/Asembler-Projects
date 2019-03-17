;=====================================================================
; ARKO - Filtr dolno/gornoprzepustowy
;=====================================================================
; Param	Qword	Dword	Word	Byte
; 1st	RCX		ECX		CX		CL		pixelArrayInput		- adres oryginalnej tablicy pikseli
; 2nd	RDX		EDX		DX		DL		PixelArrayOutput	- adres wyjsciowej tablicy pikseli
; 3rd	R8		R8D		R8W		R8B		number				- liczba wszystkich bajtow (4*pixele)
; 4th	R9		R9D		R9W		R9B		width				- szerokosc linijki (w bajtach)
; 5				rsp+48					central				- waga piksela centralnego
; 6				rsp+56					border				- waga piksela obwodowego
; 7				rsp+64					sumMedian			- suma wag
;=====================================================================
;				r10d										- licznik bajtow
;				r11d										- srednia
;				r12d										- obrabiany bajt
;				r13d										- adres 
;				r15d										- przez czas trwania funkcji adres tablicy wyjsciowej

.data
Var255 QWORD 255
Var0 QWORD 0

.code
CalcFilter proc central: DWORD, border: DWORD
main_dest:		
	
	mov r15, rdx				;przenosimy adres drugiej tablicy do r15 - edx bedzie potrzebny przy dzieleniu
	mov r10, 0					;ustawiamy licznik bajtow na 0
loop_dest:
	cmp r10, r8					;sprawdzamy czy mamy wszystko
	je exit_dest				;jesli zrobilismy juz ostatni, to koniec
	
	mov r11, [rcx+r10]			;umieszczamy wartosc koloru w r11d na potrzeby zapisu bez modyfikacji
	shl r11, 56					;czyscimy pozostale bity
	shr r11, 56					;czyscimy pozostale bity
	;jmp save_dest

	sub r10, r9					;sprawdzamy czy istnieje gora lewy
	sub r10, 4	

	cmp	Var0, r10
	jg	save_dest_repair_add	;jesli gora lewy nie istnieje, to zapisujemy bez liczenia, ale wczesniej przywracamy odpowiedniwa wartosc

	add r10, r9					;jesli gora lewy istnieje, to naprawiamy i patrzymy dalej
	add r10, 4

	add r10, r9					;sprawdzamy czy istnieje dol prawy
	add r10, 4
	cmp r8, r10					;sprawdzamy czy wyszlismy poza zakres
	jl	save_dest_reapair_sub	;jesli dol prawy nie istnieje, to zapisujemy bez liczenia, ale wczesniej przywracamy odpowiedniwa wartosc

	sub r10, r9					;jesli prawy dol istnieje, to naprawiamy 
	sub r10, 4
	
	;jmp save_dest
;======================================================================
;	zarowno gora i dol istnieja, wiec zaczynamy liczenie
;======================================================================
	mov r11, 0					;zerujemy srednia

up_left:
	sub rcx, r10				;ustawiamy adres w tablicy pierwszej na obrabiany bajt
	sub rcx, 4
	mov rax, [rcx]				;umieszczamy wartosc koloru w r12d	
	shl rax, 56
	shr rax, 56
	ret
	shl r12, 56					;czyscimy pozostale bity
	shr r12, 56					;czyscimy pozostale bity
	imul r12, [rsp+56]			;mnozymy kolor razy jego waga

	;mov rax, r12
	ret

	add rcx, r10				;ustawiamy adres w tablicy pierwszej do wartosci sprzed operacji
	add rcx, 4

	add r11, r12				;zwiekszamy srednia
up_middle:
	sub rcx, r10				;ustawiamy adres w tablicy pierwszej na obrabiany bajt
	mov r12, [rcx]				;umieszczamy wartosc koloru w r12d
	shl r12, 56					;czyscimy pozostale bity
	shr r12, 56					;czyscimy pozostale bity
	imul r12, [rsp+56]			;mnozymy kolor razy jego waga

	add rcx, r10				;ustawiamy adres w tablicy pierwszej do wartosci sprzed operacji

	add r11, r12				;zwiekszamy srednia
up_right:
	sub rcx, r10				;ustawiamy adres w tablicy pierwszej na obrabiany bajt
	add rcx, 4
	mov r12, [rcx]				;umieszczamy wartosc koloru w r12d
	shl r12, 56					;czyscimy pozostale bity
	shr r12, 56					;czyscimy pozostale bity
	imul r12, [rsp+56]			;mnozymy kolor razy jego waga

	add rcx, r10				;ustawiamy adres w tablicy pierwszej do wartosci sprzed operacji
	sub rcx, 4

	add r11, r12				;zwiekszamy srednia
middle_left:
	sub rcx, 4					;ustawiamy adres w tablicy pierwszej na obrabiany bajt
	mov r12, [rcx]				;umieszczamy wartosc koloru w r12d
	shl r12, 56					;czyscimy pozostale bity
	shr r12, 56					;czyscimy pozostale bity
	imul r12, [rsp+56]			;mnozymy kolor razy jego waga

	add rcx, 4					;ustawiamy adres w tablicy pierwszej do wartosci sprzed operacji

	add r11, r12				;zwiekszamy srednia
middle_middle:
	mov r12, [rcx]				;umieszczamy wartosc koloru w r12d
	shl r12, 56					;czyscimy pozostale bity
	shr r12, 56					;czyscimy pozostale bity
	imul r12, [rsp+48]			;mnozymy kolor razy jego waga

	add r11, r12				;zwiekszamy srednia
middle_right:
	add rcx, 4
	mov r12, [rcx]				;umieszczamy wartosc koloru w r12d
	shl r12, 56					;czyscimy pozostale bity
	shr r12, 56					;czyscimy pozostale bity
	imul r12, [rsp+56]			;mnozymy kolor razy jego waga

	sub rcx, 4					;ustawiamy adres w tablicy pierwszej do wartosci sprzed operacji

	add r11, r12				;zwiekszamy srednia
down_left:
	add rcx, r10				;ustawiamy adres w tablicy pierwszej na obrabiany bajt
	sub rcx, 4
	mov r12, [rcx]				;umieszczamy wartosc koloru w r12d
	shl r12, 56					;czyscimy pozostale bity
	shr r12, 56					;czyscimy pozostale bity
	imul r12, [rsp+56]			;mnozymy kolor razy jego waga

	sub rcx, r10				;ustawiamy adres w tablicy pierwszej do wartosci sprzed operacji
	add rcx, 4

	add r11, r12				;zwiekszamy srednia
down_middle:
	add rcx, r10				;ustawiamy adres w tablicy pierwszej na obrabiany bajt
	mov r12, [rcx]				;umieszczamy wartosc koloru w r12d
	shl r12, 56					;czyscimy pozostale bity
	shr r12, 56					;czyscimy pozostale bity
	imul r12, [rsp+56]			;mnozymy kolor razy jego waga

	sub rcx, r10				;ustawiamy adres w tablicy pierwszej do wartosci sprzed operacji

	add r11, r12				;zwiekszamy srednia
down_right:
	add rcx, r10				;ustawiamy adres w tablicy pierwszej na obrabiany bajt
	add rcx, 4
	mov r12, [rcx]				;umieszczamy wartosc koloru w r12d
	shl r12, 56					;czyscimy pozostale bity
	shr r12, 56					;czyscimy pozostale bity
	imul r12, [rsp+56]			;mnozymy kolor razy jego waga

	sub rcx, r10				;ustawiamy adres w tablicy pierwszej do wartosci sprzed operacji
	sub rcx, 4

	add r11, r12				;zwiekszamy srednia

calc_color_dest:				
	;mov rax, r10
	;ret
	mov edx, 0
	mov rax, r11
	div DWORD PTR [rsp+64]
	mov r11, rax


;poniewaz moze sie zdarzyc, ze przestrzelimy powyzej 255/ponizej 0, to trzeba sie tym odpowiednio zajac
check1_dest:
	cmp r11, Var0				;sprawdzamy czy mniej niz 0
	jns check2_dest				;jesli nie to skaczemy do drugiego testu
	mov r11, Var0				;jesli tak, to umieszczamy tam zero i zapisujemy
	jmp save_dest

check2_dest:
	cmp Var255, r11				;sprawdzamy czy jest wiecej niz 255
	jns save_dest				;jesli nie, to zapisujemy
	mov r11, Var255				;jesli jest wiecej, to wpisujemy 255 i zapisujemy
	jmp save_dest



save_dest_repair_add:
	;mov rax, r10
	;ret
	add r10, r9					;przywracamy poprzednia wartosc
	add r10, 4
	jmp save_dest

save_dest_reapair_sub:
	;mov rax, r10
	;ret
	sub r10, 4					;przywracamy poprzednia wartosc
	sub r10, r9
	jmp save_dest



save_dest:
	mov [r15+r10], r11			;wpisujemy odpowiedni kolor 

	add r10, 1					;zwiekszamy liczbe obrobionych bajtow

	jmp loop_dest				;zapisalismy, wiec wracamy na poczatek petli


exit_dest:	
	mov rdx, r15				;przywracamy adres drugiej tablicy
	mov rax, r10
	ret
CalcFilter endp
end

;============================================
; STOS
;============================================
;
; wieksze adresy
; 
;  |                             |
;  | ...                         |
;  -------------------------------
;  | parametr funkcji - int *a   | EBP+8
;  -------------------------------
;  | adres powrotu               | EBP+4
;  -------------------------------
;  | zachowane ebp               | EBP, ESP
;  -------------------------------
;  | ... tu ew. zmienne lokalne  | EBP-x
;  |                             |
;
; \/                         \/
; \/ w ta strone rosnie stos \/
; \/                         \/
;
; mniejsze adresy
;
;
;============================================
