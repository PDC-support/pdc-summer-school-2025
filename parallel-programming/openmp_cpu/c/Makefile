CC = cc
CFLAGS = -g -O2
OMPFLAGS = -fopenmp
LIBS = -lm

all: part1 part2 part3

part1: part1ex1 part1ex2 part1ex3
	

part2: part2ex1 part2ex2 part2ex3 part2ex4
	

part3: part3a
	


part1ex1: part1.c
	$(CC) $(CFLAGS) $(OMPFLAGS) -DEXAMPLE=1 $< -o $@ $(LIBS)

part1ex2: part1.c
	$(CC) $(CFLAGS) $(OMPFLAGS) -DEXAMPLE=2 $< -o $@ $(LIBS)

part1ex3: part1.c
	$(CC) $(CFLAGS) $(OMPFLAGS) -DEXAMPLE=3 $< -o $@ $(LIBS)

part2ex1: part2.c
	$(CC) $(CFLAGS) $(OMPFLAGS) -DEXAMPLE=1 $< -o $@ $(LIBS)

part2ex2: part2.c
	$(CC) $(CFLAGS) $(OMPFLAGS) -DEXAMPLE=2 $< -o $@ $(LIBS)

part2ex3: part2.c
	$(CC) $(CFLAGS) $(OMPFLAGS) -DEXAMPLE=3 $< -o $@ $(LIBS)

part2ex4: part2.c
	$(CC) $(CFLAGS) $(OMPFLAGS) -DEXAMPLE=4 $< -o $@ $(LIBS)

part3a:	part3a.c
	$(CC) $(CFLAGS) $(OMPFLAGS) $< -o $@ $(LIBS)

part2serial: part2.c
	$(CC) $(CFLAGS) -DSERIAL part2.c -o $@ $(LIBS)

part3serial: part3a.c
	$(CC) $(CFLAGS) -DSERIAL part3a.c -o $@ $(LIBS)

clean:
	rm -fr part1ex1 part1ex2 part1ex3 part2ex4 \
	part2ex1 part2ex2 part2ex3 part3a part3b *.o
