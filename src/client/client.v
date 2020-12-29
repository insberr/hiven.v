module client

import eventbus
import time
import x.websocket
import x.json2

import src.structs

const (
	bus = eventbus.new()
)

pub struct Client {
pub mut:
	ws         &websocket.Client
	token      string
	bot        bool = true
	firstevent bool = true
	heartbeat int
}

struct ClosedReason {
pub:
	code   int
	reason string
}

pub fn new_client() &Client {
	println('New client created')
	mut socket := websocket.new_client('wss://swarm-dev.hiven.io/socket?encoding=json&compression=text_json') or {
		panic('Unable to connect')
	}
	mut cl := &Client{
		ws: socket
	}
	cl.ws.on_open_ref(openfn, &cl)
	cl.ws.on_message_ref(messagefn, &cl)
	cl.ws.on_close_ref(closefn, &cl)
	return cl
}

pub fn (mut cl Client) login(token string) {
	println('Login ran')
	cl.ws.connect() or { println(err) }
	cl.token = token
	go cl.ws.listen()
	time.sleep(5)

	
}

pub fn (mut c Client) run() ? { // this function blocks until the client stops
	// allow for stuff to get done
	// if c.bot == true {
	// ws.login(c.ws,"Bot $c.token")
	// } else {
	// ws.login(c.ws, c.token)
	// }
	for {
	}
}

fn get_subscriber() eventbus.Subscriber {
	return *bus.subscriber
}

pub fn (mut c Client) on(etype string, evthandler eventbus.EventHandlerFn) {
	get_subscriber().subscribe(etype, evthandler)
}


/* === Websocket events === */
fn openfn(mut c websocket.Client, cl &Client) ? {
	
	println('websocket opened')
	bus.publish('open', cl, none)
}

fn closefn(mut c websocket.Client, code int, reason string, cl &Client) ? {
	bus.publish('close', cl, ClosedReason{
		code: code
		reason: reason
	})
}

fn messagefn(mut c websocket.Client, msg &websocket.Message, mut cl &Client) ? {
	if msg.payload.len > 0 {
		mut pck := structs.socket_msg_parse(msg)?
		match pck.op {
			1 { activate_heartbeat(pck.d["hbt_int"].int(), mut c, mut cl) }
			else { println("INVALID OPCODE: $pck.op DATA: $pck.d")}
		}
		//print(pck.d)
		//bus.publish('message', cl, message)
	}
	
}

fn activate_heartbeat(timeb int, mut c &websocket.Client, mut cl &Client) {
	println("HEARTBEAT SET TO: "+ timeb.str())
	// client.heartbeat = timeb
}

