package main

func pick(cond bool, a, b int) int {
	return cond ? a : b
}

func main() {
	println(pick(true, 1, 2))
	println(pick(false, 1, 2))
}
