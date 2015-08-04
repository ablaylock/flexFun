%option noyywrap
%option never-interactive
%option nounistd
%option backup
%option warn
%option reentrant
%option outfile="pcl-hpgl-scanner.cpp" header-file="pcl-hpgl-scanner.h"
%option full 
%option ecs



%{
#define ENA_PRINTING
%}

%x PCL_ESCAPE_SEQ
%x PCL_TWO_ESCAPE_SEQ
%x PJL_COMMAND
%x HPGL_MODE

%%

<INITIAL,PCL_ESCAPE_SEQ,HPGL_MODE>\x1b%-12345X {
    #ifdef ENA_PRINTING
    printf("Universal Exit Language Command\n");
    #endif
	BEGIN(INITIAL);
}

<INITIAL,PCL_ESCAPE_SEQ,HPGL_MODE>\x1bE {
	#ifdef ENA_PRINTING
	printf("PCL Printer Reset Command\n");
	#endif
	BEGIN(INITIAL);
}

\x1b/[\x21-\x2f] {
	#if defined(ENA_PRINTING)
	printf("PCL Parameterized Escape Sequence\n");
	#endif
	BEGIN(PCL_ESCAPE_SEQ);
}

\x1b/[\x30-\x7E] {
	#ifdef ENA_PRINTING
	printf("PCL TWO CHAR ESCAPE SEQ ");
	#endif
	BEGIN(INITIAL);
}

<INITIAL,PCL_ESCAPE_SEQ,HPGL_MODE,PJL_COMMAND>(?s:.) {
	#if defined(ENA_PRINTING) && defined(UNKNOWN_PRINT)
    //printf("Unknown Char <%02x>\n",(unsigned char) yytext[0]);
	#endif
}

@PJL[ ]{1} {
	#ifdef ENA_PRINTING
	printf("PJL Command\n");
	#endif
	BEGIN(INITIAL);
}

[ \t\n\r]{0,256}       /* skip whitespace */

%%
