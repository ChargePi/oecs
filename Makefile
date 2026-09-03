.PHONY: bundle clean

bundle:
	go run scripts/bundle.go schema/1.0.0
	go run scripts/bundle.go schema/1.1.0
	go run scripts/bundle.go schema/1.1.1

clean:
	rm -rf dist
