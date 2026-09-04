.PHONY: bundle clean

bundle:
	go run scripts/bundle.go schema/1.0.0
	go run scripts/bundle.go schema/1.1.0
	go run scripts/bundle.go schema/1.1.1
	go run scripts/bundle.go schema/2.0.0

clean:
	rm -rf dist
