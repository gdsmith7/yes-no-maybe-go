package main

func main() {
	n := 1
	_ = n ? 1 : 0       // the condition isn't a bool
	_ = n > 0 ? 1 : "a" // the branches have different types
}
