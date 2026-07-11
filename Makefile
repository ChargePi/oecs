.PHONY: bundle clean

bundle:
	go run scripts/bundle.go

clean:
	rm -rf dist
