#include <QCoreApplication>
#define YY_NO_UNISTD_H
#include "pcl-hpgl.lexer.h"

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    yyscan_t scanner;
    FILE * inputFile = 0;
    if (argc > 1)
        inputFile = fopen(argv[1], "rb");
    yylex_init( &scanner );
    if(argc > 1 && inputFile)
        yyset_in(inputFile,scanner);
    else
        yyset_in(stdin,scanner);
    yylex(scanner);
    yylex_destroy(scanner);
    if(inputFile)
        fclose(inputFile);

    return a.exec();
}
