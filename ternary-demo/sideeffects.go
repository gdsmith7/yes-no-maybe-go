package main

func loud(x int, name string) int {
	println("  evaluated", name)
	return x
}

func choose(cond bool) int {
	return cond ? loud(10, "then") : loud(20, "else")
}

func main() {
	println("choose(true):")
	println("  =", choose(true))
	println("choose(false):")
	println("  =", choose(false))
}
