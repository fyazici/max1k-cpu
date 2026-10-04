// Emacs style mode select   -*- C++ -*-
//-----------------------------------------------------------------------------
//
// $Id:$
//
// Copyright (C) 1993-1996 by id Software, Inc.
//
// This source is available for distribution and/or modification
// only under the terms of the DOOM Source Code License as
// published by id Software. All rights reserved.
//
// The source is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// FITNESS FOR A PARTICULAR PURPOSE. See the DOOM Source Code License
// for more details.
//
// $Log:$
//
// DESCRIPTION:
//	DOOM graphics stuff for X11, UNIX.
//
//-----------------------------------------------------------------------------

static const char
		rcsid[] = "$Id: i_x.c,v 1.6 1997/02/03 22:45:10 b1 Exp $";

#include <stdlib.h>
#include <unistd.h>

#include <stdarg.h>
#include <sys/time.h>
#include <sys/types.h>
#include <errno.h>
#include <signal.h>

#include "doomstat.h"
#include "i_system.h"
#include "v_video.h"
#include "m_argv.h"
#include "d_main.h"

#include "doomdef.h"

#include <platform.h>

void I_ShutdownGraphics(void)
{
}

//
// I_StartFrame
//
void I_StartFrame(void)
{
	/*
	static int frame_ctr = 0;
	static uint64_t last_cyc = 0;
	static uint64_t last_ins = 0;

	frame_ctr++;
	uint64_t cycles = csr_read_mcycle();
	if ((cycles - last_cyc) > PERIPH_CLK_HZ) // every 1 sec
	{
		uint64_t instret = csr_read_minstret();
		uint64_t c_diff = cycles - last_cyc;
		uint64_t i_diff = instret - last_ins;
		last_cyc = cycles;
		last_ins = instret;

		uint32_t hit_ctr_i = HAL_cache_get_hit_ctr(ICACHE_BASEADDR);
		uint32_t miss_ctr_i = HAL_cache_get_miss_ctr(ICACHE_BASEADDR);
		uint32_t hit_ctr_d = HAL_cache_get_hit_ctr(DCACHE_BASEADDR);
		uint32_t miss_ctr_d = HAL_cache_get_miss_ctr(DCACHE_BASEADDR);

		printf("[PLT] FPS=%d\n", frame_ctr);

		float cpi_int = (float)c_diff / (float)i_diff;
		printf("[PLT] C: %llu I: %llu CPI: %.3f\n", c_diff, i_diff, cpi_int);
		float hit_rate_i = (float)hit_ctr_i / ((float)hit_ctr_i + (float)miss_ctr_i);
		printf("[PLT] I$ H: %u M: %u HitRate: %.3f\n", hit_ctr_i, miss_ctr_i, hit_rate_i);
		float hit_rate_d = (float)hit_ctr_d / ((float)hit_ctr_d + (float)miss_ctr_d);
		printf("[PLT] D$ H: %u M: %u HitRate: %.3f\n", hit_ctr_d, miss_ctr_d, hit_rate_d);

		frame_ctr = 0;
	}
	*/
}

void I_GetEvent(void)
{
}

//
// I_StartTic
//
void I_StartTic(void)
{
}

//
// I_UpdateNoBlit
//
void I_UpdateNoBlit(void)
{
}

char myPalette[256 * 3];

//
// I_FinishUpdate
//
void I_FinishUpdate(void)
{
	static int frame_ctr = 0;
	frame_ctr++;

	((volatile struct HAL_Gpio *)GPIO0_BASEADDR)->odr = frame_ctr;

#ifdef XTERM_VIDEO
	char buf[4096];

	printf("\033[H");
	for (int y = 0; y < 200; y += 2)
	{
		memset(buf, 0, sizeof(buf));
		char *ptr = buf;

		for (int x = 0; x < 320; x += 2)
		{
			char c = screens[0][y * 320 + x];
			int r = myPalette[3 * c + 0];
			int g = myPalette[3 * c + 1];
			int b = myPalette[3 * c + 2];
			ptr += sprintf(ptr, "\033[48;2;%d;%d;%dm ", r, g, b);
		}

		puts(buf);
	}
#else
	static uint64_t last_cyc = 0;
	static uint64_t last_ins = 0;

	uint64_t cycles = csr_read_mcycle();
	if ((cycles - last_cyc) > PERIPH_CLK_HZ) // every 1 sec
	{
		uint64_t instret = csr_read_minstret();
		uint64_t c_diff = cycles - last_cyc;
		uint64_t i_diff = instret - last_ins;
		last_cyc = cycles;
		last_ins = instret;

		uint32_t hit_ctr_i = HAL_cache_get_hit_ctr(ICACHE_BASEADDR);
		uint32_t miss_ctr_i = HAL_cache_get_miss_ctr(ICACHE_BASEADDR);
		uint32_t hit_ctr_d = HAL_cache_get_hit_ctr(DCACHE_BASEADDR);
		uint32_t miss_ctr_d = HAL_cache_get_miss_ctr(DCACHE_BASEADDR);

		printf("[PLT] FPS=%d\n", frame_ctr);

		float cpi_int = (float)c_diff / (float)i_diff;
		printf("[PLT] C: %llu I: %llu CPI: %.3f\n", c_diff, i_diff, cpi_int);
		float hit_rate_i = (float)hit_ctr_i / ((float)hit_ctr_i + (float)miss_ctr_i);
		printf("[PLT] I$ H: %u M: %u HitRate: %.3f\n", hit_ctr_i, miss_ctr_i, hit_rate_i);
		float hit_rate_d = (float)hit_ctr_d / ((float)hit_ctr_d + (float)miss_ctr_d);
		printf("[PLT] D$ H: %u M: %u HitRate: %.3f\n", hit_ctr_d, miss_ctr_d, hit_rate_d);

		frame_ctr = 0;
	}
#endif
}

//
// I_ReadScreen
//
void I_ReadScreen(byte *scr)
{
	memcpy(scr, screens[0], SCREENWIDTH * SCREENHEIGHT);
}

//
// I_SetPalette
//
void I_SetPalette(byte *palette)
{
	memcpy(myPalette, palette, sizeof(myPalette));
}

void I_InitGraphics(void)
{
	// TODO: pass this to VGA DMA controller
	screens[0] = (unsigned char *)malloc(SCREENWIDTH * SCREENHEIGHT);
}
