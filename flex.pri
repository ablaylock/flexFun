flex.name = Flex ${QMAKE_FILE_IN}
flex.input = FLEXSOURCES
flex.output = ${QMAKE_FILE_PATH}/${QMAKE_FILE_BASE}.lexer.cpp
flex.commands = C:/cygwin64/bin/flex -L --outfile=${QMAKE_FILE_PATH}/${QMAKE_FILE_BASE}.lexer.cpp ${QMAKE_FILE_IN}
flex.depend_command = C:/cygwin64/bin/sed -i "/line [0-9]+/d" ${QMAKE_FILE_PATH}/${QMAKE_FILE_BASE}.lexer.cpp
flex.CONFIG += target_predeps
flex.variable_out = GENERATED_SOURCES
silent:flex.commands = @echo Lex ${QMAKE_FILE_IN} && $$flex.commands
QMAKE_EXTRA_COMPILERS += flex
