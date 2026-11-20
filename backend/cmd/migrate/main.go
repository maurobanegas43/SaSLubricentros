package main

import (
	"database/sql"
	"flag"
	"fmt"
	"log"
	"os"

	_ "github.com/lib/pq"
)

func main() {
	host := flag.String("host", "localhost", "Database host")
	port := flag.String("port", "5432", "Database port")
	user := flag.String("user", "postgres", "Database user")
	password := flag.String("password", "", "Database password")
	dbname := flag.String("dbname", "postgres", "Database name")
	flag.Parse()

	if *password == "" {
		log.Fatal("Password is required")
	}

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=require",
		*host, *port, *user, *password, *dbname)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("Failed to connect: %v", err)
	}
	defer db.Close()

	if err = db.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}
	log.Println("✅ Connected to database")

	// Read migration file
	migrationSQL, err := os.ReadFile("migrations/002_add_vehicle_image_url.sql")
	if err != nil {
		log.Fatalf("Failed to read migration file: %v", err)
	}

	// Execute migration
	_, err = db.Exec(string(migrationSQL))
	if err != nil {
		log.Fatalf("Failed to execute migration: %v", err)
	}

	log.Println("✅ Migration applied successfully")
}
