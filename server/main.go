package main

import (
	"flag"
	"log"
	"net/http"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

var addr = flag.String("addr", "localhost:8080", "http service address")

type Client struct {
	conn *websocket.Conn
}

func (c Client) echoPump() {
	defer c.conn.Close()
	for {
		messageType, p, err := c.conn.ReadMessage()
		if err != nil {
			log.Println(err)
			return
		}
		if err := c.conn.WriteMessage(messageType, p); err != nil {
			log.Println(err)
			return
		}
	}
}

func wsHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}

	client := Client{conn: conn}
	go client.echoPump()
}

func main() {
	flag.Parse()
	log.SetFlags(0)
	http.HandleFunc("/echo", wsHandler)

	log.Fatal(http.ListenAndServe(*addr, nil))
}
