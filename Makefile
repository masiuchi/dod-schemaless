install:
	carton install

test:
	carton exec prove -l

clean:
	rm cpanfile.snapshot
	rm -rf local/

