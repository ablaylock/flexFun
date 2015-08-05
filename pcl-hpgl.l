%option noyywrap
%option never-interactive
%option nounistd
%option backup
%option warn
%option reentrant
%option full 
%option ecs



%{
#include <io.h>
#define ENA_PRINTING
const char * pclValueExtractor(const char *);
const char * getJobName(const char *);
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
    //printf("PCL Parameterized Escape Sequence\n");
    printf("PCL Command:\t");
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
    printf("PJL Command:\t");
	#endif
    BEGIN(PJL_COMMAND);
}

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
}

[ \t\n\r]{0,256}       /* skip whitespace */

%%

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

