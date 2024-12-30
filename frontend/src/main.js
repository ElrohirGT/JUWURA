import "./style.css";
import "./CustomComponents/Icon/Icon.js";
import "./CustomComponents/SenkuCanvas/SenkuCanvas.js";
import { Elm } from "./Main.elm";
import { initializeLocalStoragePorts} from "./Ports/LocalStorage/LocalStorage.js";
import { initializeOauthPorts} from "./Ports/Auth/Auth.js";

// NOTE: We need to use substring to remove the / at the beginning
const basePath = import.meta.env.BASE_URL.substring(1);

const app = Elm.Main.init({
	flags: basePath,
});

// Create your WebSocket.
const socket = new WebSocket("wss://echo.websocket.org");

// When a command goes to the `sendMessage` port, we pass the message
// along to the WebSocket.
app.ports.sendMessage.subscribe((message) => {
	socket.send(message);
});

// When a message comes into our WebSocket, we pass the message along
// to the `messageReceiver` port.
socket.addEventListener("message", (event) => {
	app.ports.messageReceiver.send(event.data);
});

// LOCAL STORAGE
initializeLocalStoragePorts(app)

// OAUTH
initializeOauthPorts(app)