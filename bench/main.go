package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"math"
	"math/rand"
	"net"
	"net/http"
	"runtime"
	"sort"
	"strings"
	"time"
)

// cli flags
var (
	rFlag = flag.Int("r", 100000, "num requests")
	dFlag = flag.Int("d", 0, "num domains")
	lFlag = flag.String("l", "", "list domains")
	wFlag = flag.Int("w", runtime.NumCPU(), "num workers")
	cFlag = flag.String("c", "/var/cache/pixelserv/ca.crt", "ca cert path")
	pFlag = flag.String("p", "127.0.0.1", "pixelserve ip address")
)

var charSet = "abcdedfghijklmnopqrstuvwxyz"

var exts = []string{
	".html",
	".htm",
	".jpg",
	".jpeg",
	".gif",
	".png",
	".ico",
	".js",
	".swf",
	".txt",
}

func makeReqPath() string {
	switch rand.Intn(6) {
	default:
		return ""
	case 0:
		return fmt.Sprintf("/%s", randStr(5))
	case 1:
		return fmt.Sprintf("/%s/", randStr(6))
	case 2, 3:
		return fmt.Sprintf("/%s%s", randStr(7), exts[rand.Intn(len(exts))])
	case 4:
		return fmt.Sprintf("/%s/%s%s", randStr(8), randStr(4), exts[rand.Intn(len(exts))])
	}
}

func makeHost(domains []string) string {
	domain := domains[rand.Intn(len(domains))]
	switch rand.Intn(3) {
	default:
		return fmt.Sprintf("https://%s", domain)
	case 0, 1:
		subdomain := randStr(4)
		return fmt.Sprintf("https://%s.%s", subdomain, domain)
	}
}

func randStr(n int) string {
	var output strings.Builder
	var l = len(charSet)
	for i := 0; i < n; i++ {
		random := rand.Intn(l)
		randomChar := charSet[random]
		output.WriteString(string(randomChar))
	}
	return output.String()
}

func sortedKeys(myMap map[string]int) []string {
	keys := make([]string, 0, len(myMap))
	for k := range myMap {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

func printResults(results map[string]int, startTime time.Time) {
	currentTime := time.Now()
	diff := currentTime.Sub(startTime)
	if len(results) == 0 {
		log.Printf("Results empty after %f secons\n", diff.Seconds())
	} else {
		log.Println("")
		keys := sortedKeys(results)
		for _, status := range keys {
			n := results[status]
			seconds := diff.Seconds()
			rate := float64(n) / seconds
			log.Printf("%s: %f/sec (%d / %d)\n", status, rate, n, int(math.Ceil(seconds)))
		}
	}
}

func handleRes(res <-chan string) {
	startTime := time.Now()
	results := map[string]int{}
	ticker := time.NewTicker(1 * time.Second)

	i := 0
	for {
		select {
		case <-ticker.C:
			printResults(results, startTime)
		case r := <-res:
			results[r]++
			i++
		}
		if i >= *rFlag {
			printResults(results, startTime)
			return
		}
	}
}

func doReq(client *http.Client, host string, sem <-chan bool, res chan<- string) {
	defer func() { <-sem }()

	path := makeReqPath()
	uri := fmt.Sprintf("%s%s", host, path)
	//fmt.Println(uri)
	resp, err := client.Get(uri)
	if err != nil {
		res <- "GET error"
		return
	}

	_, err = ioutil.ReadAll(resp.Body)
	if err != nil {
		res <- "READ error"
		return
	}
	defer resp.Body.Close()

	res <- resp.Status
}

func main() {
	flag.Parse()
	rand.Seed(time.Now().Unix())

	var domains []string
	if *dFlag > 0 && *lFlag != "" {
		log.Fatal("Cannot num and list domains")
	} else if *dFlag > 0 {
		for i := 0; i < *dFlag; i++ {
			domains = append(domains, fmt.Sprintf("%s.com", randStr(10)))
		}
	} else if *lFlag != "" {
		domains = strings.Split(*lFlag, ",")
	} else {
		log.Fatal("Must either list or num domains")
	}

	if len(domains) == 0 {
		log.Fatal("No domains found")
	}

	caCert, err := ioutil.ReadFile(*cFlag)
	if err != nil {
		log.Fatal(err)
	}
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	// https://github.com/golang/go/issues/22704
	dialer := &net.Dialer{
		Timeout:   200 * time.Millisecond,
		DualStack: true,
	}

	client := &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{
				RootCAs: caCertPool,
			},
			DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
				// redirect all connections to 127.0.0.1
				addr = *pFlag + addr[strings.LastIndex(addr, ":"):]
				return dialer.DialContext(ctx, network, addr)
			},
		},
	}

	res := make(chan string, *wFlag)

	go func() {
		sem := make(chan bool, *wFlag)
		for i := 0; i < *rFlag; i++ {
			sem <- true
			host := makeHost(domains)
			go doReq(client, host, sem, res)
		}

		// drain semaphore
		for i := 0; i < cap(sem); i++ {
			sem <- true
		}
	}()

	handleRes(res)

	time.Sleep(2 * time.Second)
	log.Println("Goodbye!")
}
