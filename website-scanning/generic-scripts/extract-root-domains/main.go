/*
This tool is to be used to help reduce number of domain lookups for subfinder.
Take a list of domains found by tools like hakrevdns, extract root domains,
run that list of root domains in subfinder.

It is inefficient to take a list of like 10k domains and feed em directly into subfinder as is...
*/
package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"golang.org/x/net/idna"
)

const (
	pslURL  = "https://publicsuffix.org/list/public_suffix_list.dat"
	maxAge  = 7 * 24 * time.Hour
	timeout = 10 * time.Second
)

// Public suffix rules or whatever.
// This is what we use to parse the root domains.
type psl struct{ rules, exceptions map[string]struct{} }

func parsePSL(data []byte, keepPrivate bool) *psl {
	l := &psl{rules: map[string]struct{}{}, exceptions: map[string]struct{}{}}
	private := false
	for _, line := range strings.Split(string(data), "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "//") {
			if strings.Contains(line, "BEGIN PRIVATE DOMAINS") {
				private = true
			}
			continue
		}
		if private && !keepPrivate {
			continue
		}
		rule := strings.ToLower(line)
		// store IDN rules as punycode so they match punycode hostnames
		if strings.IndexFunc(rule, func(r rune) bool { return r >= 0x80 }) >= 0 {
			if p, err := idna.Punycode.ToASCII(rule); err == nil {
				rule = p
			}
		}
		if strings.HasPrefix(rule, "!") {
			l.exceptions[rule[1:]] = struct{}{}
		} else {
			l.rules[rule] = struct{}{}
		}
	}
	return l
}

// publicSuffix implements the publicsuffix.org algorithm, returns how many
// rightmost labels form the public suffix.
func (l *psl) publicSuffix(labels []string) int {
	// exception rules prevail: "!www.ck" -> suffix of a.www.ck is "ck"
	for i := range labels {
		if _, ok := l.exceptions[strings.Join(labels[i:], ".")]; ok {
			if n := len(labels) - i - 1; n > 0 {
				return n
			}
			return 1
		}
	}
	// longest matching rule, wildcards included ("*.ck" matches x.ck)
	for i := range labels {
		if _, ok := l.rules[strings.Join(labels[i:], ".")]; ok {
			return len(labels) - i
		}
		if i+1 < len(labels) {
			if _, ok := l.rules["*."+strings.Join(labels[i+1:], ".")]; ok {
				return len(labels) - i
			}
		}
	}
	return 1 // default rule "*": unknown TLD -> last two labels
}

func (l *psl) registrable(host string) (string, bool) {
	labels := strings.Split(host, ".")
	k := l.publicSuffix(labels)
	if len(labels)-k < 1 {
		return "", false // host is itself a public suffix
	}
	return strings.Join(labels[len(labels)-k-1:], "."), true
}

func cachePath() string {
	if base, err := os.UserCacheDir(); err == nil {
		return filepath.Join(base, "publicsuffix", "public_suffix_list.dat")
	}
	return filepath.Join(os.TempDir(), "public_suffix_list.dat")
}

func loadPSL(keepPrivate bool) *psl {
	path := cachePath()
	stale := true
	if st, err := os.Stat(path); err == nil && time.Since(st.ModTime()) < maxAge {
		stale = false
	}
	if stale {
		if err := fetch(path); err != nil {
			if _, statErr := os.Stat(path); statErr != nil {
				log.Printf("[!] No cached PSL and fetch failed (%v); naive last-label mode\n", err)
				return parsePSL(nil, keepPrivate)
			}
			log.Printf("[!] PSL refresh failed (%v); using cached copy\n", err)
		}
	}
	data, err := os.ReadFile(path)
	if err != nil {
		log.Fatal("[!] Error reading PSL cache:", err)
	}
	return parsePSL(data, keepPrivate)
}

// Fetch... rubart.
func fetch(path string) error {
	resp, err := (&http.Client{Timeout: timeout}).Get(pslURL)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return fmt.Errorf("HTTP %s", resp.Status)
	}
	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

// Helper functions.
func setupInput(inputFile *string) *os.File {
	if *inputFile == "" {
		return os.Stdin
	}

	fd, err := os.Open(*inputFile)
	if err != nil {
		log.Fatal("[!] Error opening input file:", err)
	}
	return fd
}

func setupOutput(outputFile *string) *os.File {
	if *outputFile == "" {
		return os.Stdout
	}

	fd, err := os.OpenFile(*outputFile, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0644)
	if err != nil {
		log.Fatal("[!] Error opening output file:", err)
	}
	return fd
}

func main() {
	noPrivate := flag.Bool("no-private", false, "Collapse private suffixes (github.io, herokuapp.com, ...) into one root") // Might get rid of this later because I don't really use it. I thought I would.
	inputFile := flag.String("i", "", "Input file path (default stdin)")
	outputFile := flag.String("o", "", "Output file path (default stdout)")

	flag.Parse()

	l := loadPSL(!*noPrivate)

	input := setupInput(inputFile)
	if input != os.Stdin {
		defer input.Close()
	}

	output := setupOutput(outputFile)
	if output != os.Stdout {
		defer output.Close()
	}

	sc := bufio.NewScanner(input)
	sc.Buffer(make([]byte, 0, 64*1024), 1<<20)

	out := bufio.NewWriter(output)
	defer out.Flush()

	seen := map[string]struct{}{}
	var roots []string

	for sc.Scan() {
		fields := strings.Fields(sc.Text()) // handles "IP\thost", "IP host", bare domain
		if len(fields) == 0 {
			continue
		}
		host := strings.ToLower(strings.Trim(fields[len(fields)-1], "."))
		if host == "" || net.ParseIP(host) != nil {
			continue // empty PTR / raw IP: nothing to derive
		}

		if strings.IndexFunc(host, func(r rune) bool { return r >= 0x80 }) >= 0 {
			if p, err := idna.Punycode.ToASCII(host); err == nil {
				host = p
			}
		}
		root, ok := l.registrable(host)
		if !ok {
			continue
		}
		if _, exists := seen[root]; !exists {
			seen[root] = struct{}{}
			roots = append(roots, root)
		}
	}

	// Check for errors after the loop
	// This is best practices apparently...
	if err := sc.Err(); err != nil {
		log.Fatal("Error: ", err)
	}

	sort.Strings(roots)
	for _, r := range roots {
		fmt.Fprintln(out, r)
	}
}
