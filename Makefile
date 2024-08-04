build:
	nim c src/main.nim 
	mv -f src/main bin/sequoia
	chmod a+x bin/sequoia


