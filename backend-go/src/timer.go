package main

import "fmt"

func logInfo(message string, args ...interface{}) {
	fmt.Printf("[INFO] "+message+"\n", args...)
}

func logError(message string, args ...interface{}) {
	fmt.Printf("[ERROR] "+message+"\n", args...)
}
