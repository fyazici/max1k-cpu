/*
Longest Collatz sequence
Problem 14
The following iterative sequence is defined for the set of positive integers:

n → n/2 (n is even)
n → 3n + 1 (n is odd)

Using the rule above and starting with 13, we generate the following sequence:

13 → 40 → 20 → 10 → 5 → 16 → 8 → 4 → 2 → 1
It can be seen that this sequence (starting at 13 and finishing at 1)
contains 10 terms.
Although it has not been proved yet (Collatz Problem),
it is thought that all starting numbers finish at 1.

Which starting number, under one million, produces the longest chain?

NOTE: Once the chain starts the terms are allowed to go above one million.
*/

#include <stdint.h>

uint32_t longest_collatz_sequence(uint32_t limit);

uint32_t longest_collatz_sequence(uint32_t limit)
{
  uint32_t max_chain_length = 0;
  uint32_t cur_chain_length = 0;
  uint32_t max_chain_init = 0;
  uint32_t i, n;

  for (i = 2; i < limit; i++)
  {
    n = i;
    cur_chain_length = 0;
    while (n > 1)
    {
      if (n & 1)
        n += (n << 1) + 1;
      else
        n >>= 1;
      cur_chain_length += 1;
    }

    if (cur_chain_length > max_chain_length)
    {
      max_chain_length = cur_chain_length;
      max_chain_init = i;
    }
  }

  return max_chain_init;
}