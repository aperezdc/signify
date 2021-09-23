#include <errno.h>

int main(int argc, char **argv)
{
    return program_invocation_short_name ? 0 : 1;
}
