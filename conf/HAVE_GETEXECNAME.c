#include <stdlib.h>

int main(int argc, char **argv)
{
    return getexecname() ? 0 : 1;
}
