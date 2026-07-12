.PHONY: bundle clean

bundle:
	go run scripts/bundle.go schema/1.0.0

clean:
	rm -rf dist
