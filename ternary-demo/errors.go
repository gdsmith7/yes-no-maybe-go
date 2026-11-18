package main

func main() {
	condition := 1
	_ = condition ? 1 : 0       // the condition isn't a bool
	_ = condition > 0 ? 1 : "a" // the branches have different types
}
