package log

import "fmt"

func Printf(format string, args ...interface{}) {
	fmt.Printf(format, args...)
}

func Errorf(format string, args ...interface{}) {
	fmt.Printf(format, args...)
}
