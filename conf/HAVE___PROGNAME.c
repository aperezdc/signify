extern const char *__progname;

int main(int argc, char **argv)
{
    return __progname ? 0 : 1;
}
