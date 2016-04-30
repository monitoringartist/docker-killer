#include <stdio.h>

int main(void) {
  for(;;)
    fork();
  return 0;
}
