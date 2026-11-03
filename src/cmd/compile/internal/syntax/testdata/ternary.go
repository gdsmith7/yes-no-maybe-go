package chans

func ternary(cond bool) int {
	return cond ? 1 : 0
}

func nestedTernary(cond1, cond2 bool) int {
	return cond1 ? 1 : cond2 ? 0 : 2
}

func ternaryWithReturnedBool() int {
	return returnTrue() ? 1 : 0
}

func returnTrue() bool {
	return true
}