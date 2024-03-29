// Obrazek.cpp: definiuje punkt wejścia dla aplikacji konsolowej.
//

#include "stdafx.h"
#include <iostream>
#include <SDL.h>
#include <intrin.h>


extern "C" int CalcFilter(char *pixelArrayInput, char *pixelArrayOutput, int number, int width, int central, int border, int medianSum);

void charToInt(char *input, int width, int height, int* output) {
	int num = 1;
	for (int i = 0, j = 0; i < width*height; i++, j += 4) {
		output[i] = *((int *)(input + j));
	}

	if (*(char *)&num == 1)
	{
		//JESLI LITTLE-ENDIAN, to trzeba odwrocic kolejnosc, zeby dzilalao
		for (int i = 0; i < width*height; i++) {
			output[i] = _byteswap_ulong(output[i]);
		}
	}
}

SDL_Surface * create_surf(char *input, char *output, int* intOutput, int width, int height, int central, int border) {
	CalcFilter(input, output, width*height * 4, width * 4, central, border, central + (8 * border));
	charToInt(input, width, height, intOutput);
	return  SDL_CreateRGBSurfaceFrom(
		(void*)intOutput,
		width,		//width
		height,		//height
		32,			//depth
		width * 4,	//pitch
		0xFF0000,
		0x00FF00,
		0x0000FF,
		0
	);
}



int main(int argc, char ** argv)
{
	bool quit = false;
	SDL_Event event;
	char filename[25];
	FILE * bmpImage;
	int width, height;
	int padding;
	SDL_Init(SDL_INIT_VIDEO);
	Uint32 *pixel = new Uint32;

	std::cout << "Podaj nazwe pliku: ";
	std::cin >> filename;

	bmpImage = fopen(filename, "rb");
	if (bmpImage == NULL) {
		std::cout << "Blad otwarcia pliku!" << std::endl;
		return 0;
	}

	fseek(bmpImage, 18, SEEK_SET); //ustawiamy poczatek na szerokosc
	fread((void*)pixel, 4, 1, bmpImage);
	width = *pixel;

	fseek(bmpImage, 22, SEEK_SET); //ustawiamy poczatek na wysokosc
	fread((void*)pixel, 4, 1, bmpImage);
	height = *pixel;


	int * PixelArray = new int[width*height];
	int * PixelArrayOutput = new int[width*height];

	padding = width * 3;	//tyle bajtow na rzad
	padding = padding % 4;	//jaki nadmiar
	padding = 4 - padding;	//ile brakuje do 4
	padding = padding % 4;	//zamiana 4 na 0


	fseek(bmpImage, 54, SEEK_SET); //ustawiamy poczatek na rozpoaczecie tablicy pikseli

	for (int i = (height - 1)*(width); i >= 0; i -= width) {
		for (int j = i; j < i + width; j++) {
			fread((void*)pixel, 3, 1, bmpImage);
			//(*pixel) = (*pixel) >> 8;
			PixelArray[j] = *pixel;
		}
		fseek(bmpImage, padding, SEEK_CUR);
	}

	char *charArray = new char[width*height * 4];
	char *charArrayOutput = new char[width*height * 4];

	for (int i = 0; i < width*height * 4; i++) {
		charArray[i] = 0;
		charArrayOutput[i] = 0;
	}

	for (int i = 0, j = 0; i < width*height; i++, j += 4) {
		charArray[j] = PixelArray[i] >> 24;
		charArray[j + 1] = PixelArray[i] >> 16;
		charArray[j + 2] = PixelArray[i] >> 8;
		charArray[j + 3] = PixelArray[i] & 0xff;
	}

	SDL_Surface * Image = SDL_CreateRGBSurfaceFrom(
		(void*)PixelArray,
		width,		//width
		height,		//height
		32,			//depth
		width * 4,	//pitch
		0xFF0000,
		0x00FF00,
		0x0000FF,
		0
	);

	SDL_Window * window = SDL_CreateWindow("SDL2 Pixel Drawing",
		SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, 0);

	SDL_Renderer * renderer = SDL_CreateRenderer(window, -1, 0);
	SDL_Texture * texture = SDL_CreateTextureFromSurface(renderer, Image);

	bool switched = false;

	int position = 0;
	while (!quit)
	{
		SDL_RenderCopy(renderer, texture, NULL, NULL);
		SDL_RenderPresent(renderer);

		SDL_WaitEvent(&event);
		switch (event.type)
		{
		case SDL_QUIT:
			quit = true;
			break;
		case SDL_KEYDOWN:
			switch (event.key.keysym.sym) {
			case SDLK_LEFT:
				position--;
				switched = true;
				break;
			case SDLK_RIGHT:
				position++;
				switched = true;
				break;
			}
			break;
		}
		if (switched) {
			switch (position) {
			case -1:				
				CalcFilter(charArray, charArrayOutput, width*(height-1) * 4, width * 4, 1, 1, 9);
				for (int i = (width - 1)*height*4; i < width*height * 4; i++) {
					charArrayOutput[i] = charArray[i];
				}
				charToInt(charArrayOutput, width, height, PixelArrayOutput);
				SDL_UpdateTexture(texture, NULL, (void*)PixelArrayOutput, width * 4);
				break;
			case 0:
				SDL_UpdateTexture(texture, NULL, (void*)PixelArray, width * 4);
				break;
			case 1:
				CalcFilter(charArray, charArrayOutput, width*(height-1) * 4, width * 4, 9, -1, 1);
				for (int i = (width - 1)*height * 4; i < width*height * 4; i++) {
					charArrayOutput[i] = charArray[i];
				}
				charToInt(charArrayOutput, width, height, PixelArrayOutput);
				SDL_UpdateTexture(texture, NULL, (void*)PixelArrayOutput, width * 4);
				break;
			}
		}
		switched = false;
	}

	SDL_DestroyRenderer(renderer);
	SDL_DestroyWindow(window);
	SDL_DestroyTexture(texture);
	SDL_Quit();
	fclose(bmpImage);
	delete PixelArray;
	delete pixel;
	delete charArray;
	delete charArrayOutput;
	return 0;
}

/*std::cout << "--------------------------------" << std::endl;
for (int i = 0; i < (width)*(height)*4; i++) {
for (int j = 7; j >= 0; j--) {
std::cout << ((chararray[i] >> j) & 1);
}
std::cout << std::endl;
}
std::cout << "--------------------------------" << std::endl;*/


/*for (int i = 0; i < (width)*(height); i++) {
for (int j = 31; j >= 0; j--) {
std::cout << ((PixelArray[i] >> j) & 1);
}
std::cout << "\t";
std::cout << std::hex << PixelArray[i] << "\t";
std::cout << std::dec << PixelArray[i] << std::endl;
}
std::cout << "--------------------------------" << std::endl;*/

/*for (int i = 0; i < (width)*(height); i++) {
for (int j = 31; j >= 0; j--) {
std::cout << ((PixelArray[i] >> j) & 1);
}
std::cout << "\t";
std::cout << std::hex << PixelArray[i] << "\t";
std::cout << std::dec << PixelArray[i] << std::endl;
}
std::cout << "--------------------------------" << std::endl;*/