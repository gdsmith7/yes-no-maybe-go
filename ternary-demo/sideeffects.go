package main

func loud(result string) string {
	println("  evaluated", result)
	return result
}

func choose(cond bool) string {
	return cond ? loud("then") : loud("else")
}

func main() {
	println("choose(true):")
	println("  =", choose(true))
	println("choose(false):")
	println("  =", choose(false))
}
