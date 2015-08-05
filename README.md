# Flex Fun #
I am going to make something that pulls apart PCL/HPGL/PJL files. This guide was written using cygwin64 flex 2.5.39 and compiled using Visual Studio 2013 and Qt 5.5.0.

First we make a file that describes the lexer that understands PCL/HPGL/PJL. 
> plc-hpgl.l

At the top of this file we place the following options:
> %option noyywrap
> %option never-interactive
> %option nounistd
> %option backup
> %option warn
> %option reentrant
> %option extra-type="scanner_globals *"
> %option outfile="pcl-hpgl-scanner.cpp" header-file="pcl-hpgl-scanner.h"
> %option full 
> %option ecs

Each of these options are described 

 - noyywrap: Don't include the yywrap function which is called when the scanner recives and EOF from YY_INPUT. [Flex Manual - page 20](http://courses.softlab.ntua.gr/compilers/flex.pdf)
 - never-interactive: Tells the scanner to always look ahead an extra character because it is faster. This may be redundant as the full table option is used (discussed later). [Flex Manual - page 38](http://courses.softlab.ntua.gr/compilers/flex.pdf)
 - nounistd: Don't include the header unistd.h as we are trying to make this as cross platform as possible. [Flex Manual - page 40](http://courses.softlab.ntua.gr/compilers/flex.pdf)
 - backup: generate the 'lex.backup' file which describes the states which require backing up. This is a file which we can use to assess the performance of the scanner and help us improve it. [Flex Manual - page 43](http://courses.softlab.ntua.gr/compilers/flex.pdf)
 - warn: Warn about certain things, e.g. if the default rule can be matched but no default was given. [Flex Manual - page 44](http://courses.softlab.ntua.gr/compilers/flex.pdf)
 - reentrant: Makes the scanner reentrant so we can use it in multiple processes. [Flex Manual - page 39](http://courses.softlab.ntua.gr/compilers/flex.pdf)
 - extra-type: This stores the extra user-specific data. [Flex Manual - page 58](http://courses.softlab.ntua.gr/compilers/flex.pdf)
 - outfile, header-file: Describes the output file name and the header file name.[Flex Manual - page 35-36](http://courses.softlab.ntua.gr/compilers/flex.pdf)
 - full: Specifies that this is a fast scanner with no compresssion or use of stdio. This makes the scanner larger. [Flex Manual - page 42](http://courses.softlab.ntua.gr/compilers/flex.pdf)
 - ecs: Specifies that equivilence classes are constructed to reduce the table size for little performance loss. [Flex Manual - page 41](http://courses.softlab.ntua.gr/compilers/flex.pdf)


With that knowledge we have the following flex template:

    %option noyywrap
	%option never-interactive
	%option nounistd
	%option backup
	%option warn
	%option reentrant
	%option extra-type="scanner_globals *"
	%option outfile="pcl-hpgl-scanner.cpp" header-file="pcl-hpgl-scanner.h"
	%option full 
	%option ecs
	
	
	
	%{
	/* Included headers go here and anything to be copied verbatim */
	#include "header.h" 
	%}
	
	digit         [0-9]
	letter        [a-zA-Z]
	
	%%
		/* This is the rules section */
	{letter}({letter}|{digit})* {
	                       yylval.id = strdup(yytext);
	                       return IDENT;      }
	{digit}+             { yylval.num = atoi(yytext);
	                       return NUMBER;     }
	[ \t\n\r]            /* skip whitespace */
	.                    { printf("Unknown character [%c]\n",yytext[0]);
	                       return UNKNOWN;    }
	%%
	
	int myfunc(void){return 0;}

Flex files have three sections seperated by the %% characters.

    definitions
    %%
    rules
    %%
    user code
These sections are described in great detail in Chapter 5 of the [Flex Manual](http://courses.softlab.ntua.gr/compilers/flex.pdf).

We want to start parsing HPGL/PCL/PJL so lets make a rule to get some of the basic command strings we might find in a file. In the rules section remove everything from the template and add the following rules:

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
		#ifdef ENA_PRINTING
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
	    printf("Unknown Char <%02x>\n",(unsigned char) yytext[0]);
		#endif
	}
	
	@PJL[ ]{1} {
		#ifdef ENA_PRINTING
		printf("PJL Command\n");
		#endif
		BEGIN(INITIAL);
	}
	
	[ \t\n\r]{0,256}       /* skip whitespace */

A rule is defined first with a list of start conditions in brackets:

	<start_condition1,sc2,etc> 
Start conditions ([Flex Manual Ch 10](http://courses.softlab.ntua.gr/compilers/flex.pdf)) can either be inclusive or exclusive, we want our parser to have exclusive start conditions so we add the following to the definitions section (above the rules section):

	%x PCL_ESCAPE_SEQ
	%x PCL_TWO_ESCAPE_SEQ
	%x PJL_COMMAND
	%x HPGL_MODE
Having the exclusive start conditions allows us to go into "parsing modes" which is an easy way to think about handling the different parts of HPGL/PCL/PJL. You can get the project at this point in time [here](https://github.com/ablaylock/flexFun/archive/v0.1.zip)(v0.1 of the project). 

## Interacting with the parser##

Now we want to actually use the parser so lets add some code to utilize it. We are going to modify the _main.cpp_ file to contain the following code:

	#include <QCoreApplication>
	#define YY_NO_UNISTD_H
	#include "pcl-hpgl-scanner.h"
	
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
First notice that we set 

	YY_NO_UNISTD_H

which tells the header not to include the unistd.h header. Next we construct a parser where first we see if there is an input file passed in as an argument and then set it if there was, otherwise we should take data from the standard in stream. This happens in the code block:

	yyscan_t scanner;
    FILE * inputFile = 0;
    if (argc > 1)
        inputFile = fopen(argv[1], "rb");
    yylex_init( &scanner );
    if(argc > 1 && inputFile)
        yyset_in(inputFile,scanner);
    else
        yyset_in(stdin,scanner);
Parsing actually occurs with the call to:
	
	yylex(scanner);
and then we clean everything up with:

	yylex(scanner);
	yylex_destroy(scanner);
	if(inputFile)
	    fclose(inputFile);
If we compile this project right now we will find errors that the "read" function cannot be found. We need to add the io.h header to the definitions section where verbatim code is added, between the %{}% braces. 

### Oops ###
Well, it wasn't that simple, getting flex to build our output well turned out to be a ton of work. I ended up finding [this](http://www.freehackers.org/thomas/2009/11/22/how-to-use-flex-and-bison-with-qmake-my-own-way/) and porting it for my use. Having qmake handle everything works much better. Check out [v0.2](https://github.com/ablaylock/flexFun/archive/v0.2.zip) of the project.

Now where were we? Oh yes, we have made some modes to operate in so lets go ahead and make it so that there are things decoded in those modes. We are just going to implement a few of the commands for the example. First let's start with PJL:

	    /* Add PJL commands*/
	<PJL_COMMAND>{
	     JOB[ ]NAME=.*\r?\n {
	        const char * jobName;
	        jobName = getJobName(yytext);
	        #if defined(ENA_PRINTING) || defined(ENA_JOB_NAME)
	        printf("Job Name String <%s>\n",jobName);
	        #endif
	        BEGIN(INITIAL);
	    }
	
	     ENTER[ ]LANGUAGE=PCL[ ]+\r?\n {
	         #ifdef ENA_PRINTING
	         printf("Language: PCL\n");
	         #endif
	         BEGIN(INITIAL);
	
	     }
	
	     EOJ[ \r\n]{0,256} {
	         #if defined(ENA_PRINTING) || defined(ENA_EOJ)
	         printf("End of job\n");
	         #endif
	         BEGIN(INITIAL);
	         yyterminate();
	    }
	}

We also add a few items to the definitions and user code sections of the lexer definition file. We add function prototypes to the definition section between the %{}% portion and add the actual functions to the user code section.
Definition section change:

	%{
	#include <io.h>
	#define ENA_PRINTING
	const char * pclValueExtractor(const char *);
	const char * getJobName(const char *);
	%}
User code:

	#define MAX_JOB_NAME_LEN (256)
	const char * getJobName(const char * in_str)
	{
	    // Make sure we have a null terminated string
	    static char name[MAX_JOB_NAME_LEN+1];
	    name[MAX_JOB_NAME_LEN] = '\0';
	    // Start figuring out the name location and length
	    const char * name_start = strstr(in_str,"=")+1;
	    size_t name_len = strcspn(name_start,"\n\r\t");
	    // Copy it
	    strncpy(name,name_start, (name_len > MAX_JOB_NAME_LEN) ? MAX_JOB_NAME_LEN : name_len);
	    name[name_len] = '\0';
	    return name;
	}
	
	const char * pclValueExtractor(const char * in_str)
	{
	    size_t  str_size = strlen(in_str);
	    if(str_size < 3)
	        return "\0"; // There is no value to extract
	    // Make sure we have a null terminated string
	    static char value[MAX_JOB_NAME_LEN+1];
	    value[str_size-2-1] = '\0';
	    strncpy(value,&in_str[2],str_size-2-1);
	    return value;
	}

 Looking at this there are a few important things. From the top we first see that there is an indent infront of the comment. Why? Because we don't want it interpreted as a rule. Next we see that all of the rules are in the PJL_COMMAND start condition, this is sort of like setting the mode. And finally we see that each rule for PJL results in the parser returning to the INITIAL state so that new commands can be parsed. For other commands we may not wish to immediately return to INITIAL as we will see later. You can download the project at this stage, [ v0.3, here](https://github.com/ablaylock/flexFun/archive/v0.3.zip).

Next lets implement some basic PCL commands in a PCL mode. This looks like:

	<PCL_ESCAPE_SEQ>{
	    %1B	{
	        #ifdef ENA_PRINTING
	        printf("OPEN HPGL MODE\n");
	        #endif
	        BEGIN(HPGL_MODE);
	    }
	
	    %0B	{
	        #ifdef ENA_PRINTING
	        printf("CLOSE HPGL MODE -- HACK\n");
	        #endif
	        BEGIN(INITIAL);
	    }
	
	    [*]{1}r[0-9]{0,5}T {
	        #if defined(ENA_PRINTING)
	        int intValue;
	        const char * valueStr;
	        valueStr = pclValueExtractor(yytext);
	        intValue = atoi(valueStr);
	        printf("Set Raster Page Height <%d>\n", intValue);
	        #endif
	        BEGIN(INITIAL);
	    }
	
	    [*]{1}r[0-9]{0,5}S {
	        #if defined(ENA_PRINTING)
	        int intValue;
	        const char * valueStr;
	        valueStr = pclValueExtractor(yytext);
	        intValue = atoi(valueStr);
	        printf("Set Raster Page Width <%d>\n", intValue);
	        #endif
	        BEGIN(INITIAL);
	    }
	}
 
 Now we see a few additional things. We can see how we might transition from one mode to the next, in this case we go to HPGL_MODE from PCL in the first rule. Additionally we can see how more of the functions we defined in the definition section are being used. Finally lets add some basic HPGL support.

	<HPGL_MODE>{
		IN; {
			#ifdef ENA_PRINTING
			printf("Initialize HP-GL/2\n");
			#endif
		}
		
		LT[\-0-9]{0,2}[;]? {
			#ifdef ENA_PRINTING
			printf("Set Line Type\n");
			#endif
		}
		
		\x1b%0[AB] {
			#ifdef ENA_PRINTING
			printf("Exit HPGL mode\n");
			#endif
			BEGIN(INITIAL);
		}

You can find the implementation in v0.4 [here](https://github.com/ablaylock/flexFun/archive/v0.4.zip). Now we have a framework to fill out any command from PJL, HPGL, or PCL that we want.

#The End#
[1]:  http://courses.softlab.ntua.gr/compilers/flex.pdf "Flex Manual - page 20"

> Written with [StackEdit](https://stackedit.io/).
