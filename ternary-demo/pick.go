package main

func pick(cond bool) string {
	return cond ? "then" : "else"
}

func main() {
	println(pick(true))
	println(pick(false))
}
