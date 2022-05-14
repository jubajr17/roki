import {Socket, Presence} from "phoenix"

var UserSocket = new Socket("/socket", {params: {token: window.userToken}})
UserSocket.connect()

export default UserSocket
