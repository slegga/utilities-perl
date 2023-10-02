package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"strconv"
	"math"
)

type Window struct {
	Name   string
	Screen int
	XPos   int
	YPos   int
	XSize  int
	YSize  int
	Minimize bool
}

type Screen struct {
	Windows []Window
}

func getScreenInfo() (int, int, int) {
	cmd := exec.Command("wmctrl", "-d")
	output, err := cmd.Output()
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}

	outputStr := string(output)
	lines := strings.Split(outputStr, "\n")
	for i, line := range lines {
		if  strings.Index(line, "*") == 0 {
			continue
		}
		fmt.Println(i, line)
		
		if len(line) > 0 {
			fields := strings.Fields(line)
			if len(fields) >= 4 {
				xRes := fields[3]
				dimensions := strings.Split(xRes, "x")
				if len(dimensions) == 2 {
					f, _ := strconv.Atoi(fields[0])
					x, _ := strconv.Atoi(dimensions[0])
					y, _ := strconv.Atoi(dimensions[1])
					return f, x, y
				}
			}
		}
	}
	return 0, 0, 0
}

func listWindows(cur_screen int) []Window {
	cmd := exec.Command("wmctrl", "-Gl")
	output, err := cmd.Output()
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}

	outputStr := string(output)
	lines := strings.Split(outputStr, "\n")
	var windows []Window

	for _, line := range lines {
		fields := strings.Fields(line)
		if len(fields) >= 8 {
//			windowID := fields[0]
			screen, _  := strconv.Atoi(fields[1])
			x, _ := strconv.Atoi(fields[2])
			y, _ := strconv.Atoi(fields[3])
			name := strings.Join(fields[7:], " ")
			if cur_screen != screen {
				continue
			}
			windows = append(windows, Window{
				Screen: screen,
				Name: name,
				XPos: x,
				YPos: y,
			})
		}
	}

	return windows
}

func main() {
	cur_screen, xRes, yRes := getScreenInfo()
	xMin := 36
	yMin := 36
	xMax := xRes
	yMax := yRes - 36 // Adjust as needed

	windows := listWindows(cur_screen)

	var screens []Screen
	//var wnil Window
//	for i := 0; i < len(windows); i++ {
//		if cur_screen != windows[i].Screen {
//			continue
//		}
//		screen := Screen{}
//		screen.Windows = append(screen.Windows, windows[i])
//		screens = append(screens, screen)
//	}

	// You can implement the resizing logic and other functionalities here
	// using the screens and windows data structures.
	
	xwmax := int(math.Sqrt(float64(len(windows))))
	ywmax := xwmax
	if len(windows) > xwmax * ywmax {
		xwmax = xwmax + 1
	}
	if len(windows) > xwmax * ywmax {
		ywmax = ywmax + 1
	}
	xwsize := int((xMax - xMin)/ xwmax)
	ywsize := int((yMax - yMin)/ ywmax)
	
	fmt.Println("Windows:",len(windows))
	fmt.Println("screens:",len(screens))

	fmt.Println("x_min:", xMin)
	fmt.Println("y_min:", yMin)
	fmt.Println("x_max:", xMax)
	fmt.Println("y_max:", yMax)
	
	for i := 0; i < len(windows); i++ {
		x := i / xwmax
		y := i - x * xwmax
		name2 := "\""+windows[i].Name+"\"";
		fmt.Println("name:",name2,"  winno:",i,"  x:",x * xwsize,"  y:",y * ywsize)
//		command:= "-r "+ name2+ "-b remove,above,fullscreen,sticky,maximized_vert,maximized_horz -e "+strconv.Itoa(i)+","+strconv.Itoa(x * xwsize)+","+strconv.Itoa(y * ywsize)+","+strconv.Itoa((x+1) * xwsize)+","+strconv.Itoa((y+1) * ywsize)
//		fmt.Println("wmctrl",command)
		cmds := []string {"-r", name2, "-b","\"remove,above\""}//,"-e",strconv.Itoa(i)+","+strconv.Itoa(x * xwsize)+","+strconv.Itoa(y * ywsize)+","+strconv.Itoa((x+1) * xwsize)+","+strconv.Itoa((y+1) * ywsize)}
		fmt.Println("wmctrl", strings.Join(cmds[:]," "))
		cmd := exec.Command("wmctrl", cmds...)
//			cmd := exec.Command(command)
// 
		var stderr strings.Builder
		cmd.Stderr = &stderr
		output, err := cmd.Output()
		if err != nil {
		
			fmt.Println("Error:", err)
			fmt.Println("Error:", output)
			fmt.Printf("in all caps: %q\n", stderr.String())
			fmt.Println("Error:", cmd.CombinedOutput()
			os.Exit(1)
		}
		outputStr := string(output)
		fmt.Println(outputStr)
	}
}
