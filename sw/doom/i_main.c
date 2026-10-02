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
//	Main program, simply calls D_DoomMain high level loop.
//
//-----------------------------------------------------------------------------

static const char
    rcsid[] = "$Id: i_main.c,v 1.4 1997/02/03 22:45:10 b1 Exp $";

#include "doomdef.h"

#include "m_argv.h"
#include "d_main.h"

#include <platform.h>

int main()
{
  myargc = 0;
  myargv = 0;

  HAL_uart_init(UART0_BASEADDR, 1000000);
  printf("[PLATFORM] Let there be light...\n");

  // mark lower 128MB (includes 0-8MB sdram) I$ cacheable
  HAL_cache_set_mask(ICACHE_BASEADDR, 0x00000001);
  HAL_cache_invalidate(ICACHE_BASEADDR);
  HAL_cache_clear_counters(ICACHE_BASEADDR);
  printf("[PLATFORM] I$ configured.\n");

  // mark lower 128MB (includes 0-8MB sdram) D$ cacheable
  HAL_cache_set_mask(DCACHE_BASEADDR, 0x00000001);
  HAL_cache_invalidate(DCACHE_BASEADDR);
  HAL_cache_clear_counters(DCACHE_BASEADDR);
  printf("[PLATFORM] D$ configured.\n");

  printf("[PLATFORM] Calling D_DoomMain()...\n");
  D_DoomMain();

  return 0;
}
